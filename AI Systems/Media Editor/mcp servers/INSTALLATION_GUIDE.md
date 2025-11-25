# Media Editor MCP Installation Guide

> **Quick Setup Guide for Imagician and Video-Audio MCP Servers with Docker Desktop and Claude Desktop**

## 📋 Prerequisites

Before starting, ensure you have:

- ✅ **Docker Desktop** installed and running ([Download here](https://www.docker.com/products/docker-desktop))
- ✅ **Claude Desktop** installed ([Download here](https://claude.ai/download))
- ✅ **Media Editor**, **imagician**, and **video-audio** folders downloaded

---

## 📁 Folder Structure Overview

After downloading, you should have these folders:

```
MCP Servers/
├── Media Editor/          # Your media workspace
│   ├── export/
│   │   ├── images/       # Image working directory
│   │   │   ├── Original/ # Place input images here
│   │   │   └── New/      # Processed images appear here
│   │   └── videos/       # Video working directory
│   │       ├── Original/ # Place input videos here
│   │       └── New/      # Processed videos appear here
│   ├── knowledge base/   # Documentation
│   └── AGENTS.md         # System instructions
├── imagician/            # Image processing MCP server
│   ├── docker-compose.yml
│   ├── Dockerfile
│   └── package.json
└── video-audio/          # Video/audio processing MCP server
    ├── docker-compose.yml
    ├── Dockerfile
    └── README.md
```

---

## 🚀 Installation Steps

### Step 1: Update Docker Compose Files

Both MCP servers need to know where your media files are located. You need to update the volume paths in the docker-compose files.

#### 1.1 Update Imagician Docker Compose

Open `/imagician/docker-compose.yml` and update the volume path:

**Find this line:**
```yaml
- /path/to/your/Media Editor/export/images:/images:rw
```

**Replace with YOUR actual path:**
```yaml
- /YOUR/FULL/PATH/TO/MCP Servers/Media Editor/export/images:/images:rw
```

**Example (if your folders are in Documents):**
```yaml
- /Users/yourusername/Documents/MCP Servers/Media Editor/export/images:/images:rw
```

#### 1.2 Update Video-Audio Docker Compose

Open `/video-audio/docker-compose.yml` and update the volume path:

**Find this line:**
```yaml
- /path/to/your/Media Editor/export/videos:/videos:rw
```

**Replace with YOUR actual path:**
```yaml
- /YOUR/FULL/PATH/TO/MCP Servers/Media Editor/export/videos:/videos:rw
```

**Example:**
```yaml
- /Users/yourusername/Documents/MCP Servers/Media Editor/export/videos:/videos:rw
```

> 💡 **Tip:** To get your full path in Terminal, drag the `Media Editor` folder into Terminal and it will auto-fill the path. Then add `/export/images` or `/export/videos` to the end.

---

### Step 2: Build and Start Docker Containers

#### 2.1 Start Imagician Server

Open Terminal and navigate to the imagician folder:

```bash
cd /YOUR/PATH/TO/MCP\ Servers/imagician
```

Build and start the container:

```bash
docker-compose up -d --build
```

Verify it's running:

```bash
docker ps | grep imagician
```

You should see output like:
```
imagician    imagician:latest    "node dist/index.js"    Up X minutes    ...
```

#### 2.2 Start Video-Audio Server

Navigate to the video-audio folder:

```bash
cd /YOUR/PATH/TO/MCP\ Servers/video-audio
```

Build and start the container:

```bash
docker-compose up -d --build
```

Verify it's running:

```bash
docker ps | grep video-audio
```

You should see output like:
```
video-audio    video-audio:latest    "sh -c 'echo..."    Up X minutes    ...
```

---

### Step 3: Configure Claude Desktop

Now we need to tell Claude Desktop how to connect to these MCP servers.

#### 3.1 Open Claude Desktop Config File

Open the Claude Desktop configuration file:

```bash
open ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

If the file doesn't exist, create it with:

```bash
mkdir -p ~/Library/Application\ Support/Claude/
touch ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

#### 3.2 Add MCP Server Configuration

**If the file is empty**, add this entire configuration:

```json
{
  "mcpServers": {
    "imagician": {
      "command": "docker",
      "args": ["exec", "-i", "imagician", "node", "dist/index.js"],
      "env": {
        "IMAGE_PATH": "/images",
        "NODE_ENV": "production"
      }
    },
    "video-audio": {
      "command": "docker",
      "args": ["exec", "-i", "video-audio", "python", "-m", "video_audio_mcp"],
      "env": {
        "PYTHONUNBUFFERED": "1",
        "VIDEO_PATH": "/videos",
        "NODE_ENV": "production"
      }
    }
  }
}
```

**If you already have mcpServers configured**, add the imagician and video-audio sections to your existing configuration.

#### 3.3 Save and Restart Claude Desktop

1. Save the file
2. **Completely quit** Claude Desktop (⌘Q)
3. Reopen Claude Desktop

---

## ✅ Verification

### Test Your Setup

Once Claude Desktop restarts, you should see the MCP servers connected in the bottom-left corner or settings.

#### Test Imagician (Image Processing)

In Claude Desktop, try:

```
Can you list the images in /images/Original/?
```

Or test with a sample operation:

```
$repair
```

This will run connection verification.

#### Test Video-Audio (Video Processing)

```
Can you check the video-audio MCP server status?
```

Or:

```
List videos in /videos/Original/
```

---

## 🎯 Usage Guide

### Working with Images

1. **Place input images** in:
   ```
   Media Editor/export/images/Original/
   ```

2. **Reference them in Claude** as:
   ```
   /images/Original/filename.jpg
   ```

3. **Processed images** will be saved to:
   ```
   Media Editor/export/images/New/
   ```
   
4. **In Claude, reference output** as:
   ```
   /images/New/filename.jpg
   ```

### Working with Videos

1. **Place input videos** in:
   ```
   Media Editor/export/videos/Original/
   ```

2. **Reference them in Claude** as:
   ```
   /videos/Original/filename.mp4
   ```

3. **Processed videos** will be saved to:
   ```
   Media Editor/export/videos/New/
   ```

4. **In Claude, reference output** as:
   ```
   /videos/New/filename.mp4
   ```

### Quick Commands in Claude

The Media Editor system has special command shortcuts:

- `$image` or `$img` - Image operations mode
- `$video` or `$vid` - Video operations mode  
- `$audio` or `$aud` - Audio operations mode
- `$hls` - HLS video conversion
- `$repair` or `$r` - Connection troubleshooting
- `$interactive` or `$int` - Full conversational flow

---

## 🔧 Troubleshooting

### Docker Containers Not Running

Check if Docker Desktop is running:
```bash
docker ps
```

Restart a container:
```bash
docker restart imagician
docker restart video-audio
```

View container logs:
```bash
docker logs imagician
docker logs video-audio
```

### Claude Desktop Not Connecting

1. Verify Docker containers are running:
   ```bash
   docker ps
   ```

2. Check Claude Desktop config file exists:
   ```bash
   cat ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```

3. Ensure JSON is valid (no trailing commas, proper brackets)

4. Completely quit and restart Claude Desktop (⌘Q)

### Permission Issues

If you get permission errors, ensure the volume paths are readable:

```bash
# Check permissions
ls -la /YOUR/PATH/TO/Media\ Editor/export/

# If needed, grant permissions
chmod -R 755 /YOUR/PATH/TO/Media\ Editor/export/
```

### Containers Keep Stopping

Restart with logs to see errors:
```bash
docker-compose down
docker-compose up --build
```

---

## 🔄 Starting/Stopping Services

### Start All Services
```bash
# In imagician folder
docker-compose up -d

# In video-audio folder
docker-compose up -d
```

### Stop All Services
```bash
# In imagician folder
docker-compose down

# In video-audio folder
docker-compose down
```

### Restart After Changes
```bash
# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

---

## 📚 Additional Resources

- **Media Editor Documentation**: See `Media Editor/knowledge base/` folder
- **Command Reference**: See `Media Editor/AGENTS.md`
- **Volume Paths**: See `VOLUME_REFERENCE.md` in each MCP folder
- **Imagician GitHub**: https://github.com/flowy11/imagician
- **Video-Audio MCP GitHub**: https://github.com/misbahsy/video-audio-mcp

---

## 🎉 Ready to Go!

You're all set! Your Media Editor system with Imagician and Video-Audio MCP servers is now configured and ready to use with Claude Desktop.

**Quick Start:**
1. Place a test image in `Media Editor/export/images/Original/`
2. Open Claude Desktop
3. Ask: `$repair` to verify connections
4. Ask: `Resize the image in /images/Original/ to 800x600`

Enjoy your powerful media editing capabilities! 🚀