# Imagician MCP Docker Volume Reference Guide

## Quick Path Reference

When using Imagician MCP through Claude Desktop with Docker, use these paths:

### Primary Image Directories (ONLY accessible paths)
- **Original Images (Input)**: `/images/Original/`
- **New Images (AI Output)**: `/images/New/`

### How to Use

Place your images in the designated folders on your computer:
- **Input files**: `<your-path>/imagician/images/Original/`
- **Output location**: `<your-path>/imagician/images/New/`

Reference them in Claude as:
- **Input**: `/images/Original/filename.jpg`
- **Output**: `/images/New/filename.jpg`

## Usage Examples in Claude

### Example 1: Process an Image
```
You: "First, copy your image to the Original folder"
You: "Optimize sunset.jpg from the Original folder"
Claude: "I'll optimize the image at /images/Original/sunset.jpg"
```

### Example 2: Batch Process Images
```
You: "Convert all PNGs in the Original folder to WebP"
Claude: "I'll process images in /images/Original/"
```

### Example 3: Check Output
```
You: "Where is my processed image?"
Claude: "Your processed image is saved to /images/New/"
```

## File Management

### Copy files to the Original folder:
```bash
# Copy a file from Desktop
cp ~/Desktop/photo.jpg "<your-path>/imagician/images/Original/"

# Copy multiple files
cp ~/Desktop/*.jpg "<your-path>/imagician/images/Original/"
```

### Check processed files:
```bash
# List files in New folder
ls -la "<your-path>/imagician/images/New/"
```

## Container Management

### Start the container:
```bash
cd <your-path>/imagician
docker-compose up -d
```

### Check container status:
```bash
docker ps | grep mcp-imagician
```

### View logs:
```bash
docker logs mcp-imagician
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
- Check file exists: `docker exec mcp-imagician ls -la /images/Original/`

### Permission Issues
- The container has read/write access to all mapped directories
- If issues persist, check Docker Desktop file sharing settings

### Container Not Running
```bash
# Check status
docker ps -a | grep mcp-imagician

# Start if stopped
docker-compose up -d
```

## Important Notes

1. **Limited Access**: Only `/images/` directory is accessible
2. **Original folder** (`/images/Original/`) for input files
3. **New folder** (`/images/New/`) for AI-generated output
4. **Copy files first**: Always copy files to Original folder before processing
5. **No direct access**: Cannot access Desktop, Downloads, or other directories directly

## Quick Tips

- Copy your files to the Original folder before processing
- Check the New folder for processed outputs
- Claude Desktop must be restarted after config changes
- Container auto-restarts unless explicitly stopped