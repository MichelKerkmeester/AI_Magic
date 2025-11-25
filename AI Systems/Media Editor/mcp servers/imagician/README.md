# MCP Imagician Server

## Overview

A Model Context Protocol (MCP) server that provides comprehensive image processing and manipulation capabilities. This server enables AI models to resize, convert, crop, compress, rotate, and transform images through a standardized interface.

## Features

- **Image Resizing**: Scale images to specific dimensions
- **Format Conversion**: Convert between JPEG, PNG, WebP, AVIF formats
- **Image Cropping**: Extract specific regions from images
- **Compression**: Optimize file sizes with quality control
- **Rotation & Flipping**: Rotate and flip images
- **Batch Processing**: Generate multiple sizes from one source
- **Metadata Extraction**: Get image information and properties

## Prerequisites

- Images directory for processing
- Docker with volume mounting for image access

## Docker Setup

### Build the Image

```bash
cd mcp-imagician
docker build -t mcp-imagician:latest .
```

### Run via Docker Compose

The server is configured to run as part of the main docker-compose setup:

```bash
# From the parent directory
docker-compose up -d mcp-imagician
```

### Container Management

```bash
# View logs
docker logs mcp-imagician

# Restart container
docker restart mcp-imagician

# Stop container
docker stop mcp-imagician
```

## MCP Configuration

Add to your Claude Desktop configuration (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "imagician": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-imagician", "node", "dist/index.js"],
      "env": {
        "IMAGE_PATH": "/images",
        "NODE_ENV": "production"
      }
    }
  }
}
```

## Volume Mounting

The server requires access to an images directory. This is configured in docker-compose.yml:

```yaml
volumes:
  - ./images:/images
```

Place images in the `images/` directory in the parent folder for processing.

## Available Tools

### Image Transformation
- `resize_image` - Resize to specified dimensions
- `crop_image` - Crop to specific region
- `rotate_image` - Rotate by degrees
- `flip_image` - Flip horizontally/vertically

### Format & Quality
- `convert_format` - Convert between image formats
- `compress_image` - Compress with quality settings
- `optimize_image` - Auto-optimize for web

### Batch Operations
- `batch_resize` - Generate multiple sizes
- `batch_convert` - Convert multiple images
- `create_thumbnails` - Generate thumbnail set

### Information
- `get_image_info` - Get metadata and dimensions
- `analyze_image` - Detailed image analysis
- `compare_images` - Compare two images

## Usage Examples

### Resize an Image
```
"Resize photo.jpg to 800x600 pixels maintaining aspect ratio"
```

### Convert Format
```
"Convert all PNG images to WebP format with 85% quality"
```

### Create Thumbnails
```
"Generate small (150px), medium (300px), and large (600px) thumbnails from header.jpg"
```

### Optimize for Web
```
"Compress and optimize all images in the gallery folder for web use"
```

## Supported Formats

### Input Formats
- JPEG/JPG
- PNG
- WebP
- AVIF
- GIF
- BMP
- TIFF

### Output Formats
- JPEG (with quality control)
- PNG (lossless)
- WebP (modern format)
- AVIF (next-gen format)

## Architecture

```
mcp-imagician/
├── Dockerfile          # Container definition
├── dist/
│   └── index.js       # Compiled server code
└── README.md          # This file
```

The parent directory includes:
```
images/                 # Mounted volume for image storage
├── input/             # Source images
├── output/            # Processed images
└── temp/              # Temporary processing
```

## Image Processing Options

### Resize Options
- **fit**: cover, contain, fill, inside, outside
- **preserveAspectRatio**: maintain original proportions
- **upscale**: allow enlarging images

### Compression Settings
- **quality**: 1-100 (JPEG/WebP)
- **progressive**: progressive encoding
- **lossless**: PNG optimization

### Advanced Features
- **Smart cropping**: Focus on important areas
- **Background removal**: Transparent backgrounds
- **Watermarking**: Add watermarks to images

## Troubleshooting

### Image Access Issues

1. Verify volume mounting:
   ```bash
   docker inspect mcp-imagician | grep Mounts
   ```
2. Check file permissions in images directory
3. Ensure images are in correct format

### Container Won't Start

```bash
# Check logs
docker logs mcp-imagician

# Rebuild image
docker build -t mcp-imagician:latest .

# Remove and recreate
docker-compose rm -f mcp-imagician
docker-compose up -d mcp-imagician
```

### Processing Errors

- Check image format compatibility
- Verify sufficient disk space
- Monitor memory usage for large images
- Check ImageMagick policies if using advanced features

## Performance Optimization

- **Caching**: Processed images are cached
- **Parallel Processing**: Multiple operations run concurrently
- **Memory Management**: Automatic cleanup of temporary files
- **Stream Processing**: Large images processed in chunks

## Security Notes

- Validate image uploads for malicious content
- Limit maximum file sizes
- Sanitize file names
- Use temporary directories for processing
- Regular cleanup of processed files

## Dependencies

- **sharp**: High-performance Node.js image processing
- **ImageMagick**: Advanced image manipulation
- **@modelcontextprotocol/sdk**: MCP protocol implementation

## GitHub Repository

[flowy11/imagician](https://github.com/flowy11/imagician)

## Related Resources

- [Sharp Documentation](https://sharp.pixelplumbing.com/)
- [ImageMagick Documentation](https://imagemagick.org/)
- [MCP Protocol Documentation](https://modelcontextprotocol.io)

## Support

For image processing issues, consult the [Imagician GitHub repository](https://github.com/flowy11/imagician) or the Sharp documentation for specific operations.