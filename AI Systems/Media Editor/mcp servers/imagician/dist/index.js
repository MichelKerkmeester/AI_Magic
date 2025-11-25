#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { ListToolsRequestSchema, CallToolRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import sharp from 'sharp';
import fs from 'fs/promises';
import path from 'path';

const IMAGE_PATH = process.env.IMAGE_PATH || '/images';

const server = new Server(
  {
    name: 'imagician-mcp',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {}
    }
  }
);

// Handle tool listing
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'resize_image',
        description: 'Resize an image',
        inputSchema: {
          type: 'object',
          properties: {
            input: { type: 'string', description: 'Input image path relative to /images' },
            output: { type: 'string', description: 'Output image path relative to /images' },
            width: { type: 'number', description: 'Target width in pixels' },
            height: { type: 'number', description: 'Target height in pixels' }
          },
          required: ['input', 'output']
        }
      },
      {
        name: 'convert_format',
        description: 'Convert image format',
        inputSchema: {
          type: 'object',
          properties: {
            input: { type: 'string', description: 'Input image path relative to /images' },
            output: { type: 'string', description: 'Output image path relative to /images' },
            format: { 
              type: 'string', 
              enum: ['jpeg', 'png', 'webp', 'avif'],
              description: 'Target image format'
            }
          },
          required: ['input', 'output', 'format']
        }
      },
      {
        name: 'list_images',
        description: 'List all images in the Original and New folders',
        inputSchema: {
          type: 'object',
          properties: {
            folder: { 
              type: 'string',
              enum: ['Original', 'New', 'all'],
              description: 'Which folder to list (Original, New, or all)'
            }
          }
        }
      }
    ]
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  
  try {
    if (name === 'resize_image') {
      const inputPath = path.join(IMAGE_PATH, args.input);
      const outputPath = path.join(IMAGE_PATH, args.output);
      
      // Ensure output directory exists
      await fs.mkdir(path.dirname(outputPath), { recursive: true });
      
      await sharp(inputPath)
        .resize(args.width, args.height, {
          fit: 'inside',
          withoutEnlargement: true
        })
        .toFile(outputPath);
      
      return {
        content: [{
          type: 'text',
          text: `✅ Image resized successfully!\nInput: ${args.input}\nOutput: ${args.output}\nDimensions: ${args.width || 'auto'} x ${args.height || 'auto'}`
        }]
      };
    }
    
    if (name === 'convert_format') {
      const inputPath = path.join(IMAGE_PATH, args.input);
      const outputPath = path.join(IMAGE_PATH, args.output);
      
      // Ensure output directory exists
      await fs.mkdir(path.dirname(outputPath), { recursive: true });
      
      await sharp(inputPath)
        .toFormat(args.format)
        .toFile(outputPath);
      
      return {
        content: [{
          type: 'text',
          text: `✅ Image converted successfully!\nInput: ${args.input}\nOutput: ${args.output}\nFormat: ${args.format}`
        }]
      };
    }
    
    if (name === 'list_images') {
      const folder = args.folder || 'all';
      let files = [];
      
      if (folder === 'Original' || folder === 'all') {
        try {
          const originalFiles = await fs.readdir(path.join(IMAGE_PATH, 'Original'));
          files.push(...originalFiles.map(f => `Original/${f}`));
        } catch (e) {
          // Directory might not exist
        }
      }
      
      if (folder === 'New' || folder === 'all') {
        try {
          const newFiles = await fs.readdir(path.join(IMAGE_PATH, 'New'));
          files.push(...newFiles.map(f => `New/${f}`));
        } catch (e) {
          // Directory might not exist
        }
      }
      
      return {
        content: [{
          type: 'text',
          text: files.length > 0 
            ? `📁 Found ${files.length} images:\n${files.join('\n')}`
            : '📁 No images found in the specified folder(s)'
        }]
      };
    }
    
    throw new Error(`Unknown tool: ${name}`);
  } catch (error) {
    return {
      content: [{
        type: 'text',
        text: `❌ Error: ${error.message}`
      }]
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('Imagician MCP server running on stdio');
}

main().catch(console.error);