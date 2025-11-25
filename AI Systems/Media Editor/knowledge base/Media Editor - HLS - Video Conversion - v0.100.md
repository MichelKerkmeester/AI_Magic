# Media Editor - HLS - Video Conversion

Technical reference for Terminal-based FFMPEG commands for HLS (HTTP Live Streaming) video conversion operations.

**Purpose:** Document Terminal FFMPEG command patterns, HLS conversion specifications, and technical parameters. Conversation flows and thinking methodology are in Interactive Intelligence and MEDIA Framework respectively.

---

## 📋 TABLE OF CONTENTS

1. [🔌 OVERVIEW](#1-overview)
2. [🛠️ CORE CAPABILITIES & FORMAT SUPPORT](#2-hls-fundamentals)
3. [⚙️ OPERATION SPECIFICATIONS](#3-ffmpeg-command-patterns)
4. [🎯 QUALITY OPTIMIZATION](#4-quality-presets)
5. [⚙️ CODEC SPECIFICATIONS](#5-codec-specifications)
6. [🏗️ BATCH PROCESSING](#6-batch-processing)
7. [🏎️ QUICK REFERENCE](#7-quick-reference)

---

<a id="1-overview"></a>

## 1. 🔌 OVERVIEW

### Terminal System Details

```yaml
system:
  name: "Terminal FFMPEG HLS Converter"
  package: "FFmpeg (command-line)"
  repository: "https://ffmpeg.org"
  engine: "FFmpeg (comprehensive media framework)"
  protocol: "HTTP Live Streaming (HLS)"
  language: "Shell/Bash"
  installation:
    macos: "brew install ffmpeg"
    ubuntu: "sudo apt install ffmpeg"
    windows: "Download from ffmpeg.org"
```

### Connection Verification

**Reference:** Connection verification logic is in Interactive Intelligence.

```yaml
verification:
  priority: "first_action_before_all_operations"
  command: "ffmpeg -version"
  displays:
    connected: "✅ FFmpeg Available - Terminal HLS conversion ready"
    disconnected: "❌ FFmpeg Not Found - Installation required"
  
dependencies:
  required:
    - "FFmpeg installed on system"
    - "Terminal/shell access"
    - "Write permissions for output directory"
```

---

<a id="2-hls-fundamentals"></a>

## 2. 🛠️ CORE CAPABILITIES

### Available Operations

**Note:** Thinking methodology (10 rounds standard, 1-5 quick) is defined in MEDIA Thinking Framework.

```yaml
hls_operations:
  multi_quality_conversion:
    description: "Generate multiple quality streams simultaneously"
    outputs: [master_playlist, variant_playlists, media_segments]
    qualities: ["1080p", "720p", "480p", "360p"]
    
  single_quality_conversion:
    description: "Generate single quality HLS stream"
    outputs: [playlist, media_segments]
    custom: "Any resolution and bitrate"
    
  adaptive_streaming:
    description: "Browser-driven quality switching"
    automatic: true
    bandwidth_aware: true
    
  batch_processing:
    description: "Convert multiple videos"
    tool: "Bash script automation"
    parallel: false

web_optimizations:
  faststart:
    description: "Optimize for immediate playback"
    flag: "-movflags +faststart"
    
  no_audio:
    description: "Remove audio streams"
    flag: "-an"
    savings: "20-30% file size"
    
  segment_duration:
    description: "Control segment size"
    recommended: "2 seconds"
    purpose: "Fast initial playback"
    
system_tools:
  ffmpeg:
    description: "Media conversion engine"
    returns: [hls_playlists, segments]
  
  ffprobe:
    description: "Media file analysis"
    returns: [duration, resolution, codec, bitrate]
```

### Processing Order

The optimal sequence for HLS video conversion:

1. **Verify FFmpeg Installation** - Ensure FFmpeg is available before starting
2. **Analyze Input Video** - Check source video properties (resolution, codec, duration)
3. **Determine Quality Levels** - Select appropriate quality variants based on use case
4. **Execute Conversion Command** - Run FFmpeg with optimized parameters
5. **Verify Output Structure** - Confirm all playlists and segments were created correctly

**Note:** Always verify connection before operations. This standard workflow ensures consistent results and catches issues early.

---

## 3. 📊 FORMAT SUPPORT

### HLS Protocol Overview

```yaml
hls_protocol:
  name: "HTTP Live Streaming"
  developer: "Apple Inc."
  standard: "RFC 8216"
  
  components:
    master_playlist:
      file: "master.m3u8"
      format: "Extended M3U"
      purpose: "Index of quality variants"
      
    variant_playlists:
      files: ["stream_1080p.m3u8", "stream_720p.m3u8", ...]
      format: "Extended M3U"
      purpose: "Segment lists per quality"
      
    media_segments:
      files: ["segment_000.ts", "segment_001.ts", ...]
      format: "MPEG Transport Stream"
      duration: "2-10 seconds each"
  
  advantages:
    - "Adaptive quality switching based on viewer's bandwidth"
    - "Works over standard HTTP/HTTPS (no special streaming server)"
    - "Universal browser support with HLS.js"
    - "Bandwidth efficient with intelligent quality selection"
    - "Simple hosting - just static files"
    
browser_support:
  - **Safari**: Native HLS support (iOS/macOS)
  - **Chrome, Firefox, Edge**: Via HLS.js JavaScript library
  - **Mobile browsers**: Excellent support across all platforms
```

**Note:** Format selection logic and recommendations are in MEDIA Thinking Framework Section 2 (Evaluate).

### Output File Structure

```yaml
directory_structure:
  single_quality:
    example: |
      output/
      ├── playlist.m3u8           # Main playlist
      ├── segment_000.ts          # Video segment
      ├── segment_001.ts
      └── segment_002.ts
  
  multi_quality:
    example: |
      output/
      ├── master.m3u8             # Master playlist
      ├── 1080p/                  # 1080p quality directory
      │   ├── playlist.m3u8       # 1080p variant playlist
      │   ├── segment_000.ts      # 1080p segments
      │   ├── segment_001.ts
      │   └── segment_002.ts
      ├── 720p/                   # 720p quality directory
      │   ├── playlist.m3u8       # 720p variant playlist
      │   ├── segment_000.ts      # 720p segments
      │   └── segment_001.ts
      ├── 480p/                   # 480p quality directory
      │   ├── playlist.m3u8       # 480p variant playlist
      │   └── segment_000.ts
      └── 360p/                   # 360p quality directory
          ├── playlist.m3u8       # 360p variant playlist
          └── segment_000.ts
```

### Playlist Format Examples

```yaml
master_playlist:
  file: "master.m3u8"
  content: |
    #EXTM3U
    #EXT-X-VERSION:3
    #EXT-X-STREAM-INF:BANDWIDTH=2500000,RESOLUTION=1920x1080,NAME="1080p"
    1080p/playlist.m3u8
    #EXT-X-STREAM-INF:BANDWIDTH=1500000,RESOLUTION=1280x720,NAME="720p"
    720p/playlist.m3u8
    #EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=854x480,NAME="480p"
    480p/playlist.m3u8
    #EXT-X-STREAM-INF:BANDWIDTH=500000,RESOLUTION=640x360,NAME="360p"
    360p/playlist.m3u8

variant_playlist:
  file: "1080p/playlist.m3u8"
  content: |
    #EXTM3U
    #EXT-X-VERSION:3
    #EXT-X-TARGETDURATION:2
    #EXT-X-MEDIA-SEQUENCE:0
    #EXT-X-PLAYLIST-TYPE:VOD
    #EXTINF:2.000000,
    segment_000.ts
    #EXTINF:2.000000,
    segment_001.ts
    #EXTINF:2.000000,
    segment_002.ts
    #EXT-X-ENDLIST
```

---

## 3. ⚙️ OPERATION SPECIFICATIONS

### Multi-Quality HLS Conversion

**Reference:** All parameter values optimized through MEDIA Thinking Framework analysis.

```yaml
multi_quality_conversion:
  command_structure:
    input: "ffmpeg -i INPUT_VIDEO"
    filter_complex: "Split and scale to multiple resolutions"
    mapping: "Map each stream to separate output"
    encoding: "Apply H.264 with quality-specific settings"
    hls_output: "Generate playlists and segments"
  
  parameters:
    input_video_path:
      type: string
      required: true
      description: "Path to source video file"
      formats: [mp4, mov, avi, mkv, webm]
      
    output_directory:
      type: string
      required: true
      description: "Directory for HLS output files"
      creates: [master_playlist, variant_playlists, segments]
      
    qualities:
      type: array
      default: ["1080p", "720p", "480p", "360p"]
      customizable: true
      
    segment_duration:
      type: integer
      default: 2
      unit: "seconds"
      range: [2, 10]
      
    remove_audio:
      type: boolean
      default: true
      flag: "-an"
```

### Complete Multi-Quality Command

```bash
ffmpeg -i INPUT_VIDEO.mp4 \
  -filter_complex "[0:v]split=4[v1][v2][v3][v4]; \
  [v1]scale=w=1920:h=1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2[v1out]; \
  [v2]scale=w=1280:h=720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2[v2out]; \
  [v3]scale=w=854:h=480:force_original_aspect_ratio=decrease,pad=854:480:(ow-iw)/2:(oh-ih)/2[v3out]; \
  [v4]scale=w=640:h=360:force_original_aspect_ratio=decrease,pad=640:360:(ow-iw)/2:(oh-ih)/2[v4out]" \
  -map "[v1out]" -c:v:0 libx264 -preset fast -tune fastdecode -profile:v main -level 4.0 \
    -crf 23 -maxrate:v:0 2500k -bufsize:v:0 5000k -g 48 -keyint_min 48 -sc_threshold 0 \
  -map "[v2out]" -c:v:1 libx264 -preset fast -tune fastdecode -profile:v main -level 4.0 \
    -crf 23 -maxrate:v:1 1500k -bufsize:v:1 3000k -g 48 -keyint_min 48 -sc_threshold 0 \
  -map "[v3out]" -c:v:2 libx264 -preset fast -tune fastdecode -profile:v baseline -level 3.1 \
    -crf 23 -maxrate:v:2 800k -bufsize:v:2 1600k -g 48 -keyint_min 48 -sc_threshold 0 \
  -map "[v4out]" -c:v:3 libx264 -preset fast -tune fastdecode -profile:v baseline -level 3.1 \
    -crf 23 -maxrate:v:3 500k -bufsize:v:3 1000k -g 48 -keyint_min 48 -sc_threshold 0 \
  -an \
  -f hls \
  -hls_time 2 \
  -hls_playlist_type vod \
  -hls_flags independent_segments \
  -hls_segment_type mpegts \
  -hls_segment_filename "OUTPUT_DIR/%v/segment_%03d.ts" \
  -master_pl_name "master.m3u8" \
  -var_stream_map "v:0,name:1080p v:1,name:720p v:2,name:480p v:3,name:360p" \
  OUTPUT_DIR/%v/playlist.m3u8
```

### Parameter Breakdown

**Note:** All values optimized via MEDIA Framework Section 3 (Analyze) methodology.

```yaml
input_stage:
  "-i INPUT_VIDEO.mp4":
    description: "Input video file"
    auto_detection: "Format detected by FFmpeg"
    supported_formats: [mp4, mov, avi, mkv, webm]

filter_complex_stage:
  "[0:v]split=4[v1][v2][v3][v4]":
    description: "Duplicate video stream 4 times"
    purpose: "Create 4 independent quality versions"
    
  "scale=w=1920:h=1080:force_original_aspect_ratio=decrease":
    description: "Scale to target resolution"
    behavior: "Downscale only, maintain aspect ratio"
    force_original_aspect_ratio: "Prevents upscaling"
    
  "pad=1920:1080:(ow-iw)/2:(oh-ih)/2":
    description: "Add padding to exact dimensions"
    calculation: "Center content with black bars"
    when_needed: "If aspect ratio differs"

encoding_stage:
  codec:
    "-c:v:0 libx264":
      description: "H.264 video codec"
      reason: "Universal browser compatibility"
      alternatives: [h264_nvenc, h264_videotoolbox]
      
  preset:
    "-preset fast":
      description: "Encoding speed/compression balance"
      options: [ultrafast, fast, medium, slow]
      choice_reason: "Optimal for web delivery"
      
  tune:
    "-tune fastdecode":
      description: "Optimize for playback speed"
      use_case: "Background videos, instant playback"
      
  profile:
    "-profile:v main":
      description: "H.264 profile"
      1080p_720p: "main"
      480p_360p: "baseline"
      reason: "Compatibility vs compression tradeoff"
      
  level:
    "-level 4.0":
      description: "H.264 level"
      supports: "1080p @ 30fps"
      
  quality:
    "-crf 23":
      description: "Constant Rate Factor"
      range: "0-51 (lower = better)"
      value_reason: "Visually transparent quality"
      
  bitrate:
    "-maxrate:v:0 2500k":
      description: "Maximum bitrate cap"
      purpose: "Consistent streaming bandwidth"
      per_quality:
        1080p: "2500k"
        720p: "1500k"
        480p: "800k"
        360p: "500k"
        
    "-bufsize:v:0 5000k":
      description: "Rate control buffer"
      calculation: "2x maxrate"
      purpose: "Handle bitrate variations"
      
  gop:
    "-g 48":
      description: "GOP size (keyframe interval)"
      calculation: "24fps × 2sec = 48 frames"
      purpose: "Align with segment duration"
      
    "-keyint_min 48":
      description: "Minimum keyframe interval"
      value: "Same as GOP size"
      
    "-sc_threshold 0":
      description: "Scene change detection"
      value: "0 = disabled"
      reason: "Predictable segment structure"

audio_stage:
  "-an":
    description: "Remove audio stream"
    savings: "20-30% file size"
    use_case: "Background videos, autoplay"

hls_stage:
  format:
    "-f hls":
      description: "Output format HLS"
      
  segment_duration:
    "-hls_time 2":
      description: "Segment length in seconds"
      recommended: "2 seconds"
      reason: "Fast initial playback"
      
  playlist_type:
    "-hls_playlist_type vod":
      description: "Video on Demand"
      options: [vod, event, live]
      
  flags:
    "-hls_flags independent_segments":
      description: "Independently decodable segments"
      benefit: "Seamless quality switching"
      
  segment_type:
    "-hls_segment_type mpegts":
      description: "MPEG Transport Stream"
      extension: ".ts"
      
  naming:
    "-hls_segment_filename":
      pattern: "%v/segment_%03d.ts"
      variables:
        "%v": "Variant stream name (1080p, 720p, 480p, 360p)"
        "%03d": "Segment number (000, 001...)"
      structure: "Creates subdirectory per quality level"
        
  master:
    "-master_pl_name":
      value: "master.m3u8"
      purpose: "Entry point for adaptive streaming"
      location: "Root of output directory"
      
  output_pattern:
    format: "%v/playlist.m3u8"
    description: "Creates quality subdirectories with playlists"
    structure: "OUTPUT_DIR/1080p/playlist.m3u8, OUTPUT_DIR/720p/playlist.m3u8, etc."
```

### Single Quality Conversion

```yaml
single_quality_pattern:
  use_case: "When only one quality needed"
  
  parameters:
    input_video_path:
      type: string
      required: true
      
    output_directory:
      type: string
      required: true
      
    resolution:
      type: string
      format: "WIDTHxHEIGHT"
      example: "1920x1080"
      
    maxrate:
      type: string
      format: "NUMBER[k|M]"
      example: "2500k"
      
  command: |
    ffmpeg -i INPUT_VIDEO.mp4 \
      -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" \
      -c:v libx264 -preset fast -tune fastdecode -profile:v main -level 4.0 \
      -crf 23 -maxrate 2500k -bufsize 5000k \
      -g 48 -keyint_min 48 -sc_threshold 0 \
      -an \
      -f hls -hls_time 2 -hls_playlist_type vod \
      -hls_flags independent_segments \
      -hls_segment_filename "OUTPUT_DIR/segment_%03d.ts" \
      OUTPUT_DIR/playlist.m3u8
```

### Testing Command

```yaml
test_conversion:
  purpose: "Quick verification of parameters"
  duration: "10 seconds only"
  
  command: |
    ffmpeg -i INPUT_VIDEO.mp4 -t 10 \
      -vf "scale=1920:1080" \
      -c:v libx264 -preset fast -crf 23 -maxrate 2500k \
      -an test_output.mp4
```

---

## 4. 🎯 QUALITY OPTIMIZATION

### Quality Presets

**Note:** Quality vs size optimization logic is in MEDIA Framework Section 2 (Evaluate).

```yaml
quality_presets:
  "1080p":
    resolution: "1920x1080"
    bitrate_max: "2500k"
    bitrate_buffer: "5000k"
    profile: "main"
    level: "4.0"
    use_case: "Desktop displays, high-end"
    file_size_estimate: "~2.5MB per 10 seconds"
    
  "720p":
    resolution: "1280x720"
    bitrate_max: "1500k"
    bitrate_buffer: "3000k"
    profile: "main"
    level: "4.0"
    use_case: "Desktop standard, tablets"
    file_size_estimate: "~1.5MB per 10 seconds"
    
  "480p":
    resolution: "854x480"
    bitrate_max: "800k"
    bitrate_buffer: "1600k"
    profile: "baseline"
    level: "3.1"
    use_case: "Mobile devices, slower connections"
    file_size_estimate: "~800KB per 10 seconds"
    
  "360p":
    resolution: "640x360"
    bitrate_max: "500k"
    bitrate_buffer: "1000k"
    profile: "baseline"
    level: "3.1"
    use_case: "Very slow connections, legacy"
    file_size_estimate: "~500KB per 10 seconds"
```

### CRF (Constant Rate Factor) Guidelines

```yaml
crf_scale:
  range: "0-51"
  description: "Quality control (lower = better)"
  
  values:
    "18": "Visually lossless"
    "23": "High quality (RECOMMENDED)"
    "28": "Medium quality"
    
  recommendations:
    standard: "23"
    premium_quality: "20-22"
    bandwidth_limited: "24-26"
```

### Adaptive Streaming Selection

HLS enables browsers to automatically select the best quality based on available bandwidth and device capabilities.

**Automatic Quality Selection by Bandwidth:**
- **> 3 Mbps**: 1080p stream preferred
- **1.5-3 Mbps**: 720p stream
- **700kb-1.5 Mbps**: 480p stream  
- **< 700kb**: 360p stream

**Device-Specific Considerations:**
- **Desktop (large screen)**: Prefers 1080p, falls back gracefully
- **Desktop (standard)**: Starts with 720p
- **Tablet**: Starts with 720p, adapts based on connection
- **Mobile**: Typically starts at 480p or 360p to ensure fast playback

**Dynamic Switching Behavior:**
- When buffer runs low → switches to lower quality automatically
- When bandwidth improves → upgrades quality after stable period
- All transitions are seamless with no playback interruption

---

## 5. ⚙️ CODEC SPECIFICATIONS

### H.264 Profile Details

```yaml
h264_profiles:
  baseline:
    use: "480p, 360p streams"
    features: "Basic encoding"
    compatibility: "Maximum (all devices)"
    compression: "Lower efficiency"
    
  main:
    use: "1080p, 720p streams"
    features: "Advanced encoding, B-frames"
    compatibility: "Modern devices (post-2010)"
    compression: "Better efficiency"
    
  high:
    use: "4K, professional production"
    features: "Maximum compression"
    compatibility: "High-end devices only"
    compression: "Best efficiency"
```

### H.264 Level Details

```yaml
h264_levels:
  "3.1":
    max_resolution: "1280x720"
    max_framerate: "30 fps"
    use_for: "480p, 360p streams"
    
  "4.0":
    max_resolution: "1920x1080"
    max_framerate: "30 fps"
    use_for: "1080p, 720p streams"
    
  "4.1":
    max_resolution: "1920x1080"
    max_framerate: "60 fps"
    use_for: "High framerate 1080p"
```

### GOP (Group of Pictures) Structure

```yaml
gop_configuration:
  definition: "Keyframe interval in frames"
  
  calculation:
    formula: "framerate × segment_duration"
    example: "24 fps × 2 sec = GOP 48"
    
  importance:
    - "Aligns with segment boundaries"
    - "Enables clean quality switching"
    - "Ensures independent playback"
    
  keyframe_types:
    I_frame: "Complete frame (keyframe)"
    P_frame: "Predicted from previous"
    B_frame: "Bidirectional prediction"
```

### Buffer Size Logic

```yaml
buffer_size_calculation:
  standard_rule: "bufsize = 2 × maxrate"
  
  reasoning:
    - "Allows bitrate variations"
    - "Prevents encoder overflow"
    - "Maintains quality consistency"
    
  examples:
    "1080p": "maxrate 2500k → bufsize 5000k"
    "720p": "maxrate 1500k → bufsize 3000k"
    "480p": "maxrate 800k → bufsize 1600k"
    "360p": "maxrate 500k → bufsize 1000k"
```

### Segment Duration Analysis

```yaml
segment_duration_options:
  "2_seconds":
    pros:
      - "Fast initial playback"
      - "Quick quality switching"
      - "Better user experience"
    cons:
      - "More segment files"
      - "Slightly more overhead"
    recommended: true
    
  "4_seconds":
    pros:
      - "Fewer segment files"
      - "Less overhead"
    cons:
      - "Slower initial playback"
      - "Slower quality switching"
    
  "6-10_seconds":
    pros:
      - "Minimal segment count"
    cons:
      - "Poor initial load time"
      - "Sluggish quality adaptation"
    recommended: false
```

---

## 6. 🏗️ BATCH PROCESSING

### Bash Script for Multiple Videos

**Complete conversion script with automation and error handling.**

```bash
#!/bin/bash

# ──────────────────────────────────────────────────────────────────────────────
# HLS Hero Video Converter
# Converts multiple videos to HLS with 4 quality levels
# Optimized for website hero background videos
# ──────────────────────────────────────────────────────────────────────────────

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
OUTPUT_BASE="hls_output"
QUALITIES=("1080p" "720p" "480p" "360p")

# Video files to process
VIDEOS=(
  "Dit-is-Nobel-Hero.mp4"
  "Home-Hero.mov"
  "Locatie-Hero.mp4"
)

# Quality settings
declare -A RESOLUTIONS=(
  ["1080p"]="1920:1080"
  ["720p"]="1280:720"
  ["480p"]="854:480"
  ["360p"]="640:360"
)

declare -A MAXRATES=(
  ["1080p"]="2500k"
  ["720p"]="1500k"
  ["480p"]="800k"
  ["360p"]="500k"
)

declare -A BUFSIZES=(
  ["1080p"]="5000k"
  ["720p"]="3000k"
  ["480p"]="1600k"
  ["360p"]="1000k"
)

declare -A PROFILES=(
  ["1080p"]="main"
  ["720p"]="main"
  ["480p"]="baseline"
  ["360p"]="baseline"
)

# ──────────────────────────────────────────────────────────────────────────────
# Functions
# ──────────────────────────────────────────────────────────────────────────────

check_ffmpeg() {
  if ! command -v ffmpeg &> /dev/null; then
    echo -e "${RED}❌ FFmpeg not found${NC}"
    echo "Install FFmpeg:"
    echo "  macOS: brew install ffmpeg"
    echo "  Ubuntu: sudo apt install ffmpeg"
    echo "  Windows: Download from ffmpeg.org"
    exit 1
  fi
  
  echo -e "${GREEN}✅ FFmpeg found: $(ffmpeg -version | head -n 1)${NC}"
}

check_input_file() {
  local file=$1
  if [ ! -f "$file" ]; then
    echo -e "${RED}❌ File not found: $file${NC}"
    return 1
  fi
  return 0
}

get_video_info() {
  local file=$1
  echo -e "${YELLOW}📹 Video Info: $file${NC}"
  ffprobe -v quiet -print_format json -show_format -show_streams "$file" | \
    grep -E '"width"|"height"|"duration"|"codec_name"' | head -5
  echo ""
}

convert_to_hls() {
  local input=$1
  local basename=$(basename "$input" | sed 's/\.[^.]*$//')
  local output_dir="$OUTPUT_BASE/$basename"
  
  echo -e "${YELLOW}🎬 Converting: $input${NC}"
  echo -e "${YELLOW}📁 Output: $output_dir${NC}"
  
  # Create output directory
  mkdir -p "$output_dir"
  
  # Get video duration for progress estimation
  local duration=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$input")
  echo -e "${YELLOW}⏱️  Duration: ${duration}s${NC}"
  
  # Start conversion with progress
  echo -e "${GREEN}▶️  Starting HLS conversion...${NC}"
  
  ffmpeg -i "$input" -hide_banner -loglevel warning -stats \
    -filter_complex "[0:v]split=4[v1][v2][v3][v4]; \
    [v1]scale=w=1920:h=1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2[v1out]; \
    [v2]scale=w=1280:h=720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2[v2out]; \
    [v3]scale=w=854:h=480:force_original_aspect_ratio=decrease,pad=854:480:(ow-iw)/2:(oh-ih)/2[v3out]; \
    [v4]scale=w=640:h=360:force_original_aspect_ratio=decrease,pad=640:360:(ow-iw)/2:(oh-ih)/2[v4out]" \
    -map "[v1out]" -c:v:0 libx264 -preset fast -tune fastdecode -profile:v main -level 4.0 \
      -crf 23 -maxrate:v:0 2500k -bufsize:v:0 5000k -g 48 -keyint_min 48 -sc_threshold 0 \
    -map "[v2out]" -c:v:1 libx264 -preset fast -tune fastdecode -profile:v main -level 4.0 \
      -crf 23 -maxrate:v:1 1500k -bufsize:v:1 3000k -g 48 -keyint_min 48 -sc_threshold 0 \
    -map "[v3out]" -c:v:2 libx264 -preset fast -tune fastdecode -profile:v baseline -level 3.1 \
      -crf 23 -maxrate:v:2 800k -bufsize:v:2 1600k -g 48 -keyint_min 48 -sc_threshold 0 \
    -map "[v4out]" -c:v:3 libx264 -preset fast -tune fastdecode -profile:v baseline -level 3.1 \
      -crf 23 -maxrate:v:3 500k -bufsize:v:3 1000k -g 48 -keyint_min 48 -sc_threshold 0 \
    -an \
    -f hls \
    -hls_time 2 \
    -hls_playlist_type vod \
    -hls_flags independent_segments \
    -hls_segment_type mpegts \
    -hls_segment_filename "$output_dir/%v/segment_%03d.ts" \
    -master_pl_name "master.m3u8" \
    -var_stream_map "v:0,name:1080p v:1,name:720p v:2,name:480p v:3,name:360p" \
    "$output_dir/%v/playlist.m3u8"
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Success: $basename${NC}"
    generate_report "$output_dir"
  else
    echo -e "${RED}❌ Failed: $basename${NC}"
    return 1
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Main Execution
# ──────────────────────────────────────────────────────────────────────────────

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎬 HLS Hero Video Converter${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check FFmpeg installation
check_ffmpeg
echo ""

# Create base output directory
mkdir -p "$OUTPUT_BASE"

# Process each video
success_count=0
fail_count=0

for video in "${VIDEOS[@]}"; do
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  if check_input_file "$video"; then
    get_video_info "$video"
    
    if convert_to_hls "$video"; then
      ((success_count++))
    else
      ((fail_count++))
    fi
  else
    ((fail_count++))
  fi
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
done

# Final summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 Batch Conversion Complete${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "✅ Success: ${GREEN}$success_count${NC}"
echo -e "❌ Failed:  ${RED}$fail_count${NC}"
echo ""
echo "📁 Output directory: $OUTPUT_BASE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

### generate_report Function

The script includes a reporting function that displays conversion results:

```bash
generate_report() {
  local dir=$1
  echo ""
  echo -e "${GREEN}📊 Conversion Report${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Count files
  local segment_count=$(find "$dir" -name "*.ts" | wc -l)
  local playlist_count=$(find "$dir" -name "*.m3u8" | wc -l)
  
  echo "📁 Output directory: $dir"
  echo "📝 Playlists: $playlist_count"
  echo "🎞️  Segments: $segment_count"
  echo ""
  
  # File sizes by quality
  for quality in "${QUALITIES[@]}"; do
    local quality_dir="$dir/$quality"
    if [ -d "$quality_dir" ]; then
      local size=$(du -sh "$quality_dir" 2>/dev/null | awk '{print $1}')
      if [ -n "$size" ]; then
        echo "  $quality: $size"
      fi
    fi
  done
  
  echo ""
  local total_size=$(du -sh "$dir" | awk '{print $1}')
  echo "📦 Total size: $total_size"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}
```

### Usage Instructions

**Save and Prepare the Script:**

1. Save the script as `convert_hls.sh`
2. Make it executable:
   ```bash
   chmod +x convert_hls.sh
   ```

**Configure Your Videos:**

Edit the `VIDEOS` array in the script:
```bash
VIDEOS=(
  "your-video-1.mp4"
  "your-video-2.mov"
  "your-video-3.mp4"
)
```

**Run the Conversion:**

Execute the script:
```bash
./convert_hls.sh
```

The script will create an `hls_output/` directory with subdirectories for each video.

**Output Structure:**
```
hls_output/
├── video-name-1/
│   ├── master.m3u8
│   ├── 1080p/
│   │   ├── playlist.m3u8
│   │   └── segment_*.ts
│   ├── 720p/
│   │   ├── playlist.m3u8
│   │   └── segment_*.ts
│   ├── 480p/
│   └── 360p/
└── video-name-2/
    └── ...
```

**Test Output:**

Test playback with FFplay:
```bash
ffplay hls_output/VIDEO_NAME/master.m3u8
```

Or start a local web server:
```bash
python3 -m http.server 8000
# Then open: http://localhost:8000/hls_output/VIDEO_NAME/master.m3u8
```

---

## 7. 🏎️ QUICK REFERENCE

### Command Templates

```yaml
quick_commands:
  multi_quality_4k:
    description: "Four quality levels (1080p, 720p, 480p, 360p)"
    command: |
      ffmpeg -i input.mp4 \
        -filter_complex "[0:v]split=4[v1][v2][v3][v4]; \
        [v1]scale=1920:1080[v1out]; [v2]scale=1280:720[v2out]; \
        [v3]scale=854:480[v3out]; [v4]scale=640:360[v4out]" \
        -map "[v1out]" -c:v:0 libx264 -preset fast -crf 23 -maxrate:v:0 2500k -bufsize:v:0 5000k -g 48 \
        -map "[v2out]" -c:v:1 libx264 -preset fast -crf 23 -maxrate:v:1 1500k -bufsize:v:1 3000k -g 48 \
        -map "[v3out]" -c:v:2 libx264 -preset fast -crf 23 -maxrate:v:2 800k -bufsize:v:2 1600k -g 48 \
        -map "[v4out]" -c:v:3 libx264 -preset fast -crf 23 -maxrate:v:3 500k -bufsize:v:3 1000k -g 48 \
        -an -f hls -hls_time 2 -hls_playlist_type vod -hls_flags independent_segments \
        -hls_segment_filename "output/%v/segment_%03d.ts" \
        -master_pl_name "master.m3u8" \
        -var_stream_map "v:0,name:1080p v:1,name:720p v:2,name:480p v:3,name:360p" \
        output/%v/playlist.m3u8
  
  single_quality_1080p:
    description: "Single 1080p HLS stream"
    command: |
      ffmpeg -i input.mp4 \
        -vf "scale=1920:1080" \
        -c:v libx264 -preset fast -crf 23 -maxrate 2500k -bufsize 5000k \
        -g 48 -keyint_min 48 -sc_threshold 0 -an \
        -f hls -hls_time 2 -hls_playlist_type vod \
        -hls_segment_filename "output/seg_%03d.ts" \
        output/playlist.m3u8
  
  test_10_seconds:
    description: "Test encoding (first 10 seconds)"
    command: |
      ffmpeg -i input.mp4 -t 10 \
        -vf "scale=1920:1080" \
        -c:v libx264 -preset fast -crf 23 -maxrate 2500k \
        -an test.mp4
  
  analyze_video:
    description: "Get video information"
    command: "ffprobe -v quiet -print_format json -show_format -show_streams input.mp4"
  
  check_ffmpeg:
    description: "Verify FFmpeg installation"
    command: "ffmpeg -version"
```

### Integration References

```yaml
related_documents:
  mcp_operations:
    file: "Media Editor - MCP Intelligence - Video, Audio"
    relationship: "Complementary operations"
    when_to_use_mcp:
      - "Single format conversions"
      - "Interactive editing (trim, overlay)"
      - "Audio extraction/processing"
    when_to_use_terminal:
      - "HLS multi-quality conversion"
      - "Batch processing"
      - "Adaptive streaming requirements"
    
  thinking_methodology:
    file: "Media Editor - MEDIA Thinking Framework"
    sections:
      - "Section 2: MEDIA Principles (quality optimization)"
      - "Section 3: Cognitive Rigor (parameter selection)"
      - "Section 9: MCP Troubleshooting"
    
  conversation_flow:
    file: "Media Editor - Interactive Intelligence"
    sections:
      - "Section 1: Conversation Architecture"
      - "Section 2: Response Templates"
      - "Section 5: Error Recovery"
```

### Troubleshooting Quick Fixes

**FFmpeg Not Found**
```
Error: ffmpeg: command not found
```
**Solution:**
- macOS: `brew install ffmpeg`
- Ubuntu: `sudo apt install ffmpeg`
- Windows: Download from ffmpeg.org, add to PATH
- Verify: `ffmpeg -version`

---

**Codec Not Supported**
```
Error: Unknown encoder 'libx264'
```
**Solution:** Install FFmpeg with libx264 support
- Verify codec availability: `ffmpeg -codecs | grep 264`

---

**Permission Denied**
```
Error: Permission denied
```
**Solution:**
- For script: `chmod +x script.sh`
- For directory: `mkdir -p output_directory`

---

**Segments Not Created**
```
Error: No .ts files generated
```
**Check:** Verify output directory and subdirectories exist
- FFmpeg will auto-create subdirectories with `%v` pattern
- Manual creation if needed: `mkdir -p output/{1080p,720p,480p,360p}`

---

**Large File Size**
```
Issue: Output files too large
```
**Solutions:**
1. Increase CRF (lower quality): `-crf 26` (was 23)
2. Reduce bitrate: `-maxrate 2000k` (was 2500k)
3. Lower resolution: Remove 1080p variant

---

**Poor Video Quality**
```
Issue: Video looks blocky or pixelated
```
**Solutions:**
1. Decrease CRF (higher quality): `-crf 20` (was 23)
2. Increase bitrate: `-maxrate 3000k` (was 2500k)
3. Use slower preset: `-preset medium` (was fast)

---

**Playback Issues in Browser**
```
Error: Video won't play in browser
```
**Checklist:**
1. Verify HLS.js library is loaded
2. Check browser console for JavaScript errors
3. Test with FFplay: `ffplay master.m3u8`
4. If serving from different domain, verify CORS headers are set

### Performance Benchmarks

Encoding times vary significantly based on CPU performance, source codec complexity, and video content. These are approximate estimates:

**10-Second Video:**
- Single quality: 10-30 seconds
- Four qualities: 30-90 seconds

**30-Second Video:**
- Single quality: 30-120 seconds (0.5-2 minutes)
- Four qualities: 2-5 minutes

**60-Second Video:**
- Single quality: 1-3 minutes
- Four qualities: 4-10 minutes

*Note: Actual times depend on hardware, source format, and encoding settings. GPU acceleration can significantly reduce these times.*

### GPU Acceleration Options

GPU acceleration can significantly speed up encoding (2-5x faster) but may produce slightly lower quality compared to software encoding.

**NVIDIA NVENC** (NVIDIA GPUs)
- Codec: `h264_nvenc`
- Replace: `-c:v libx264` → `-c:v h264_nvenc`
- Speed benefit: 3-5x faster
- Quality: Slightly lower than software

**Intel Quick Sync** (Intel CPUs with integrated graphics)
- Codec: `h264_qsv`
- Replace: `-c:v libx264` → `-c:v h264_qsv`
- Speed benefit: 2-4x faster

**macOS VideoToolbox** (Apple hardware)
- Codec: `h264_videotoolbox`
- Replace: `-c:v libx264` → `-c:v h264_videotoolbox`
- Speed benefit: 2-3x faster on Mac

**Recommendation:**
- Use `libx264` (software) for best quality and compatibility
- Consider GPU encoding for large batches where speed is critical
- Test quality output before committing to GPU encoding for production

### Verification Commands

**Check Master Playlist:**
```bash
cat output/master.m3u8
```
Look for multiple `#EXT-X-STREAM-INF` entries listing all quality variants.

**List Generated Segments:**
```bash
ls -lh output/**/*.ts
```
Should show multiple `.ts` files organized in quality directories.

**Test Playback Locally:**
```bash
ffplay output/master.m3u8
```
*Note: FFplay is included with FFmpeg installation*

**Analyze Quality Stream:**
```bash
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,bit_rate \
  output/1080p/playlist.m3u8
```
Verify resolution and bitrate match expectations.

### Limitations

**Terminal Requirements:**
- FFmpeg must be installed on system
- Command-line/terminal access required
- Write permissions needed for output directory

**Operation Constraints:**

*What Terminal FFMPEG Can Do:*
- HLS conversion with all quality levels
- Batch processing via shell scripts
- Custom encoding parameters
- Any format conversion FFmpeg supports

*What Terminal FFMPEG Cannot Do:*
- Interactive editing (use MCP Video-Audio server instead)
- Real-time preview during encoding
- GUI interface
- Live streaming (requires streaming server)

**Format Support:**
- **Input**: Any video format supported by FFmpeg (MP4, MOV, AVI, MKV, WebM, etc.)
- **Output**: HLS format only (.m3u8 playlists + .ts segments)

**When to Use MCP vs Terminal:**
- Use **MCP Video-Audio** for: Single format conversions, interactive editing, trim/overlay operations
- Use **Terminal FFMPEG** for: HLS multi-quality streaming, batch processing, automated workflows

---

*This document focuses exclusively on Terminal-based FFMPEG commands for HLS conversion. For MCP operations, see Video-Audio MCP Intelligence. For thinking methodology, see MEDIA Framework. For conversation flows, see Interactive Intelligence.*