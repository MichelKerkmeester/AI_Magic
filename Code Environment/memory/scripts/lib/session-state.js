/**
 * Session State Module - Search session persistence
 *
 * Implements US7: Session State Persistence for interactive memory search.
 * Provides save/load/resume functionality with 1-hour TTL expiration.
 *
 * Features:
 * - Atomic file writes (write to temp, rename)
 * - Secure file permissions (0600 for files, 0700 for directory)
 * - Automatic TTL-based expiration (1 hour)
 * - Auto-save on state changes
 * - Session cleanup for expired entries
 *
 * @module session-state
 * @version 1.0.0
 */

'use strict';

const fs = require('fs');
const fsPromises = require('fs/promises');
const path = require('path');
const os = require('os');
const crypto = require('crypto');

// ───────────────────────────────────────────────────────────────
// CONFIGURATION
// ───────────────────────────────────────────────────────────────

const SESSION_DIR = path.join(os.homedir(), '.opencode', 'search-sessions');
const SESSION_TTL_MS = 60 * 60 * 1000; // 1 hour
const DIR_PERMISSIONS = 0o700;  // Owner read/write/execute only
const FILE_PERMISSIONS = 0o600; // Owner read/write only

// Valid session states (from plan.md state machine)
const VALID_STATES = ['IDLE', 'RESULTS', 'PREVIEW', 'FILTERED', 'CLUSTERED', 'LOAD', 'EXIT'];

// ───────────────────────────────────────────────────────────────
// SESSION ID GENERATION
// ───────────────────────────────────────────────────────────────

/**
 * Generate unique session ID (UUID v4)
 * @returns {string} UUID v4 format session ID
 */
function generateSessionId() {
  // Use crypto.randomUUID if available (Node 14.17+), fallback to manual generation
  if (crypto.randomUUID) {
    return crypto.randomUUID();
  }

  // Manual UUID v4 generation for older Node versions
  const bytes = crypto.randomBytes(16);
  // Set version (4) and variant (RFC4122)
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  const hex = bytes.toString('hex');
  return [
    hex.slice(0, 8),
    hex.slice(8, 12),
    hex.slice(12, 16),
    hex.slice(16, 20),
    hex.slice(20, 32)
  ].join('-');
}

// ───────────────────────────────────────────────────────────────
// SESSION CREATION
// ───────────────────────────────────────────────────────────────

/**
 * Create new session object
 *
 * @param {string} query - Search query
 * @param {Array} results - Search results array
 * @returns {Object} New session object conforming to schema
 */
function createSession(query, results = []) {
  const now = new Date();
  const expiresAt = new Date(now.getTime() + SESSION_TTL_MS);

  return {
    sessionId: generateSessionId(),
    createdAt: now.toISOString(),
    expiresAt: expiresAt.toISOString(),
    state: 'RESULTS',
    query: query || '',
    results: Array.isArray(results) ? results : [],
    filters: {
      folder: null,
      dateFrom: null,
      dateTo: null,
      tags: []
    },
    pagination: {
      page: 1,
      pageSize: 10,
      totalResults: Array.isArray(results) ? results.length : 0
    },
    viewMode: 'flat'
  };
}

// ───────────────────────────────────────────────────────────────
// DIRECTORY MANAGEMENT
// ───────────────────────────────────────────────────────────────

/**
 * Ensure session directory exists with proper permissions
 * @returns {Promise<void>}
 */
async function ensureSessionDir() {
  try {
    await fsPromises.access(SESSION_DIR);
  } catch {
    // Directory doesn't exist, create it
    await fsPromises.mkdir(SESSION_DIR, { recursive: true, mode: DIR_PERMISSIONS });
  }

  // Ensure correct permissions even if directory already existed
  try {
    await fsPromises.chmod(SESSION_DIR, DIR_PERMISSIONS);
  } catch (err) {
    // Log warning but don't fail - permissions may not be changeable on all systems
    console.warn(`[session-state] Could not set directory permissions: ${err.message}`);
  }
}

/**
 * Synchronous version of ensureSessionDir for use in sync contexts
 */
function ensureSessionDirSync() {
  if (!fs.existsSync(SESSION_DIR)) {
    fs.mkdirSync(SESSION_DIR, { recursive: true, mode: DIR_PERMISSIONS });
  }

  try {
    fs.chmodSync(SESSION_DIR, DIR_PERMISSIONS);
  } catch (err) {
    console.warn(`[session-state] Could not set directory permissions: ${err.message}`);
  }
}

