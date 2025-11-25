/**
 * Condition-Based Waiting Patterns
 * Production-ready code templates for async operations
 *
 * Replace arbitrary setTimeout with condition polling for reliable frontend code
 */

/**
 * Wait for DOM element to exist
 * @param {string} selector - CSS selector
 * @param {number} timeout - Max wait time in ms (default: 5000)
 * @returns {Promise<Element>} The found element
 * @throws {Error} If element not found within timeout
 */
async function waitForElement(selector, timeout = 5000) {
  const startTime = Date.now();

  while (Date.now() - startTime < timeout) {
    const element = document.querySelector(selector);
    if (element) return element;

    // Check every 50ms
    await new Promise(resolve => setTimeout(resolve, 50));
  }

  throw new Error(`Element ${selector} not found after ${timeout}ms`);
}

/**
 * Wait for external library to load
 * @param {string} globalName - Name of global variable
 * @param {number} timeout - Max wait time in ms (default: 10000)
 * @returns {Promise<any>} The library object
 * @throws {Error} If library not loaded within timeout
 */
async function waitForLibrary(globalName, timeout = 10000) {
  const startTime = Date.now();

  while (Date.now() - startTime < timeout) {
    if (typeof window[globalName] !== 'undefined') {
      return window[globalName];
    }

    await new Promise(resolve => setTimeout(resolve, 50));
  }

  throw new Error(`Library ${globalName} not loaded after ${timeout}ms`);
}

/**
 * Wait for image to load
 * @param {HTMLImageElement} img - Image element
 * @returns {Promise<HTMLImageElement>} The loaded image
 */
function waitForImageLoad(img) {
  return new Promise((resolve, reject) => {
    if (img.complete) {
      // Image already loaded
      resolve(img);
    } else {
      img.addEventListener('load', () => resolve(img));
      img.addEventListener('error', () => reject(new Error('Image failed to load')));
    }
  });
}

/**
 * Wait for CSS transition to complete
 * @param {Element} element - Element with transition
 * @param {string|null} property - Specific property to wait for (optional)
 * @returns {Promise<TransitionEvent>} The transition event
 */
function waitForTransitionEnd(element, property = null) {
  return new Promise(resolve => {
    function handler(event) {
      // If property specified, only resolve for that property
      if (property && event.propertyName !== property) return;

      element.removeEventListener('transitionend', handler);
      resolve(event);
    }

    element.addEventListener('transitionend', handler);
  });
}

/**
 * Wait for video to be ready to play
 * @param {HTMLVideoElement} video - Video element
 * @returns {Promise<HTMLVideoElement>} The ready video
 */
function waitForVideoReady(video) {
  return new Promise((resolve, reject) => {
    if (video.readyState >= 3) {
      // HAVE_FUTURE_DATA or greater
      resolve(video);
    } else {
      video.addEventListener('canplay', () => resolve(video), { once: true });
      video.addEventListener('error', () => reject(new Error('Video load failed')), { once: true });
    }
  });
}

/**
 * Wait for DOM to be ready
 * @returns {Promise<void>}
 */
function domReady() {
  return new Promise(resolve => {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', resolve);
    } else {
      // DOM already ready
      resolve();
    }
  });
}

/**
 * Wait for font to load
 * @param {string} fontFamily - Font family name
 * @param {number} timeout - Max wait time in ms (default: 5000)
 * @returns {Promise<boolean>} True if loaded, false if timeout
 */
async function waitForFont(fontFamily, timeout = 5000) {
  try {
    await document.fonts.load(`1em ${fontFamily}`, '', { timeout });
    return true;
  } catch (error) {
    console.warn(`Font ${fontFamily} not loaded:`, error);
    return false;
  }
}

/**
 * Wait for all images in container to load
 * @param {string} selector - Container selector
 * @param {number} timeout - Max wait time in ms (default: 10000)
 * @returns {Promise<void>}
 */
async function waitForImages(selector, timeout = 10000) {
  const images = Array.from(document.querySelectorAll(`${selector} img`));
  const promises = images.map(img => waitForImageLoad(img));

  try {
    await Promise.race([
      Promise.all(promises),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Image load timeout')), timeout)
      )
    ]);
    console.log(`[Images] All loaded for ${selector}`);
  } catch (error) {
    console.warn(`[Images] Some failed to load for ${selector}:`, error);
    // Continue anyway after timeout
  }
}

// Export if using modules
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    waitForElement,
    waitForLibrary,
    waitForImageLoad,
    waitForTransitionEnd,
    waitForVideoReady,
    domReady,
    waitForFont,
    waitForImages
  };
}
