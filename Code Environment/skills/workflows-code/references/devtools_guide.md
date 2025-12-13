# Browser DevTools Comprehensive Guide

Consolidated reference for DevTools features used across all workflows.

---

## 1. 📋 ESSENTIAL OPERATIONS

### Console Panel

**Viewing Errors and Warnings:**
- Red errors: JavaScript execution failures
- Yellow warnings: Non-critical issues
- Blue info: Informational messages
- Expand error to see full stack trace

**Executing Commands:**
```javascript
// Test code directly in console
document.querySelector('[video-hero]').play();

// Inspect variables
console.log(myVariable);

// Check function availability
typeof Hls !== 'undefined'
```

**Filtering:**
- Filter by log level (Errors, Warnings, Info)
- Filter by text search
- Filter by source file
- Show/hide network errors

### Elements/Inspector Panel

**Inspecting DOM:**
- Right-click element → Inspect
- Cmd+Shift+C to activate picker
- View element attributes
- See applied CSS styles

**Editing Live:**
- Double-click to edit text
- Right-click → Edit as HTML
- Toggle CSS properties
- Add new CSS rules

**Computed Styles:**
- View final computed values
- See which styles override
- Check specificity
- View box model diagram

### Sources/Debugger Panel

**Setting Breakpoints:**
- Click line number to add breakpoint
- Right-click → Add conditional breakpoint
- Breakpoints persist across reloads
- Disable/enable individual breakpoints

**Stepping Through Code:**
- F8: Resume execution
- F10: Step over (next line)
- F11: Step into (enter function)
- Shift+F11: Step out (exit function)

**Call Stack:**
- View full execution path
- Click stack frame to jump to that point
- See all function calls leading to current position

**Scope:**
- Local variables
- Closure variables
- Global variables
- Watch expressions

### Network Panel

**Monitoring Requests:**
- View all resource loads
- Filter by type (XHR, JS, CSS, Media)
- See request/response headers
- View timing breakdown

**Failed Requests:**
- Red items indicate failures
- Check status code (404, 500, etc.)
- View error messages
- Check CORS issues

**Throttling:**
- Simulate slow connections
- Test offline behavior
- Custom throttling profiles

### Performance Panel

**Recording:**
- Click record → interact → stop
- Captures CPU, network, rendering
- Shows frame rate
- Identifies bottlenecks

**Analysis:**
- Flame chart shows function calls
- Main thread activity
- GPU activity
- Memory usage

---

## 2. 🔍 DEBUGGING FEATURES

### Programmatic Breakpoints

```javascript
function suspectFunction() {
  debugger; // Execution pauses here
  // Code continues when you step/resume
}
```

### Conditional Breakpoints

Right-click line number → "Add conditional breakpoint"
```javascript
// Only pause when condition true
userId === '12345'
count > 100
!element
```

### Logpoints

Right-click line number → "Add logpoint"
```javascript
// Logs without modifying code
'User ID:', userId, 'Count:', count
```

### Call Stack Inspection

**Reading the stack:**
```
at play (video-player.js:45)
at initialize (video-player.js:20)
at DOMContentLoaded (app.js:15)
```
- Bottom = where execution started
- Top = current position
- Click any frame to jump to that code

### Event Listener Inspection

```javascript
// View all listeners on element
getEventListeners(element);

// Output:
// {
//   click: [{ listener: ƒ, useCapture: false }],
//   focus: [{ listener: ƒ, useCapture: false }]
// }
```

**Event Listener Breakpoints:**
- Sources → Event Listener Breakpoints
- Check event types to pause on
- Mouse, keyboard, timer, etc.

### XHR/Fetch Breakpoints

Sources → XHR/Fetch Breakpoints
- Pause on any request
- Pause on specific URL patterns
- Inspect request before sending

---

## 3. ⚡ QUICK REFERENCE

### Keyboard Shortcuts

**Chrome:**
| Action | Shortcut |
|--------|----------|
| Open DevTools | F12 / Cmd+Option+I |
| Inspect element | Cmd+Shift+C |
| Console | Cmd+Option+J |
| Hard refresh | Cmd+Shift+R |
| Device toolbar | Cmd+Shift+M |
| Search files | Cmd+P |
| Command menu | Cmd+Shift+P |

### Console API

```javascript
// Basic logging
console.log('message', data);
console.warn('warning', data);
console.error('error', data);
console.info('info', data);

// Grouping
console.group('Group Name');
console.log('item 1');
console.log('item 2');
console.groupEnd();

// Timing
console.time('operation');
// ... code ...
console.timeEnd('operation');

// Call stack
console.trace();

// Table view
console.table([
  { name: 'Item 1', value: 100 },
  { name: 'Item 2', value: 200 }
]);

// Assert
console.assert(condition, 'Message if false');

// Count
console.count('label'); // Increments counter

// Clear
console.clear();
```

### Element Inspection

```javascript
// Select single element
$('[selector]'); // Same as querySelector

// Select all elements
$$('[selector]'); // Same as querySelectorAll

// Recently inspected
$0; // Most recent
$1; // Second most recent
$2, $3, $4; // etc.

// Copy to clipboard
copy($0);
copy(object);

// Monitor events
monitorEvents($0);
monitorEvents($0, 'click');
unmonitorEvents($0);

// Get event listeners
getEventListeners($0);
```

### Network Debugging

```javascript
// Check online status
navigator.onLine;

// Simulate offline
// DevTools → Network → Throttling → Offline

// Monitor connectivity
window.addEventListener('online', () => {
  console.log('Back online');
});

window.addEventListener('offline', () => {
  console.log('Gone offline');
});
```

---

## 4. 🎯 COMMON WORKFLOWS

### Debugging JavaScript Errors

1. Open Console, read error message
2. Click stack trace link to jump to code
3. Set breakpoint on error line
4. Refresh page
5. Inspect variables in Scope panel
6. Step through to find issue

### Inspecting CSS Issues

1. Right-click element → Inspect
2. Elements panel shows applied styles
3. Computed tab shows final values
4. Toggle checkboxes to test changes
5. Edit values live to experiment
6. Copy final CSS when fixed

### Analyzing Performance

1. Performance panel → Record
2. Interact with page
3. Stop recording
4. Analyze flame chart
5. Identify slow operations
6. Optimize those sections

### Testing Responsive Design

1. Toggle device toolbar (Cmd+Shift+M)
2. Select device preset or custom size
3. Test interactions at that size
4. Check breakpoints by resizing
5. Rotate device (portrait/landscape)
6. Test touch events if applicable

---

## 5. 🔗 INTEGRATION POINTS

### Used In
- **implementation_workflows** - DevTools for development
- **debugging_workflows** - DevTools for debugging
- **verification_workflows** - DevTools for verification

### External Resources
- Chrome DevTools: https://developer.chrome.com/docs/devtools/

---

**See also:**
- [shared_patterns.md](./shared_patterns.md) - DevTools quick reference
- [quick_reference.md](./quick_reference.md) - One-page cheat sheet