# Performance Optimization Patterns - Phase 1 Integration

Performance optimization checklist for frontend development (Motion.dev, HLS video, Webflow).

---

## 1. 🎯 WHEN TO USE

Apply during Phase 1 (Implementation) when:
- Writing animation code (Motion.dev or CSS animations)
- Implementing video players (HLS.js)
- Adding interactive features
- Optimizing page load time
- Before deploying to production

---

## 2. ⚙️ PERFORMANCE CHECKLIST

### Code Splitting & Lazy Loading

**JavaScript:**
```javascript
// ✅ GOOD: Lazy load heavy libraries
async function loadVideoPlayer() {
  const Hls = await import('https://cdn.jsdelivr.net/npm/hls.js@latest/dist/hls.min.js');
  // Initialize player
}

// ❌ BAD: Load everything upfront
<script src="https://cdn.jsdelivr.net/npm/hls.js@latest/dist/hls.min.js"></script>
```

**Checklist:**
- [ ] Non-critical JavaScript loaded via dynamic import
- [ ] Vendor bundles separated from application code
- [ ] Route-based code splitting implemented where applicable

### Asset Optimization

**Images:**
```html
<!-- ✅ GOOD: WebP with fallback -->
<picture>
  <source srcset="image.webp" type="image/webp">
  <img src="image.jpg" alt="Description" loading="lazy">
</picture>

<!-- ❌ BAD: Large PNG/JPG without optimization -->
<img src="huge-image.png">
```

**Videos:**
```javascript
// ✅ GOOD: HLS streaming for large videos
const video = document.querySelector('video');
if (Hls.isSupported()) {
  const hls = new Hls({
    maxBufferLength: 30,  // Optimize buffer
    maxMaxBufferLength: 600
  });
  hls.loadSource('video.m3u8');
}

// ❌ BAD: Single large MP4 file
<video src="huge-video.mp4"></video>
```

**Fonts:**
```html
<!-- ✅ GOOD: Subset and preload critical fonts -->
<link rel="preload" href="fonts/subset.woff2" as="font" type="font/woff2" crossorigin>

<!-- ❌ BAD: Load entire font family -->
<link href="https://fonts.googleapis.com/css2?family=Roboto:wght@100;200;300;400;500;600;700;800;900">
```

**Checklist:**
- [ ] Images: WebP format with fallback
- [ ] Videos: HLS streaming for files >10MB
- [ ] Fonts: Subset and preload critical fonts (<50KB)
- [ ] CSS: Critical CSS inline, defer non-critical

### Animation Performance (Motion.dev & CSS)

**GPU-Accelerated Properties:**
```javascript
// ✅ GOOD: Use transform/opacity (GPU-accelerated) with Motion.dev
import { animate } from "motion"

animate(
  ".element",
  { y: [100, 0], opacity: [0, 1] },
  { easing: "ease-out" }
);

// ✅ GOOD: CSS animations with transform
@keyframes slideIn {
  from { transform: translateY(100px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

// ❌ BAD: Animate top/left (triggers layout)
animate(
  ".element",
  { top: [100, 0], left: [0, 100] }  // Triggers layout recalculation - Expensive!
);
```

**will-change Management:**
```javascript
// ✅ GOOD: Add/remove will-change with Motion.dev
element.style.willChange = 'transform, opacity';

animate(
  element,
  { x: 250 },
  {
    onComplete: () => {
      element.style.willChange = 'auto';  // Remove after animation
    }
  }
);

// ❌ BAD: Leave will-change active
element.style.willChange = 'transform';  // Never removed
```

**Low-end Device Testing:**
```markdown
Chrome DevTools → Performance tab → CPU throttling (4x slowdown)
Test animations on throttled CPU to verify 60fps maintained
```

**Checklist:**
- [ ] Only animate transform/opacity (no width/height/top/left)
- [ ] Set will-change before animation
- [ ] Remove will-change after animation completes
- [ ] Test on throttled CPU (4x slowdown)
- [ ] Verify 60fps in Performance tab

### Request Optimization

**API Caching:**
```javascript
// ✅ GOOD: Cache API responses
const fetchData = async (url) => {
  const cached = sessionStorage.getItem(url);
  if (cached) {
    const { data, timestamp } = JSON.parse(cached);
    const STALE_TIME = 5 * 60 * 1000;  // 5 minutes
    if (Date.now() - timestamp < STALE_TIME) {
      return data;
    }
  }

  const response = await fetch(url);
  const data = await response.json();
  sessionStorage.setItem(url, JSON.stringify({
    data,
    timestamp: Date.now()
  }));
  return data;
};

// ❌ BAD: Fetch on every request
const fetchData = async (url) => {
  const response = await fetch(url);
  return response.json();
};
```

**Input Debouncing:**
```javascript
// ✅ GOOD: Debounce expensive operations
const debounce = (func, wait) => {
  let timeout;
  return (...args) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
};

searchInput.addEventListener('input', debounce((e) => {
  fetchSearchResults(e.target.value);
}, 300));

// ❌ BAD: Fire on every keystroke
searchInput.addEventListener('input', (e) => {
  fetchSearchResults(e.target.value);  // Expensive API call every keystroke
});
```

**Lazy Loading with IntersectionObserver:**
```javascript
// ✅ GOOD: Lazy load images/content
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const img = entry.target;
      img.src = img.dataset.src;
      observer.unobserve(img);
    }
  });
});

document.querySelectorAll('img[data-src]').forEach(img => observer.observe(img));

// ❌ BAD: Load all images upfront
document.querySelectorAll('img[data-src]').forEach(img => {
  img.src = img.dataset.src;  // All images load immediately
});
```

**Checklist:**
- [ ] API responses cached (staleTime: 5min default)
- [ ] User input handlers debounced (300ms default)
- [ ] Images/content lazy loaded with IntersectionObserver
- [ ] Third-party scripts minimized and loaded async
- [ ] CDN version parameters updated after changes

---

## 3. 📏 PERFORMANCE BUDGETS

**Target metrics:**
- First Contentful Paint (FCP): <1.8s
- Largest Contentful Paint (LCP): <2.5s
- Time to Interactive (TTI): <3.8s
- Total Blocking Time (TBT): <200ms
- Cumulative Layout Shift (CLS): <0.1

**Measure with:**
- Chrome DevTools Lighthouse tab
- Performance tab (record + analyze)
- Network tab (check waterfall)

---

## 4. 🚫 ANTI-PATTERNS

**Never:**
- ❌ Animate width/height/top/left (triggers layout)
- ❌ Use synchronous XHR requests
- ❌ Load large libraries without code splitting
- ❌ Leave will-change active after animation
- ❌ Skip lazy loading for below-the-fold content
- ❌ Ignore mobile performance (test on throttled CPU)

---

## 5. 🔗 INTEGRATION WITH WORKFLOWS-CODE

**Apply during:**
- **Phase 1 (Implementation)**: Use checklist before writing code
- **Phase 2 (Debugging)**: Use Performance tab to identify bottlenecks
- **Phase 3 (Verification)**: Verify metrics in Lighthouse

**See also:**
- [debugging_workflows.md](./debugging_workflows.md) - Performance debugging
- [verification_workflows.md](./verification_workflows.md) - Browser testing
- [devtools_guide.md](./devtools_guide.md) - DevTools reference