// ───────────────────────────────────────────────────────────────
// SESSION PERSISTENCE
// ───────────────────────────────────────────────────────────────

/**
 * Get session file path for a given session ID
 * @param {string} sessionId - Session ID
 * @returns {string} Full path to session file
 */
function getSessionPath(sessionId) {
  // Sanitize sessionId to prevent path traversal
  const sanitized = sessionId.replace(/[^a-zA-Z0-9-]/g, '');
  return path.join(SESSION_DIR, `session-${sanitized}.json`);
}

/**
 * Save session to disk with atomic write
 *
 * @param {Object} session - Session object to save
 * @returns {Promise<void>}
 * @throws {Error} If session is invalid or write fails
 */
async function saveSession(session) {
  if (!session || !session.sessionId) {
    throw new Error('Invalid session: missing sessionId');
  }

  // Validate session structure
  if (!validateSession(session)) {
    throw new Error('Invalid session structure');
  }

  await ensureSessionDir();

  const sessionPath = getSessionPath(session.sessionId);
  const tempPath = `${sessionPath}.tmp.${Date.now()}`;

  // Update expiresAt on each save (extends TTL)
  const updatedSession = {
    ...session,
    expiresAt: new Date(Date.now() + SESSION_TTL_MS).toISOString()
  };

  try {
    // Write to temp file first (atomic write pattern)
    await fsPromises.writeFile(
      tempPath,
      JSON.stringify(updatedSession, null, 2),
      { encoding: 'utf-8', mode: FILE_PERMISSIONS }
    );

    // Atomic rename
    await fsPromises.rename(tempPath, sessionPath);

    // Ensure file permissions
    await fsPromises.chmod(sessionPath, FILE_PERMISSIONS);
  } catch (err) {
    // Clean up temp file if rename failed
    try {
      await fsPromises.unlink(tempPath);
    } catch {
      // Ignore cleanup errors
    }
    throw new Error(`Failed to save session: ${err.message}`);
  }
}

/**
 * Load session from disk
 *
 * @param {string} [sessionId] - Specific session ID to load, or null for most recent
 * @returns {Promise<Object|null>} Session object or null if expired/missing
 */
async function loadSession(sessionId = null) {
  try {
    await ensureSessionDir();

    if (sessionId) {
      // Load specific session
      return await loadSessionById(sessionId);
    } else {
      // Load most recent valid session
      return await getCurrentSession();
    }
  } catch (err) {
    console.warn(`[session-state] Failed to load session: ${err.message}`);
    return null;
  }
}

/**
 * Load a specific session by ID
 *
 * @param {string} sessionId - Session ID to load
 * @returns {Promise<Object|null>} Session or null if not found/expired
 */
async function loadSessionById(sessionId) {
  const sessionPath = getSessionPath(sessionId);

  try {
    const content = await fsPromises.readFile(sessionPath, 'utf-8');
    const session = JSON.parse(content);

    if (!isSessionValid(session)) {
      // Session expired, clean it up
      await expireSessionFile(sessionPath);
      return null;
    }

    return session;
  } catch (err) {
    if (err.code === 'ENOENT') {
      return null; // File doesn't exist
    }
    throw err;
  }
}

/**
 * Get the most recent valid session
 *
 * @returns {Promise<Object|null>} Most recent valid session or null
 */
async function getCurrentSession() {
  try {
    await ensureSessionDir();

    const files = await fsPromises.readdir(SESSION_DIR);
    const sessionFiles = files.filter(f => f.startsWith('session-') && f.endsWith('.json'));

    if (sessionFiles.length === 0) {
      return null;
    }

    // Get file stats and sort by modification time (most recent first)
    const filesWithStats = await Promise.all(
      sessionFiles.map(async (file) => {
        const filePath = path.join(SESSION_DIR, file);
        try {
          const stat = await fsPromises.stat(filePath);
          return { file, filePath, mtime: stat.mtime };
        } catch {
          return null;
        }
      })
    );

    const validFiles = filesWithStats
      .filter(f => f !== null)
      .sort((a, b) => b.mtime - a.mtime);

    // Try each file starting from most recent
    for (const { filePath } of validFiles) {
      try {
        const content = await fsPromises.readFile(filePath, 'utf-8');
        const session = JSON.parse(content);

        if (isSessionValid(session)) {
          return session;
        } else {
          // Expired session, clean it up
          await expireSessionFile(filePath);
        }
      } catch {
        // Skip corrupted files
        continue;
      }
    }

    return null;
  } catch (err) {
    console.warn(`[session-state] Failed to get current session: ${err.message}`);
    return null;
  }
}

