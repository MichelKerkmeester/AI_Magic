# Video-Audio MCP Docker Volume Reference Guide

## Quick Path Reference

When using Video-Audio MCP through Claude Desktop with Docker, use these paths:

### Primary Media Directories (ONLY accessible paths)
- **Original Media (Input)**: `/videos/Original/`
- **Processed Media (Output)**: `/videos/New/`

### How to Use

Place your media files in the designated folders on your computer:
- **Input files**: `<your-path>/video-audio/videos/Original/`
- **Output location**: `<your-path>/video-audio/videos/New/`

Reference them in Claude as:
- **Input**: `/videos/Original/filename.mp4`
- **Output**: `/videos/New/filename.mp4`

## Usage Examples in Claude

### Example 1: Compress a Video
```
You: "First, copy your video to the Original folder"
You: "Compress video.mp4 from the Original folder"
Claude: "I'll compress the video at /videos/Original/video.mp4"
```

### Example 2: Extract Audio
```
You: "Extract audio from the video in Original folder"
Claude: "I'll extract audio from /videos/Original/video.mp4"
Claude: "Audio saved to /videos/New/video_audio.mp3"
```

### Example 3: Convert Format
```
You: "Convert all MOV files in Original to MP4"
Claude: "I'll convert MOV files in /videos/Original/"
Claude: "Converted files saved to /videos/New/"
```

## File Management

### Copy files to the Original folder:
```bash
# Copy a single video
cp ~/Desktop/video.mp4 "<your-path>/video-audio/videos/Original/"

# Copy multiple videos
cp ~/Desktop/*.mp4 "<your-path>/video-audio/videos/Original/"

# Copy audio files
cp ~/Music/*.mp3 "<your-path>/video-audio/videos/Original/"
```

### Check processed files:
```bash
# List files in New folder
ls -la "<your-path>/video-audio/videos/New/"

# Check file size
du -h "<your-path>/video-audio/videos/New/"*.mp4
```

## Container Management

### Start the container:
```bash
cd <your-path>/video-audio
docker-compose up -d
```

### Check container status:
```bash
docker ps | grep mcp-video-audio
```

### View logs:
```bash
docker logs mcp-video-audio
```

### Restart container:
```bash
docker-compose restart
```

### Stop container:
```bash
docker-compose down
```

## Troubleshooting

### File Not Found
- Ensure the file is in the Original folder first
- Check file exists: `docker exec mcp-video-audio ls -la /videos/Original/`

### Permission Issues
- The container has read/write access to the mapped directory
- Check Docker Desktop file sharing settings if issues persist

### Container Not Running
```bash
# Check status
docker ps -a | grep mcp-video-audio

# Start if stopped
docker-compose up -d
```

### FFmpeg Errors
- The container includes FFmpeg for media processing
- Check logs for specific error messages: `docker logs mcp-video-audio`

## Important Notes

1. **Limited Access**: Only `/videos/` directory is accessible
2. **Original folder** (`/videos/Original/`) for input media files
3. **New folder** (`/videos/New/`) for processed output
4. **Copy files first**: Always copy files to Original folder before processing
5. **No direct access**: Cannot access Desktop, Downloads, or other directories directly
6. **Supports**: Video files (MP4, MOV, AVI, etc.) and audio files (MP3, WAV, etc.)

## Quick Tips

- Copy your media files to the Original folder before processing
- Check the New folder for processed outputs
- Claude Desktop must be restarted after config changes
- Container auto-restarts unless explicitly stopped
- FFmpeg is pre-installed in the container for all media operations

## Supported Operations

The Video-Audio MCP supports:
- Video compression and optimization
- Audio extraction from video
- Format conversion (MP4, MOV, AVI, WebM, etc.)
- Video trimming and cutting
- Audio processing and enhancement
- Batch processing of multiple files
- Platform-specific optimization (YouTube, Instagram, TikTok, etc.)