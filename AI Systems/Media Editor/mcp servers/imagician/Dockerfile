FROM node:20-slim

WORKDIR /app

# Install dependencies for image processing
RUN apt-get update && apt-get install -y \
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

# Copy package.json and install dependencies
COPY package.json .
RUN npm install

# Copy the server code
COPY dist/index.js /app/dist/

# Create images directory
RUN mkdir -p /images/Original /images/New

CMD ["node", "dist/index.js"]