/**
 * Update existing session (auto-saves to disk)
 *
 * @param {Object} session - Session with updated fields
 * @returns {Promise<void>}
 */
async function updateSession(session) {
  if (!session || !session.sessionId) {
    throw new Error('Invalid session: missing sessionId');
  }

  // Validate state if provided
  if (session.state && !VALID_STATES.includes(session.state)) {
    throw new Error(`Invalid session state: ${session.state}`);
  }

  // Update pagination totalResults if results changed
  if (session.results && session.pagination) {
    session.pagination.totalResults = session.results.length;
  }

  await saveSession(session);
}

// ───────────────────────────────────────────────────────────────
// SESSION VALIDATION & EXPIRATION
// ───────────────────────────────────────────────────────────────

/**
 * Check if session is valid (not expired)
 *
 * @param {Object} session - Session object to validate
 * @returns {boolean} True if session is valid and not expired
 */
function isSessionValid(session) {
  if (!session || !session.sessionId || !session.expiresAt) {
    return false;
  }

  const expiresAt = new Date(session.expiresAt);
  const now = new Date();

  return expiresAt > now;
}

/**
 * Validate session structure
 *
 * @param {Object} session - Session to validate
 * @returns {boolean} True if session has valid structure
 */
function validateSession(session) {
  if (!session || typeof session !== 'object') {
    return false;
  }

  // Required fields
  const requiredFields = ['sessionId', 'createdAt', 'expiresAt', 'state', 'query'];
  for (const field of requiredFields) {
    if (!(field in session)) {
      return false;
    }
  }

  // Validate state
  if (!VALID_STATES.includes(session.state)) {
    return false;
  }

  // Validate results is array
  if (session.results && !Array.isArray(session.results)) {
    return false;
  }

  return true;
}

/**
 * Delete a specific session file
 *
 * @param {string} filePath - Path to session file
 * @returns {Promise<boolean>} True if deleted
 */
async function expireSessionFile(filePath) {
  try {
    await fsPromises.unlink(filePath);
    return true;
  } catch (err) {
    if (err.code === 'ENOENT') {
      return true; // Already gone
    }
    console.warn(`[session-state] Failed to expire session: ${err.message}`);
    return false;
  }
}

/**
 * Delete expired sessions (cleanup)
 *
 * @returns {Promise<number>} Count of deleted sessions
 */
async function cleanupExpiredSessions() {
  let deleted = 0;

  try {
    await ensureSessionDir();

    const files = await fsPromises.readdir(SESSION_DIR);
    const sessionFiles = files.filter(f => f.startsWith('session-') && f.endsWith('.json'));

    for (const file of sessionFiles) {
      const filePath = path.join(SESSION_DIR, file);

      try {
        const content = await fsPromises.readFile(filePath, 'utf-8');
        const session = JSON.parse(content);

        if (!isSessionValid(session)) {
          if (await expireSessionFile(filePath)) {
            deleted++;
          }
        }
      } catch {
        // If we can't read/parse the file, it's corrupted - delete it
        if (await expireSessionFile(filePath)) {
          deleted++;
        }
      }
    }
  } catch (err) {
    console.warn(`[session-state] Cleanup error: ${err.message}`);
  }

  return deleted;
}

/**
 * Expire a specific session by ID
 *
 * @param {string} sessionId - Session ID to expire
 * @returns {Promise<boolean>} True if expired
 */
async function expireSession(sessionId) {
  if (!sessionId) {
    return false;
  }

  const sessionPath = getSessionPath(sessionId);
  return await expireSessionFile(sessionPath);
}

// ───────────────────────────────────────────────────────────────
// AUTO-SAVE WRAPPER
// ───────────────────────────────────────────────────────────────

/**
 * Create an auto-saving session proxy
 * Automatically saves session on any state change
 *
 * @param {Object} session - Session object to wrap
 * @returns {Object} Proxy that auto-saves on changes
 */
function createAutoSaveSession(session) {
  if (!session || !session.sessionId) {
    throw new Error('Invalid session for auto-save');
  }

  // Track pending save to debounce rapid changes
  let saveTimeout = null;
  let pendingSave = null;

  const debouncedSave = () => {
    if (saveTimeout) {
      clearTimeout(saveTimeout);
    }

    saveTimeout = setTimeout(async () => {
      try {
        await saveSession(session);
      } catch (err) {
        console.warn(`[session-state] Auto-save failed: ${err.message}`);
      }
      saveTimeout = null;
    }, 100); // 100ms debounce
  };

  // Create a proxy that triggers save on changes
  const handler = {
    set(target, property, value) {
      const result = Reflect.set(target, property, value);
      debouncedSave();
      return result;
    },

    deleteProperty(target, property) {
      const result = Reflect.deleteProperty(target, property);
      debouncedSave();
      return result;
    }
  };

  return new Proxy(session, handler);
}

