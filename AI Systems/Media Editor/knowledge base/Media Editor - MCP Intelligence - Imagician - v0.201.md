# Media Editor - MCP Intelligence - Imagician

Technical reference for Imagician MCP server capabilities and integration for image processing operations.

**Purpose:** Document Imagician-specific features, supported operations, and technical specifications. Conversation flows and thinking methodology are in Interactive Intelligence and MEDIA Framework respectively.

---

## 📋 TABLE OF CONTENTS

1. [🔌 SERVER OVERVIEW](#1-server-overview)
2. [🛠️ CORE CAPABILITIES](#2-core-capabilities)
3. [📊 FORMAT SUPPORT](#3-format-support)
4. [⚙️ OPERATION SPECIFICATIONS](#4-operation-specifications)
5. [🎯 QUALITY OPTIMIZATION](#5-quality-optimization)
6. [� RESIZE & CROP](#6-resize--crop)
7. [🔄 TRANSFORMS](#7-transforms)
8. [🏎️ QUICK REFERENCE](#8-quick-reference)

---

<a id="1-server-overview"></a>

## 1. 🔌 SERVER OVERVIEW

### MCP Server Details

The Imagician MCP server (`@flowy11/imagician`) provides high-performance image processing capabilities powered by Sharp, a Node.js image processing library. It enables format conversion, resizing, cropping, compression, and various transformations through native MCP integration.

**Key Information:**
- **Package:** `@flowy11/imagician`
- **Repository:** https://github.com/flowy11/imagician
- **Engine:** Sharp (Node.js image processing)
- **Protocol:** Model Context Protocol (MCP)

**Installation:**
```bash
# Quick start (no installation)
npx -y @flowy11/imagician

# Global installation
npm install -g @flowy11/imagician
```

### Connection Verification

**Reference:** Connection verification logic is in Interactive Intelligence.

Connection verification must be the **first action before all operations**. Use the `list_images` tool to test connectivity and server availability.

**Status Messages:**
- ✅ **Connected:** "Imagician Connected - Image processing available"
- ❌ **Disconnected:** "Imagician Not Connected - Setup required"

---

<a id="2-core-capabilities"></a>

## 2. 🛠️ CORE CAPABILITIES

### Available Operations

**Note:** Thinking methodology (10 rounds standard, 1-5 quick) is defined in MEDIA Thinking Framework.

The Imagician MCP server provides comprehensive image processing capabilities:

**Resize** - Change image dimensions with multiple fit modes
- Parameters: width, height, fit mode, aspect ratio preservation
- Use case: Responsive images, thumbnails, web optimization

**Convert** - Change image format with quality control
- Parameters: target format (JPEG, PNG, WebP, AVIF), quality level
- Use case: Format optimization, browser compatibility

**Crop** - Extract specific regions from images
- Parameters: x, y coordinates, width, height
- Use case: Focus on subjects, remove unwanted areas

**Compress** - Optimize file size while maintaining quality
- Parameters: quality level, strip metadata, optimize flag
- Use case: Web performance, bandwidth reduction

**Rotate** - Rotate images by specific angles
- Parameters: angle in degrees, background color
- Use case: Orientation correction, creative effects

**Flip** - Flip images horizontally or vertically
- Parameters: direction (horizontal/vertical)
- Use case: Mirror effects, corrections

**Get Metadata** - Extract image information
- Tool: `getMetadata`
- Returns: Dimensions, format, color space, orientation
- Use case: Image analysis, validation

**Batch Processing** - Process multiple images at once
- Parameters: Array of operations
- Use case: Bulk optimization, consistent transformations

**List Images** - List images in a folder
- Tool: `list_images`
- Parameters: Folder path
- Use case: Directory scanning, file discovery

### Processing Order

For optimal results, process images in this sequence:
1. Verify connection
2. Crop if needed (remove unwanted areas first)
3. Resize if needed (adjust dimensions)
4. Rotate/flip if needed (orientation corrections)
5. Convert format (change file type)
6. Optimize quality (final compression)

---

<a id="3-format-support"></a>

## 3. 📊 FORMAT SUPPORT

### Supported Formats

Imagician supports modern image formats with full input/output capabilities.

**JPEG (.jpg, .jpeg)**
- Input: ✅ | Output: ✅
- Transparency: ❌
- Best for: Photos, complex images with many colors
- Use case: Photography, realistic imagery

**PNG (.png)**
- Input: ✅ | Output: ✅
- Transparency: ✅
- Best for: Graphics, screenshots, images requiring transparency
- Use case: Logos, UI elements, graphics with text

**WebP (.webp)**
- Input: ✅ | Output: ✅
- Transparency: ✅
- Best for: Modern web applications, balanced compression
- Use case: Web optimization with better compression than JPEG/PNG

**AVIF (.avif)**
- Input: ✅ | Output: ✅
- Transparency: ✅
- Best for: Next-generation compression, cutting-edge applications
- Use case: Modern browsers, maximum compression efficiency

**Note:** Format selection logic and recommendations are in MEDIA Thinking Framework Section 2 (Evaluate).

---

<a id="4-operation-specifications"></a>

## 4. ⚙️ OPERATION SPECIFICATIONS

### Resize Operation

Change image dimensions with multiple fit modes and aspect ratio control.

```yaml
resize:
  parameters:
    inputPath: string (required) - Path to input image
    outputPath: string (required) - Path to save resized image
    width: number (optional) - Target width in pixels
    height: number (optional) - Target height in pixels
    fit: string (optional, default: "inside")
      options: [cover, contain, fill, inside, outside]
    preserveAspectRatio: boolean (default: true)
```

**Fit Modes Explained:**
- **cover** - Crop to cover both dimensions exactly
- **contain** - Fit within dimensions with padding if needed
- **fill** - Stretch to exact dimensions (may distort)
- **inside** - Resize to fit inside bounds (most common)
- **outside** - Resize to fit outside bounds

### Convert Operation

Change image format with quality control.

```yaml
convert:
  parameters:
    inputPath: string (required)
    outputPath: string (required)
    format: string (required) - Options: jpeg, png, webp, avif
    quality: number (optional, default: 85) - Range: 1-100
```

### Crop Operation

Extract a specific region from an image.

```yaml
crop:
  parameters:
    inputPath: string (required)
    outputPath: string (required)
    x: number (required) - X coordinate from left edge
    y: number (required) - Y coordinate from top edge
    width: number (required) - Crop width in pixels
    height: number (required) - Crop height in pixels
```

### Compress Operation

Optimize file size while maintaining acceptable quality.

```yaml
compress:
  parameters:
    inputPath: string (required)
    outputPath: string (required)
    quality: number (optional, default: 80) - Range: 1-100
    strip: boolean (optional, default: false) - Remove metadata
    optimize: boolean (optional, default: true) - Apply additional optimization
```

---

<a id="5-quality-optimization"></a>

## 5. 🎯 QUALITY OPTIMIZATION

### Quality Guidelines

**Note:** Quality vs size optimization logic is in MEDIA Framework Section 2 (Evaluate).

Quality settings determine the balance between file size and visual fidelity. Higher quality means larger files but better visual appearance.

**Quality Presets:**

| Preset | Quality Range | Use Case | File Size | Visual Quality |
|--------|---------------|----------|-----------|----------------|
| Archive | 100 | Lossless preservation | Largest | Perfect |
| High Quality | 90-95 | Prints, professional work | Large | Excellent |
| Standard Web | 80-89 | Web display (default) | Moderate | Very good |
| Good Compression | 70-79 | Size priority, acceptable quality | Smaller | Good |
| Heavy Compression | 60-69 | Extreme size limits | Small | Acceptable |

### Format-Specific Quality

**For Photos:**
- JPEG: 80-85% (good balance)
- WebP: 85% (better compression than JPEG)
- AVIF: 75-80% (excellent compression)

**For Graphics:**
- PNG: 100% (lossless for graphics with text)
- WebP: 90-95% (high quality with transparency)

**For Web Optimization:**
- Primary: WebP at 85%
- Fallback: JPEG at 80%
- Modern: AVIF at 75%

---

<a id="6-resize--crop"></a>

## 6. 📐 RESIZE & CROP

### Resize Strategies

Choose the appropriate resize strategy based on your requirements:

**Proportional Resizing**
- Maintains aspect ratio
- Use for: Most cases where proportions matter
- Method: Set width or height, let other dimension adjust

**Fixed Width**
- Set width, auto-calculate height
- Use for: Responsive design, gallery columns
- Aspect ratio: Preserved

**Fixed Height**
- Set height, auto-calculate width
- Use for: Gallery rows, consistent heights
- Aspect ratio: Preserved

**Exact Dimensions**
- Force specific width and height
- Use for: Thumbnails, strict size requirements
- Warning: May distort if aspect ratio differs

**Max Dimensions**
- Fit within maximum bounds
- Use for: Container limits, responsive images
- Aspect ratio: Always preserved

### Common Resize Scenarios

**Thumbnail Generation:**
```yaml
width: 150
height: 150
fit: cover  # Crops to fill square
```

**Web Optimization:**
```yaml
width: 1920
fit: inside  # Scales down if larger
preserveAspectRatio: true
```

**Mobile Optimization:**
```yaml
width: 800
fit: inside
preserveAspectRatio: true
```

**Social Media:**
```yaml
# Instagram square
width: 1080
height: 1080
fit: cover

# Instagram story
width: 1080
height: 1920
fit: cover
```
  width: 640
  fit: "inside"
  
social_media:
  instagram_feed: {width: 1080, height: 1080, fit: "cover"}
  instagram_story: {width: 1080, height: 1920, fit: "cover"}
  twitter_card: {width: 1200, height: 628, fit: "cover"}
```

---

<a id="7-transforms"></a>

## 7. 🔄 TRANSFORMS

### Rotation Operation

```yaml
rotate:
  parameters:
    inputPath:
      type: string
      required: true
      
    outputPath:
      type: string
      required: true
      
    angle:
      type: number
      required: true
      common_values: [90, 180, 270, -90, -180, -270]
      
    background:
      type: string
      optional: true
      description: "Background color for exposed areas"
```

### Flip Operation

```yaml
flip:
  parameters:
    inputPath:
      type: string
      required: true
      
    outputPath:
      type: string
      required: true
      
    direction:
      type: string
      required: true
      options: [horizontal, vertical]
```

### Orientation Auto-Correction

```yaml
auto_orientation:
  feature: "Automatic EXIF orientation correction"
  actions:
    - "Read EXIF orientation flag"
    - "Apply necessary rotation"
    - "Update or remove EXIF data"
```

---

<a id="8-quick-reference"></a>

## 8. 🏎️ QUICK REFERENCE

### MCP Tools Summary

```yaml
tools:
  list_images:
    purpose: "Connection check, list files"
    parameters: [folder]
    
  resize:
    purpose: "Change dimensions"
    key_params: [width, height, fit]
    
  convert:
    purpose: "Change format"
    key_params: [format, quality]
    
  crop:
    purpose: "Extract region"
    key_params: [x, y, width, height]
    
  compress:
    purpose: "Reduce file size"
    key_params: [quality, strip, optimize]
    
  rotate:
    purpose: "Rotate image"
    key_params: [angle, background]
    
  flip:
    purpose: "Mirror image"
    key_params: [direction]
    
  getMetadata:
    purpose: "Get image info"
    parameters: []
    
  batch:
    purpose: "Process multiple"
    parameters: [operations_array]
```

### Integration References

```yaml
related_documents:
  thinking_methodology:
    file: "Media Editor - MEDIA Thinking Framework"
    sections:
      - "Section 2: MEDIA Principles (quality vs size)"
      - "Section 3: Cognitive Rigor (format selection)"
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
      - "Docker volume configuration"
      - "Path translation"
      - "Permission diagnostics"
```

### Performance Characteristics

```yaml
performance:
  engine: "Sharp (libvips)"
  characteristics:
    - "Multi-threaded operations"
    - "Memory-efficient streaming"
    - "Hardware acceleration when available"
    
  benchmarks:
    small_files:
      size: "< 1MB"
      resize: "< 100ms"
      convert: "< 150ms"
      compress: "< 200ms"
      crop: "< 50ms"
      
    medium_files:
      size: "1-5MB"
      resize: "100-300ms"
      convert: "150-400ms"
      compress: "200-500ms"
      crop: "50-150ms"
      
    large_files:
      size: "> 5MB"
      resize: "300-1000ms"
      convert: "400-1500ms"
      compress: "500-2000ms"
      crop: "150-500ms"
```

### Limitations

```yaml
limitations:
  formats:
    supported: [JPEG, PNG, WebP, AVIF]
    not_supported: [GIF, TIFF, BMP, SVG]
    
  operations:
    can_do:
      - "Resize, convert, crop, compress"
      - "Rotate, flip, metadata"
      - "Batch processing"
    cannot_do:
      - "AI generation"
      - "Complex filters"
      - "Image composition"
      - "Text rendering"
      
  size_constraints:
    recommended_max: "50MB per image"
    memory_dependent: true
    batch_processing: "Preferred for large sets"
```

---

*This document focuses exclusively on Imagician MCP server capabilities and technical specifications. For thinking methodology, see MEDIA Framework. For conversation flows and error handling, see Interactive Intelligence.*