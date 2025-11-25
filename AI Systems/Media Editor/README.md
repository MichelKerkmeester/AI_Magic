# Media Editor System - User Guide v0.212

Transforms natural language requests into optimized images, videos, audio, and HLS streaming with **automatic MEDIA processing and 10-round optimization**.

## 📋 TABLE OF CONTENTS

1. [🆕 WHAT'S NEW IN V0.212](#1-whats-new-in-v0212)
2. [✨ KEY FEATURES](#2-key-features)
3. [🌳 SYSTEM ARCHITECTURE](#3-system-architecture)
4. [🚀 QUICK SETUP](#4-quick-setup)
5. [🔧 INSTALLING MCP TOOLS](#5-installing-mcp-tools)
6. [🧠 HOW IT WORKS](#6-how-it-works)
7. [🎛️ OPERATING MODES](#7-operating-modes)
8. [💬 EXAMPLE INTERACTIONS](#8-example-interactions)
9. [📚 RESOURCES](#9-resources)

---

<a id="1-whats-new-in-v0212"></a>
## 1. 🆕 WHAT'S NEW IN V0.212

### Documentation Improvements
- **Enhanced Readability**: Improved balance between YAML and markdown prose across MCP Intelligence documents
- **MCP Intelligence Updates**: Updated to v0.201 (Imagician) and v0.202 (Video-Audio) with clearer technical specifications
- **Better Structure**: Converted heavily YAML-formatted sections to readable markdown while preserving technical accuracy

### Features from V0.211

**HLS Adaptive Streaming Support:**
- **Multi-quality streaming**: Generate 1080p, 720p, 480p, 360p variants automatically
- **Adaptive bitrate**: Browser selects optimal quality based on viewer's bandwidth
- **Segment-based delivery**: 2-10 second segments for fast playback start
- **Universal compatibility**: Works on all modern browsers with HLS.js
- **Professional optimization**: Automatic quality presets and codec selection
- **Command shortcuts**: Use `$hls` mode for quick HLS conversion
- **Complete guide**: Dedicated HLS Video Conversion documentation (v0.100)

### 🔧 System Improvements

**Critical Bug Fixes:**
- **Version reference corrections**: Fixed all file references from v0.200 to v0.211
- **Tool verification logic**: Improved blocking behavior when required tools unavailable
- **Circular references**: Removed confusing self-referential documentation loops
- **Recovery mapping**: Added explicit RICCE validation recovery paths to MEDIA phases
- **Transparency boundaries**: Clear algorithmic rules for internal vs external visibility

**Enhanced Tool Integration:**
- **Standardized verification**: Clear "Tool Verification Priority Table" for operation routing
- **Consistent terminology**: Unified language across MCP servers and Terminal FFmpeg
- **Smart tool detection**: Automatic selection based on operation type
  - Images → Imagician (MCP)
  - Video/Audio → Video-Audio (MCP)
  - HLS Streaming → FFmpeg (Terminal)
- **Better error handling**: Clear setup guidance when tools unavailable

### 📊 Evolution: v0.211 → v0.200 → v0.114

**v0.211:** HLS streaming support, critical bug fixes, improved tool integration, enhanced documentation  
**v0.200:** Streamlined cognitive approach, pure MCP capabilities focus, enhanced conversation architecture  
**v0.114:** Original multi-perspective framework with mixed MCP documentation

---

<a id="2-key-features"></a>
## 2. ✨ KEY FEATURES

### Core Capabilities
- **Tool Verification First**: Always checks required tools before operations (blocking)
- **Universal Media Processing**: Images, videos, audio, and HLS streaming in one system
- **Natural Language Understanding**: Describe what you want in plain words
- **MEDIA Framework**: 5-phase thinking methodology with automatic depth
- **Automatic Deep Thinking**: 10 rounds of optimization for every operation
- **Streamlined Cognitive Rigor**: 3 focused media-specific optimization techniques
- **HLS Adaptive Streaming**: Multi-quality video conversion for optimal delivery
- **Pattern Learning**: Adapts to your preferences
- **Visual Feedback**: Real-time progress directly in chat
- **Rate Limiting**: Smart API usage management
- **Educational Insights**: Learn why optimizations work

### What It Can Do

**Image Operations:**
- Resize, crop, rotate, flip
- Convert between JPEG, PNG, WebP, AVIF
- Compress with quality control
- Batch process multiple images
- Extract metadata

**Video Operations:**
- Transcode between formats (MP4, MOV, AVI, WebM)
- Compress with bitrate control
- Trim and concatenate videos
- Add text/image overlays
- Extract frames for thumbnails

**Audio Operations:**
- Extract audio from videos
- Convert between formats (MP3, WAV, AAC, FLAC)
- Normalize audio levels
- Adjust sample rates
- Remove silence

**HLS Streaming Operations (NEW):**
- Multi-quality stream generation (1080p, 720p, 480p, 360p)
- Adaptive bitrate streaming for bandwidth optimization
- Segment-based delivery (2-10 second segments)
- Master and variant playlist creation
- Audio removal or extraction for streaming
- Professional codec optimization (H.264, AAC)

### What It Cannot Do
- ❌ Complex editing (color grading, effects)
- ❌ Upload to platforms
- ❌ Real-time streaming (HLS is for on-demand adaptive streaming)
- ❌ Very large files (>100MB for MCP operations, >5GB for HLS)
- ❌ AI-generated content creation

---

<a id="3-system-architecture"></a>
## 3. 🌳 SYSTEM ARCHITECTURE

```
AGENTS.md → Entry point with intelligent routing logic
    ↓
MCP System - Media Editor - v0.212.md (System prompt with MEDIA integration)
    ↓
MEDIA Thinking Framework v0.220 (5-phase methodology with cognitive rigor)
    ↓
Interactive Intelligence v0.211 (Conversation flow with two-layer transparency)
    ↓
MCP Tools:
  ├─ Imagician v0.201 (Image operations)
  ├─ Video-Audio v0.202 (Video & audio operations)
  └─ FFmpeg Terminal (HLS adaptive streaming)
    ↓
HLS Video Conversion v0.100 (Multi-quality streaming guide)
    ↓
Output → Optimized media files via MCP servers or Terminal commands
```

---

<a id="4-quick-setup"></a>
## 4. 🚀 QUICK SETUP

### Step 1: Create a Claude Project
1. Go to claude.ai
2. Click "Projects" in sidebar
3. Create new project named "Media Editor"

### Step 2: Add System Instructions
1. Click "Edit project details"
2. Find "Custom instructions" section
3. Copy and paste: `MCP - Media Editor - v0.212.md`
4. Save the project

### Step 3: Upload Reference Documents
Add these documents to your project:
- `Media Editor - Interactive Intelligence - v0.211.md`
- `Media Editor - MEDIA Thinking Framework - v0.211.md`
- `Media Editor - HLS - Video Conversion - v0.100.md`
- `Media Editor - MCP Intelligence - Imagician - v0.201.md`
- `Media Editor - MCP Intelligence - Video, Audio - v0.202.md`

### Step 4: Install MCP Tools
See next section for detailed setup

### Step 5: Start Processing
```
optimize my vacation photos          # Interactive with auto optimization
$image resize to 1920px              # Direct mode with deep thinking
$video compress presentation.mp4     # Video processing with 10 rounds
```

---

<a id="5-installing-mcp-tools"></a>
## 5. 🔧 INSTALLING MCP TOOLS

The Media Editor requires two MCP servers:

### Prerequisites
- Node.js (for Imagician)
- Python 3.8+ (for Video-Audio)
- FFmpeg (for Video-Audio)
- Claude Desktop app

### Option A: Docker Setup (Recommended)

**Prerequisites:**
- Docker Desktop installed
- Claude Desktop app

**Quick Setup:**
Ask any AI assistant:
```
Help me set up Docker containers for Media Editor MCP tools:
1. Imagician MCP: https://github.com/flowy11/imagician
2. Video-Audio MCP: https://github.com/misbahsy/video-audio-mcp

Create docker-compose.yml and configure claude_desktop_config.json.
I'm on [Windows/Mac/Linux].
```

### Option B: Direct Installation

**Imagician (NPX):**
```json
{
  "mcpServers": {
    "imagician": {
      "command": "npx",
      "args": ["-y", "@flowy11/imagician"]
    }
  }
}
```

**Video-Audio (Python/UV):**
1. Install FFmpeg first
2. Clone the repository
3. Install UV package manager
4. Configure as shown in documentation

**FFmpeg for HLS (Terminal - NEW):**
- **macOS**: `brew install ffmpeg`
- **Ubuntu/Debian**: `sudo apt install ffmpeg`
- **Windows**: Download from ffmpeg.org
- Verify: `ffmpeg -version`

**Config Location:**
- Mac: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- Linux: `~/.config/claude/claude_desktop_config.json`

### Verification
After installation, restart Claude Desktop and check:
```
🔧 Setup Verification

✔ Imagician: Connected (Images)
✔ Video-Audio: Connected (Video/Audio)
✔ FFmpeg: Installed (HLS Streaming)
✔ Configuration: Valid
✔ Thinking Mode: 10 rounds automatic

Ready for professional media processing including HLS streaming!
```

---

<a id="6-how-it-works"></a>
## 6. 🧠 HOW IT WORKS

### MCP Connection Verification

System always verifies MCP connections first:
```
🔌 MCP Connection Check

• Imagician: ✅ Connected
• Video-Audio: ✅ Connected

All media operations available with automatic optimization.
```

### Intent Recognition & Routing

| Confidence | Range | Response | Processing |
|------------|-------|----------|------------|
| **Exact** | >0.95 | Direct execution | 10 rounds auto |
| **High** | 0.80-0.95 | Clarify → Execute | 10 rounds auto |
| **Medium** | 0.50-0.79 | Explore → Execute | 10 rounds auto |
| **Low** | <0.50 | Guide → Execute | 10 rounds auto |

### MEDIA Thinking Framework v0.220 (Automatic)
1. **Pre-Check**: Verify required tools for operation type
2. **M - Measure**: Analyze source media (deep analysis)
3. **E - Evaluate**: Generate processing strategies (10 rounds)
4. **D - Decide**: Select best approach (automatic optimization)
5. **I - Implement**: Execute with monitoring
6. **A - Analyze**: Verify and learn

### Streamlined Cognitive Rigor (v0.211)

The system automatically applies **three focused media-specific techniques** for optimal results:

#### 1. Quality-Size Optimization (Automatic)
Analyzes quality requirements, evaluates compression options, and selects the optimal balance between file size reduction and visual quality.

**Example:** "User needs web display" → "85% WebP quality ideal" → "8.5MB → 425KB with no visible quality loss"

#### 2. Format Selection Analysis (Automatic)
Evaluates available formats, compares compression efficiency, checks compatibility, and selects the optimal format with reasoning.

**Example:** "PNG source for web" → "WebP 30% smaller, 96% browser support" → "WebP selected, PNG fallback available"

**HLS Example:** "Video for streaming" → "Multi-quality HLS (1080p/720p/480p/360p)" → "Adaptive delivery based on bandwidth"

#### 3. Platform Compatibility Check (Continuous)
Identifies target platform, validates format support, checks quality requirements, and flags compatibility issues.

**Example:** "WebP supported by 96% of browsers" • "Email clients prefer PNG/JPEG" • `[Note: Email use requires PNG fallback]`

**User sees:** Key optimization decisions and reasoning  
**System does:** Complete 10-round MEDIA analysis automatically

### Automatic Optimization
The system automatically applies:
- **Standard Mode**: 10 rounds of deep thinking for professional results
- **No User Input**: System determines optimal depth automatically
- **Challenge Mode**: Automatically simplifies overly complex requests

---

<a id="7-operating-modes"></a>
## 7. 🎛️ OPERATING MODES

| Mode | Command | Thinking Applied | Tool Used | Use When |
|------|---------|-----------------|-----------|----------|
| **Interactive** | DEFAULT | 10 rounds auto | Auto-detect | Guided discovery |
| **Image** | `$image`/`$img` | 10 rounds auto | Imagician (MCP) | Direct image processing |
| **Video** | `$video`/`$vid` | 10 rounds auto | Video-Audio (MCP) | Direct video processing |
| **Audio** | `$audio`/`$aud` | 10 rounds auto | Video-Audio (MCP) | Direct audio processing |
| **HLS** | `$hls` | 10 rounds auto | FFmpeg (Terminal) | Adaptive streaming (NEW) |

### Mode Activation

**Interactive Mode (Default):**
```
User: help with my media files
System: [Checking MCP connections...]
✅ Media processing ready!

Applying deep analysis (10 rounds)...

What type of media?
• Images (photos, graphics)
• Videos (movies, clips)
• Audio (music, podcasts)
```

---

<a id="8-example-interactions"></a>
## 8. 💬 EXAMPLE INTERACTIONS

### Simple Image Optimization
```
User: optimize photo for web

System: I'll optimize your photo for the web!

Applying professional optimization (10 rounds of deep analysis)...

🎬 Image Processing Operation

Thinking: Deep analysis (10 rounds applied)
Operation: Web optimization

📂 Input:
• File: photo.jpg (4.2 MB)
• Format: JPEG

🔄 Processing:
• Resize to 1920px ✔
• Convert to WebP ✔
• Optimize quality to 85% ✔

Progress: [████████████████] 100%
API calls: 2/60 🟢

✅ Operation Complete!

📊 Results:
• Size: 4.2 MB → 487 KB (88% reduction)
• Quality: 85% maintained
• Load time: 5× faster

💡 WebP provides better compression than JPEG
   Optimization determined via deep analysis

📁 Output: [Location]
```

### HLS Streaming Conversion (NEW)
```
User: $hls convert video for streaming

System: I'll convert your video to HLS adaptive streaming!

Applying professional optimization (10 rounds)...

🎬 HLS Streaming Conversion

Thinking: Deep analysis (10 rounds applied)
Operation: Multi-quality adaptive streaming

📂 Input:
• File: presentation.mp4 (450 MB)
• Format: H.264 MP4

🔄 Processing:
• Generate 1080p stream ✔
• Generate 720p stream ✔
• Generate 480p stream ✔
• Generate 360p stream ✔
• Create master playlist ✔
• Optimize segments (2s) ✔

✅ HLS Conversion Complete!

📊 Results:
• Quality levels: 4 (1080p/720p/480p/360p)
• Segments: 2-second adaptive delivery
• Total output: 485 MB (multiple quality variants)
• Bandwidth: Automatic adaptation
• Compatibility: All modern browsers + HLS.js

💡 HLS enables adaptive quality switching based on viewer's bandwidth
   Professional streaming optimized for web delivery

📁 Output: [HLS package folder with master.m3u8]

🎯 Next Steps:
• Upload HLS package to web server
• Use HLS.js for browser playback
• Test on different bandwidths
```

### API Usage Indicators
- 🟢 **Green (0-30)**: Safe zone

---

<a id="9-resources"></a>
## 9. 📚 RESOURCES

### MCP Server Documentation
- [Imagician MCP](https://github.com/flowy11/imagician) - Image processing
- [Video-Audio MCP](https://github.com/misbahsy/video-audio-mcp) - Media processing

### Tools & Platforms
- [Claude Desktop](https://claude.ai/download) - Required for MCP
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) - Container setup
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html) - Video/audio/HLS
- [Sharp Documentation](https://sharp.pixelplumbing.com/) - Image processing
- [HLS.js](https://github.com/video-dev/hls.js/) - HLS playback library (NEW)

### Format References
- [WebP Guide](https://developers.google.com/speed/webp) - Modern images
- [HLS Specification](https://datatracker.ietf.org/doc/html/rfc8216) - Adaptive streaming (NEW)
- [H.264 Overview](https://en.wikipedia.org/wiki/Advanced_Video_Coding) - Video codec
- [Audio Formats Comparison](https://www.adobe.com/creativecloud/video/discover/audio-file-formats.html)