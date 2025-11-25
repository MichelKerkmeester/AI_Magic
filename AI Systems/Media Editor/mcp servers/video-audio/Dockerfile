FROM python:3.11-slim

# Install FFmpeg and system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone the repository
RUN git clone https://github.com/misbahsy/video-audio-mcp.git .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt || \
    pip install --no-cache-dir \
        mcp \
        python-dotenv \
        ffmpeg-python \
        pillow \
        numpy

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV NODE_ENV=production

# Keep container running and ready for docker exec
CMD ["sh", "-c", "echo 'Video-Audio MCP Server started' && echo 'Container is ready to accept connections via docker exec' && tail -f /dev/null"]