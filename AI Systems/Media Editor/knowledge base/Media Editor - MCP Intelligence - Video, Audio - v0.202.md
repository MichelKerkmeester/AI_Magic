# Media Editor - MCP Intelligence - Video, Audio

Technical reference for Video-Audio MCP server capabilities and integration for video and audio processing operations.

**Purpose:** Document Video-Audio MCP specific features, supported operations, and technical specifications. Conversation flows and thinking methodology are in Interactive Intelligence and MEDIA Framework respectively.

---

## 📋 TABLE OF CONTENTS

1. [🔌 SERVER OVERVIEW](#1-server-overview)
2. [🛠️ CORE CAPABILITIES](#2-core-capabilities)
3. [🎬 VIDEO OPERATIONS](#3-video-operations)
4. [🎵 AUDIO OPERATIONS](#4-audio-operations)
5. [🎨 ADVANCED FEATURES](#5-advanced-features)
6. [📊 FORMAT SUPPORT](#6-format-support)
7. [⚙️ CODEC SPECIFICATIONS](#7-codec-specifications)
8. [🏎️ QUICK REFERENCE](#8-quick-reference)

---

<a id="1-server-overview"></a>

## 1. 🔌 SERVER OVERVIEW

### MCP Server Details

The Video-Audio MCP Server (`@misbahsy/video-audio-mcp`) provides comprehensive video and audio processing capabilities powered by FFmpeg. It enables format conversion, editing, optimization, and advanced effects through native MCP integration.

**Key Information:**
- **Package:** `@misbahsy/video-audio-mcp`
- **Repository:** https://github.com/misbahsy/video-audio-mcp
- **Engine:** FFmpeg (comprehensive media framework)
- **Protocol:** Model Context Protocol (MCP)
- **Language:** Python

**Installation:**
- **Recommended:** UV package manager (`uv sync`)
- **Alternative:** Python pip

### Connection Verification

**Reference:** Connection verification logic is in Interactive Intelligence.

Connection verification must be the **first action before all operations**. Use the `health_check` tool to verify server status and FFmpeg availability.

**Status Messages:**
- ✅ **Connected:** "Video-Audio MCP Connected - Media processing available"
- ❌ **Disconnected:** "Video-Audio MCP Not Connected - Setup required"

**Required Dependencies:**
- FFmpeg must be installed on the system
- Python environment properly configured
- MCP server running and accessible

---

<a id="2-core-capabilities"></a>

## 2. 🛠️ CORE CAPABILITIES

### Available Operations

**Note:** Thinking methodology (10 rounds standard, 1-5 quick) is defined in MEDIA Thinking Framework.

The Video-Audio MCP server provides comprehensive media processing capabilities organized into several categories:

**Video Format Conversion:**
- `convert_video_format` - Convert between video formats (MP4, MOV, AVI, WebM, MKV)
- `convert_video_properties` - Advanced conversion with codec and quality control

**Video Editing:**
- `trim_video` - Extract specific time segments
- `concatenate_videos` - Join multiple videos with optional transitions
- `adjust_video_speed` - Create slow motion or timelapse effects

**Video Properties:**
- `set_video_resolution` - Change video dimensions
- `change_aspect_ratio` - Adjust aspect ratio (16:9, 4:3, 1:1, 9:16, 21:9)
- `set_video_codec` - Change video encoding codec

**Video Optimization:**
- `set_video_bitrate` - Control video quality and file size
- `set_video_frame_rate` - Adjust frames per second (24, 30, 60)

**Visual Effects:**
- `fade_in_out` - Add smooth fade transitions
- `add_transition_effect` - Apply various transition effects

**Audio Operations:**
- `extract_audio_from_video` - Extract audio tracks
- `convert_audio_format` - Convert between audio formats
- `convert_audio_properties` - Advanced audio conversion
- `remove_silence` - Automatically remove silent segments

**Advanced Features:**
- `add_text_overlay` - Add text to videos
- `add_image_overlay` - Add watermarks or logos
- `add_subtitle` - Embed subtitle files
- `insert_broll` - Insert B-roll footage

**System Tools:**
- `health_check` - Verify server status and FFmpeg version

---

<a id="3-video-operations"></a>

## 3. 🎬 VIDEO OPERATIONS

### Format Conversion

```yaml
convert_video_format:
  parameters:
    video_path:
      type: string
      required: true
      
    output_video_path:
      type: string
      required: true
      
    target_format:
      type: string
      required: true
      options: [mp4, mov, avi, webm, mkv]
      
convert_video_properties:
  parameters:
    input_video_path:
      type: string
      required: true
      
    output_video_path:
      type: string
      required: true
      
    target_format:
      type: string
      optional: true
      
    resolution:
      type: string
      format: "WIDTHxHEIGHT"
      example: "1920x1080"
      
    video_codec:
      type: string
      examples: [libx264, libx265, vp9]
      
    audio_codec:
      type: string
      examples: [aac, mp3, opus]
      
    video_bitrate:
      type: string
      format: "NUMBER[K|M]"
      example: "5M"
      
    audio_bitrate:
      type: string
      format: "NUMBER[K]"
      example: "192k"
      
    frame_rate:
      type: integer
      common: [24, 30, 60]
```

### Video Editing

```yaml
trim_video:
  parameters:
    video_path:
      type: string
      required: true
      
    output_video_path:
      type: string
      required: true
      
    start_time:
      type: string
      formats: ["HH:MM:SS", "seconds"]
      examples: ["00:01:30", "90"]
      
    end_time:
      type: string
      formats: ["HH:MM:SS", "seconds"]
      
concatenate_videos:
  parameters:
    video_paths:
      type: array
      items: string
      required: true
      
    output_video_path:
      type: string
      required: true
      
    transition:
      type: string
      options: [fade, dissolve, wipe, none]
      
adjust_video_speed:
  parameters:
    video_path:
      type: string
      required: true
      
    output_video_path:
      type: string
      required: true
      
    speed_factor:
      type: float
      range: [0.25, 4.0]
      examples:
        slow_motion: [0.25, 0.5]
        normal: 1.0
        timelapse: [2.0, 4.0]
```

### Resolution and Aspect Ratio

**Set Video Resolution:**

Change video dimensions to specific width and height values.

```yaml
set_video_resolution:
  parameters:
    video_path: string (required)
    output_video_path: string (required)
    width: integer (required)
    height: integer (required)
```

**Change Aspect Ratio:**

Adjust video aspect ratio to common formats. This operation may crop or add letterboxing depending on the source and target ratios.

```yaml
change_aspect_ratio:
  parameters:
    video_path: string (required)
    output_video_path: string (required)
    aspect_ratio: string (required)
      options: ["16:9", "4:3", "1:1", "9:16", "21:9"]
```

**Common Aspect Ratios:**

| Ratio | Use Case | Common Resolutions |
|-------|----------|-------------------|
| 16:9 | Standard video (YouTube, TV) | 1920x1080, 1280x720 |
| 4:3 | Legacy content | 640x480, 800x600 |
| 1:1 | Social media square (Instagram) | 1080x1080, 720x720 |
| 9:16 | Vertical video (Stories, TikTok) | 1080x1920, 720x1280 |
| 21:9 | Cinematic ultrawide | 2560x1080, 3440x1440 |

---

<a id="4-audio-operations"></a>

## 4. 🎵 AUDIO OPERATIONS

### Audio Extraction and Conversion

```yaml
extract_audio_from_video:
  parameters:
    video_path:
      type: string
      required: true
      
    output_audio_path:
      type: string
      required: true
      
    audio_codec:
      type: string
      optional: true
      common: [aac, mp3, flac]
      
convert_audio_format:
  parameters:
    input_audio_path:
      type: string
      required: true
      
    output_audio_path:
      type: string
      required: true
      
    target_format:
      type: string
      required: true
      
    bitrate:
      type: string
      optional: true
      
    sample_rate:
      type: integer
      optional: true
      
    channels:
      type: integer
      optional: true
      options: [1, 2]
      
convert_audio_properties:
  parameters:
    input_audio_path:
      type: string
      required: true
      
    output_audio_path:
      type: string
      required: true
      
    target_format:
      type: string
      optional: true
      
    bitrate:
      type: string
      optional: true
      
    sample_rate:
      type: integer
      optional: true
      
    channels:
      type: integer
      optional: true
```

### Audio Quality Guidelines

**Note:** Quality vs size optimization logic is in MEDIA Framework Section 2 (Evaluate).

Audio bitrate determines the quality and file size of audio output. Choose the appropriate preset based on your content type and quality requirements.

**Bitrate Recommendations:**

| Preset | Bitrate | Use Case | File Size | Quality |
|--------|---------|----------|-----------|---------|
| Voice Only | 96k | Speech, podcasts | Smallest | Acceptable for voice |
| Standard | 128k | General audio | Small | Good for most uses |
| Music Streaming | 192k | Music, good quality | Moderate | High quality audio |
| High Quality | 256k | High quality music | Large | Very high quality |
| Maximum | 320k | Archival, production | Largest | Maximum quality |

**Sample Rate Options:**
- **22.05 kHz** - Voice/speech minimal quality
- **44.1 kHz** - CD quality (standard for music)
- **48 kHz** - Professional audio/video production

**Channel Options:**
- **1** - Mono (voice, podcasts)
- **2** - Stereo (music, video)
    use: "Standard music"
    
  professional:
    rate: 48000
    use: "Video production"
    
  high_res:
    rate: 96000
    use: "Specialized audio"
```

### Audio Processing

```yaml
remove_silence:
  parameters:
    video_path:
      type: string
      required: true
      
    output_video_path:
      type: string
      required: true
      
    silence_threshold:
      type: float
      description: "Auto-calculated via analysis"
      
    minimum_silence_duration:
      type: float
      description: "Auto-determined"
```

---

<a id="5-advanced-features"></a>

## 5. 🎨 ADVANCED FEATURES

### Overlays

```yaml
add_text_overlay:
  parameters:
    video_path:
      type: string
      required: true
      
    output_video_path:
      type: string
      required: true
      
    text:
      type: string
      required: true
      
    position:
      type: string
      options: [top-left, top-center, top-right, center-left, center, center-right, bottom-left, bottom-center, bottom-right]
      
    font_size:
      type: integer
      optional: true
      
    font_color:
      type: string
      optional: true
      
    start_time:
      type: string
      optional: true
      
    duration:
      type: string
      optional: true
      
add_image_overlay:
  parameters:
    video_path:
      type: string
      required: true
      
    output_video_path:
      type: string
      required: true
      
    image_path:
      type: string
      required: true
      description: "Watermark or logo"
      
    position:
      type: string
      options: [top-left, top-center, top-right, center-left, center, center-right, bottom-left, bottom-center, bottom-right]
      
    scale:
      type: float
      optional: true
      
    start_time:
      type: string
      optional: true
      
    duration:
      type: string
      optional: true
```

### Transitions and Effects

```yaml
add_transition_effect:
  parameters:
    video1_path:
      type: string
      required: true
      
    video2_path:
      type: string
      required: true
      
    output_video_path:
      type: string
      required: true
      
    transition_type:
      type: string
      options: [fade, dissolve, wipe]
      
    transition_duration:
      type: float
      optional: true
      
fade_in_out:
  parameters:
    video_path:
      type: string
      required: true
      
    output_video_path:
      type: string
      required: true
```

### Subtitles

```yaml
add_subtitle:
  parameters:
    video_path:
      type: string
      required: true
      
    output_video_path:
      type: string
      required: true
      
    subtitle_path:
      type: string
      required: true
      description: "SRT or ASS format"
      
    style:
      type: object
      optional: true
      properties:
        Fontsize: integer
        PrimaryColour: string
        OutlineColour: string
        BorderStyle: integer
        Outline: integer
        Shadow: integer
```

### B-Roll and Composition

```yaml
insert_broll:
  parameters:
    main_video_path:
      type: string
      required: true
      
    broll_video_path:
      type: string
      required: true
      
    output_video_path:
      type: string
      required: true
      
    insert_points:
      type: array
      items: string
      description: "Timestamps for insertion"
      
    broll_duration:
      type: float
      optional: true
```

---

<a id="6-format-support"></a>

## 6. � FORMAT SUPPORT

### Video Formats

```yaml
formats:
  mp4:
    extensions: [".mp4", ".m4v"]
    video_codecs: [H.264, H.265]
    audio_codecs: [AAC, MP3]
    best_for: "Universal compatibility"
    
  mov:
    extensions: [".mov", ".qt"]
    video_codecs: [H.264, ProRes]
    audio_codecs: [AAC, PCM]
    best_for: "Apple ecosystem"
    
  avi:
    extensions: [".avi"]
    video_codecs: ["Various"]
    audio_codecs: ["Various"]
    best_for: "Legacy systems"
    
  mkv:
    extensions: [".mkv"]
    video_codecs: ["Any"]
    audio_codecs: ["Any"]
    best_for: "Maximum flexibility"
    
  webm:
    extensions: [".webm"]
    video_codecs: [VP8, VP9]
    audio_codecs: [Opus, Vorbis]
    best_for: "Web streaming"
```

### Audio Formats

```yaml
formats:
  mp3:
    extension: ".mp3"
    codec: "MPEG-1 Layer 3"
    type: "Lossy"
    use: "Universal playback"
    
  wav:
    extension: ".wav"
    codec: "PCM"
    type: "Lossless"
    use: "Editing/Production"
    
  aac:
    extensions: [".aac", ".m4a"]
    codec: "Advanced Audio Coding"
    type: "Lossy"
    use: "Modern devices"
    
  flac:
    extension: ".flac"
    codec: "Free Lossless Audio Codec"
    type: "Lossless"
    use: "Archival quality"
    
  ogg:
    extension: ".ogg"
    codec: "Vorbis"
    type: "Lossy"
    use: "Open source"
```

---

<a id="7-codec-specifications"></a>

## 7. ⚙️ CODEC SPECIFICATIONS

### Video Codecs

**Note:** Codec selection logic is in MEDIA Framework Section 3 (Decide).

```yaml
video_codecs:
  h264_libx264:
    name: "H.264 (libx264)"
    compatibility: "Universal (best)"
    compression: "Good"
    speed: "Fast"
    use: "Default choice"
    
  h265_libx265:
    name: "H.265 (libx265)"
    compatibility: "Modern devices"
    compression: "Excellent (50% smaller)"
    speed: "Slower"
    use: "Size optimization"
    
  vp9:
    name: "VP9"
    compatibility: "Web browsers"
    compression: "Excellent"
    speed: "Slow"
    use: "Web streaming"
    
  prores:
    name: "ProRes"
    compatibility: "Professional editing"
    compression: "Minimal (high quality)"
    speed: "Very fast"
    use: "Production workflow"
    
  dnxhd:
    name: "DNxHD"
    compatibility: "Broadcast"
    compression: "Minimal"
    speed: "Fast"
    use: "Broadcast quality"
```

### Audio Codecs

```yaml
audio_codecs:
  aac:
    name: "AAC"
    compatibility: "Modern standard"
    quality: "Excellent"
    use: "Default choice"
    
  mp3:
    name: "MP3"
    compatibility: "Universal"
    quality: "Good"
    use: "Maximum compatibility"
    
  pcm:
    name: "PCM"
    compatibility: "Universal"
    quality: "Perfect (uncompressed)"
    use: "Editing/Production"
    
  flac:
    name: "FLAC"
    compatibility: "Good"
    quality: "Perfect (lossless)"
    use: "Archival"
    
  opus:
    name: "Opus"
    compatibility: "Modern"
    quality: "Excellent"
    use: "Streaming efficiency"
```

---

<a id="8-quick-reference"></a>

## 8. 🏎️ QUICK REFERENCE

### MCP Tools Summary

```yaml
tools:
  system:
    health_check: "Server status verification"
    
  video_conversion:
    convert_video_format: "Change container format"
    convert_video_properties: "Full transcode with settings"
    
  video_editing:
    trim_video: "Cut segments"
    concatenate_videos: "Join multiple videos"
    adjust_video_speed: "Speed up/slow down"
    
  video_properties:
    set_video_resolution: "Change dimensions"
    change_aspect_ratio: "Adjust aspect ratio"
    set_video_codec: "Change video codec"
    set_video_bitrate: "Adjust quality/size"
    set_video_frame_rate: "Change FPS"
    
  audio_operations:
    extract_audio_from_video: "Extract audio track"
    convert_audio_format: "Change audio format"
    convert_audio_properties: "Full audio transcode"
    remove_silence: "Auto-remove silent portions"
    
  overlays:
    add_text_overlay: "Add text to video"
    add_image_overlay: "Add watermark/logo"
    
  effects:
    add_transition_effect: "Add transitions between clips"
    fade_in_out: "Add fade effects"
    
  subtitles:
    add_subtitle: "Burn subtitles"
    
  composition:
    insert_broll: "Insert B-roll footage"
```

### Integration References

```yaml
related_documents:
  thinking_methodology:
    file: "Media Editor - MEDIA Thinking Framework"
    sections:
      - "Section 2: MEDIA Principles (codec selection)"
      - "Section 3: Cognitive Rigor (format analysis)"
      - "Section 9: MCP Troubleshooting"
    
  conversation_flow:
    file: "Media Editor - Interactive Intelligence"
    sections:
      - "Section 1: Conversation Architecture"
      - "Section 2: Response Templates"
      - "Section 5: Error Recovery"
    
  error_handling:
    file: "Media Editor - MEDIA Thinking Framework"
    section: "Section 9: MCP Troubleshooting"
    includes:
      - "FFmpeg installation verification"
      - "Codec availability checks"
      - "Performance optimization"
```

### Performance Characteristics

```yaml
performance:
  engine: "FFmpeg"
  characteristics:
    - "Hardware acceleration support"
    - "Streaming for large files"
    - "Multi-threaded processing"
    - "Cross-platform compatibility"
    
  benchmarks:
    small_files:
      size: "< 100MB"
      trim: "1-5s"
      convert: "5-15s"
      compress: "10-30s"
      overlay: "5-20s"
      
    medium_files:
      size: "100MB-1GB"
      trim: "5-20s"
      convert: "30-120s"
      compress: "60-300s"
      overlay: "20-60s"
      
    large_files:
      size: "> 1GB"
      trim: "20-60s"
      convert: "2-10min"
      compress: "5-20min"
      overlay: "1-5min"
```

### Limitations

```yaml
limitations:
  dependencies:
    required:
      - "FFmpeg installed"
      - "Python environment"
      - "Sufficient disk space"
    
  file_size:
    recommended_max: "2GB per operation"
    workaround: "Split large files"
    
  operations:
    can_do:
      - "Format conversion, transcoding"
      - "Trimming, concatenation"
      - "Overlays, subtitles, effects"
      - "Audio extraction and processing"
    
    cannot_do:
      - "AI content generation"
      - "Complex video editing (NLE features)"
      - "Real-time processing"
      - "Direct upload to platforms"
      
  ffmpeg_dependent:
    note: "All capabilities depend on FFmpeg installation"
    check: "Run 'ffmpeg -version' to verify"
```

---

*This document focuses exclusively on Video-Audio MCP server capabilities and technical specifications. For thinking methodology, see MEDIA Framework. For conversation flows and error handling, see Interactive Intelligence.*
