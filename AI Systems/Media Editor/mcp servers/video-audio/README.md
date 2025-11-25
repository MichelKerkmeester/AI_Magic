# Video-Audio MCP Server Docker Setup

This is a Dockerized version of the [video-audio-mcp](https://github.com/misbahsy/video-audio-mcp) server for Claude Desktop.

## Features

A comprehensive video and audio editing MCP server powered by FFmpeg, enabling:
- Video processing (format conversion, scaling, codec changes)
- Audio processing (format/bitrate conversion)
- Editing tools (trimming, overlays, transitions)
- Advanced editing (concatenation, B-roll insertion)

## Docker Setup

### Build the Image
```bash
docker build -t mcp-video-audio:latest .
```

### Run the Container
The container is managed via docker-compose in the parent directory's setup folder.

## Usage in Claude Desktop

The server is configured to run via Docker exec commands in Claude Desktop's config.

## Environment Variables

- `PYTHONUNBUFFERED=1` - Ensures Python output is sent straight to terminal
- `NODE_ENV=production` - Production environment setting

## Volume Mounts

You can mount local directories for video/audio file access:
```yaml
volumes:
  - /path/to/videos:/videos
  - /path/to/audio:/audio
```