/**
 * Manually trigger session save (for use after batch updates)
 *
 * @param {Object} session - Session to save
 * @returns {Promise<void>}
 */
async function forceSave(session) {
  await saveSession(session);
}

// ───────────────────────────────────────────────────────────────
// SESSION UTILITIES
// ───────────────────────────────────────────────────────────────

/**
 * Get time remaining before session expires
 *
 * @param {Object} session - Session object
 * @returns {number} Milliseconds until expiration (0 if expired)
 */
function getTimeRemaining(session) {
  if (!session || !session.expiresAt) {
    return 0;
  }

  const expiresAt = new Date(session.expiresAt);
  const now = new Date();
  const remaining = expiresAt - now;

  return Math.max(0, remaining);
}

/**
 * Get human-readable time remaining
 *
 * @param {Object} session - Session object
 * @returns {string} Human-readable time (e.g., "45 minutes")
 */
function getTimeRemainingHuman(session) {
  const ms = getTimeRemaining(session);

  if (ms === 0) {
    return 'expired';
  }

  const minutes = Math.floor(ms / 60000);

  if (minutes < 1) {
    return 'less than a minute';
  } else if (minutes === 1) {
    return '1 minute';
  } else {
    return `${minutes} minutes`;
  }
}

/**
 * List all sessions (for debugging/management)
 *
 * @returns {Promise<Object[]>} Array of session metadata
 */
async function listSessions() {
  const sessions = [];

  try {
    await ensureSessionDir();

    const files = await fsPromises.readdir(SESSION_DIR);
    const sessionFiles = files.filter(f => f.startsWith('session-') && f.endsWith('.json'));

    for (const file of sessionFiles) {
      const filePath = path.join(SESSION_DIR, file);

      try {
        const content = await fsPromises.readFile(filePath, 'utf-8');
        const session = JSON.parse(content);
        const stat = await fsPromises.stat(filePath);

        sessions.push({
          sessionId: session.sessionId,
          query: session.query,
          state: session.state,
          createdAt: session.createdAt,
          expiresAt: session.expiresAt,
          resultCount: session.results?.length || 0,
          isValid: isSessionValid(session),
          fileSize: stat.size,
          modifiedAt: stat.mtime.toISOString()
        });
      } catch {
        // Skip corrupted files
        continue;
      }
    }
  } catch (err) {
    console.warn(`[session-state] Failed to list sessions: ${err.message}`);
  }

  // Sort by creation time (newest first)
  return sessions.sort((a, b) =>
    new Date(b.createdAt) - new Date(a.createdAt)
  );
}

/**
 * Clear all sessions (for testing/reset)
 *
 * @returns {Promise<number>} Number of sessions deleted
 */
async function clearAllSessions() {
  let deleted = 0;

  try {
    await ensureSessionDir();

    const files = await fsPromises.readdir(SESSION_DIR);
    const sessionFiles = files.filter(f => f.startsWith('session-') && f.endsWith('.json'));

    for (const file of sessionFiles) {
      const filePath = path.join(SESSION_DIR, file);
      try {
        await fsPromises.unlink(filePath);
        deleted++;
      } catch {
        // Ignore deletion errors
      }
    }
  } catch (err) {
    console.warn(`[session-state] Failed to clear sessions: ${err.message}`);
  }

  return deleted;
}

// ───────────────────────────────────────────────────────────────
// MODULE EXPORTS
// ───────────────────────────────────────────────────────────────

module.exports = {
  // Session ID
  generateSessionId,

  // Session creation
  createSession,

  // Session persistence (T062, T065)
  saveSession,
  loadSession,
  getCurrentSession,
  updateSession,
  forceSave,

  // Session validation (T063)
  isSessionValid,
  validateSession,

  // Session expiration (T064)
  expireSession,
  cleanupExpiredSessions,

  // Auto-save (T066)
  createAutoSaveSession,

  // Utilities
  getTimeRemaining,
  getTimeRemainingHuman,
  listSessions,
  clearAllSessions,

  // Directory management
  ensureSessionDir,
  ensureSessionDirSync,

  // Constants
  SESSION_DIR,
  SESSION_TTL_MS,
  VALID_STATES
};
