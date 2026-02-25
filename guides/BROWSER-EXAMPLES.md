# Playwright MCP Integration Examples

Practical examples of using Playwright MCP tools for reverse engineering web apps.

## Overview

Ralph uses Playwright MCP Server to interact with your web app. This guide shows concrete examples of how to navigate, capture, and analyze pages.

## Basic Page Exploration

### Navigate to a Page

```javascript
// Tool: browser_navigate
// Purpose: Go to a specific URL

await browser_navigate({
  url: "https://www.zigbang.com/search"
})

// Result: Browser navigates to search page, waits for page load
```

### Capture Page Structure

```javascript
// Tool: browser_snapshot
// Purpose: Get accessibility tree (UI structure)

const snapshot = await browser_snapshot()

// Result: Hierarchical tree of UI elements
/*
{
  "role": "WebArea",
  "name": "검색",
  "children": [
    {
      "role": "button",
      "name": "검색",
      "ref": 1,
      "tagName": "button"
    },
    {
      "role": "textbox",
      "name": "지역 검색",
      "ref": 2,
      "tagName": "input"
    },
    {
      "role": "list",
      "children": [
        {"role": "listitem", "ref": 3, ...}
      ]
    }
  ]
}
*/
```

### Take Screenshot

```javascript
// Tool: browser_take_screenshot
// Purpose: Capture visual state

await browser_take_screenshot()

// Result: Returns base64 image data or saves to file
// Use for: Visual documentation, comparing states
```

## Device-Specific Capture

### ⚠️ Mobile Emulation Limitations (READ FIRST)

**CRITICAL**: Viewport resizing alone is insufficient for mobile testing. Most sites check user agent, not just screen size.

| Approach | Setup Required | Effectiveness | Use When |
|----------|----------------|---------------|----------|
| **Option A: Native** | Configure MCP server once | 95-100% | Highest accuracy needed |
| **Option B: Best-effort** | No setup (works out-of-box) | 70-80% | Autonomous operation, most sites |

**What doesn't work with Option B:**
- ❌ HTTP User-Agent header (affects ~10-20% of sites with server-side detection)
- ❌ True touch events (rare edge case)

**What works with Option B:**
- ✅ JavaScript checks (`navigator.userAgent`, `navigator.maxTouchPoints`)
- ✅ CSS media queries and responsive layouts
- ✅ Viewport-based rendering

**Recommendation for e2e-reverse skill**: Use Option B (best-effort) by default. Document when native emulation may be needed.

### Desktop View

```javascript
// Simple: resize and capture
await browser_resize({ width: 1280, height: 800 })
const desktopSnapshot = await browser_snapshot()
await browser_take_screenshot()
// Saved as: e2e/screenshots/search/initial.desktop.png
```

### Returning to Desktop (Reset Mobile Emulation)

**⚠️ IMPORTANT**: After using Option B mobile emulation, you MUST reset before capturing desktop views. `addInitScript()` permanently stacks scripts that cannot be removed—the only guaranteed reset is closing the browser.

#### Robust Method (Recommended)

Close browser and navigate fresh. **Important:** Store the URL when you first navigate, not when resetting.

```javascript
// AT START OF WORKFLOW: Store the URL
// const targetUrl = "https://example.com/search"
// await browser_navigate({ url: targetUrl })

// WHEN RESETTING TO DESKTOP:
// 1. Close browser (clears ALL state: routes, init scripts, everything)
await browser_close()

// 2. Navigate to stored URL (fresh browser, no emulation)
await browser_navigate({ url: targetUrl })  // Use the URL you stored earlier

// 3. Resize to desktop
await browser_resize({ width: 1280, height: 800 })

// 4. Verify UA is correct (optional debug step)
await browser_run_code({
  code: `async (page) => {
    const ua = await page.evaluate(() => navigator.userAgent);
    console.log('Current UA:', ua);
    return { userAgent: ua };
  }`
})

// 5. Capture
const desktopSnapshot = await browser_snapshot()
```

**Key points:**

- Store the URL at workflow start—don't try to capture it when resetting
- `browser_close()` destroys the entire browser context including all stacked init scripts
- `browser_navigate()` spawns a fresh browser with default UA

#### In-Page Reset (No Browser Restart)

This method keeps the browser open but overrides mobile settings. Less reliable but faster:

```javascript
await browser_run_code({
  code: `async (page) => {
    const desktopUA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

    // 1. Clear route handlers (stops HTTP header interception)
    await page.unrouteAll({ behavior: 'ignoreErrors' });

    // 2. Force desktop UA via init script (stacks on top of mobile script)
    await page.addInitScript(\`
      Object.defineProperty(navigator, 'userAgent', { get: () => '\${desktopUA}' });
      Object.defineProperty(navigator, 'maxTouchPoints', { get: () => 0 });
      Object.defineProperty(navigator, 'platform', { get: () => 'MacIntel' });
    \`);

    // 3. Reload - new init script runs AFTER old ones, overwriting values
    await page.reload({ waitUntil: 'networkidle' });

    return { success: true };
  }`
})
await browser_resize({ width: 1280, height: 800 })
```

**Why this works:** Init scripts stack in order. The desktop script runs after the mobile script, so desktop values win. HTTP headers use browser default after `unrouteAll()`.

**Limitation:** Scripts keep stacking. After many switches, page load slows down. Use robust method for clean state.

#### ⚡ Performance: Minimize Device Switches

Alternating between mobile and desktop degrades performance because:

- Each `addInitScript()` stacks (previous scripts still run)
- `browser_close()` + `browser_navigate()` is expensive (~1-2s per switch)
- Route handler setup/teardown adds overhead

**Recommended capture order:**

1. **Desktop first** → Capture all desktop states/screenshots
2. **Switch to mobile once** → Capture all mobile devices in sequence
3. **Reset to desktop only at end** → If you need desktop again

```javascript
// ✅ GOOD: Batch by device type
// 1. Desktop captures (no emulation overhead)
await browser_resize({ width: 1280, height: 800 })
captureDesktopStates()

// 2. Mobile captures (one setup, multiple sizes)
await setupMobileEmulation()  // Single setup
await browser_resize({ width: 390, height: 844 })   // iPhone
captureMobile()
await browser_resize({ width: 412, height: 915 })   // Android
captureMobile()

// 3. Reset only if desktop needed again (closes and reopens browser)
await resetToDesktop()

// ❌ BAD: Alternating (expensive browser close/reopen each switch)
captureDesktop() → setupMobile() → captureMobile() → resetDesktop() → captureDesktop() → setupMobile()...
```

### Mobile View - Option A (Native Emulation)

**One-time setup** in MCP config (e.g., `claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest", "--device", "iPhone 13"]
    }
  }
}
```

**Usage** (same as desktop - context handles everything):

```javascript
await browser_resize({ width: 390, height: 844 })
const mobileSnapshot = await browser_snapshot()
await browser_take_screenshot()
```

See [setup.md Step 4](../setup.md) for detailed MCP configuration instructions.

### Mobile View - Option B (Best-Effort Emulation)

**No setup required** - works immediately:

```javascript
// 1. Resize viewport FIRST
await browser_resize({ width: 390, height: 844 })

// 2. Set up route interception + init scripts + reload
await browser_run_code({
  code: `async (page) => {
    const mobileUA = 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';

    // 1. Intercept ALL requests and override User-Agent HTTP header
    await page.route('**/*', route => {
      const headers = {
        ...route.request().headers(),
        'user-agent': mobileUA
      };
      route.continue({ headers });
    });

    // 2. Override JavaScript navigator properties for client-side checks
    await page.addInitScript(\`
      Object.defineProperty(navigator, 'userAgent', {
        get: () => '\${mobileUA}'
      });
      Object.defineProperty(navigator, 'maxTouchPoints', { get: () => 5 });
      Object.defineProperty(navigator, 'platform', { get: () => 'iPhone' });
    \`);

    // 3. Reload - route handler modifies HTTP headers, init script runs on load
    await page.reload({ waitUntil: 'networkidle' });
  }`
})

// 3. Capture (both HTTP headers and JS properties are now mobile)
const mobileSnapshot = await browser_snapshot()
await browser_take_screenshot()
```

**⚠️ Why both `page.route()` AND `addInitScript()` are needed**:

- `page.route()` intercepts HTTP requests BEFORE they're sent → server sees mobile UA
- `addInitScript()` overrides JS `navigator.userAgent` → client-side code sees mobile UA
- Without `page.route()`, the server receives desktop UA and may return desktop HTML

### Compare Device Differences

```javascript
// After capturing both desktop and mobile snapshots:

function findDeviceDifferences(desktopSnap, mobileSnap) {
  // Desktop has inline dropdown
  const desktopDropdown = findByRole(desktopSnap, "combobox")

  // Mobile has full-screen overlay
  const mobileOverlay = findByRole(mobileSnap, "dialog")

  // Document different behaviors:
  if (desktopDropdown && !mobileOverlay) {
    return {
      desktop: "Dropdown autocomplete appears inline",
      mobile: "Full-screen search overlay opens"
    }
  }
}

// Result: Device-specific scenarios in Gherkin
/*
@desktop
Scenario: Search autocomplete
  When user clicks search input
  Then dropdown appears below input

@mobile
Scenario: Search overlay
  When user taps search bar
  Then full-screen overlay opens
*/
```

## Interaction Patterns

### Click Element

**⚠️ IMPORTANT: Selector Reliability Hierarchy (Playwright 2026 Best Practices)**

Use selectors in this order of preference:

1. **Role-based locators** (MOST RELIABLE - Playwright 2026 recommendation)
2. **aria-label / accessible name selectors**
3. **data-testid or semantic attributes**
4. **Refs from snapshot** (LEAST RELIABLE - use as last resort)

```javascript
// Method 1: Role-based locator (BEST - Playwright 2026)
await browser_click({
  selector: "role=button[name='검색']"
})
// Advantages: Matches how users and assistive tech find elements
// Resilient: Works even if implementation changes (class, id, structure)

// Method 2: aria-label selector (GOOD)
await browser_click({
  selector: "button[aria-label='검색']"
})
// Advantages: Semantic, accessible
// Risk: Breaks if aria-label changes

// Method 3: data-testid (OK for test-specific attributes)
await browser_click({
  selector: "[data-testid='search-button']"
})
// Advantages: Explicit test hooks
// Risk: Requires adding test attributes to code

// Method 4: Ref from snapshot (USE WITH CAUTION)
await browser_click({
  ref: 5  // Reference from snapshot - can resolve to wrong element
})
// Risk: Refs can be unstable on dynamic pages
// Only use when other methods fail

// Use case: Trigger state changes to explore different UI states
// Example: Click filter to show filter panel, click tab to see different content
```

**Why role-based locators are superior (2026 best practice):**

- Match how users perceive and interact with UI
- Resilient to implementation changes (CSS refactoring, framework upgrades)
- Force accessible markup (if role doesn't work, UI might have accessibility issues)
- Work across frameworks and shadow DOM boundaries
- Recommended by Playwright, Testing Library, and W3C ARIA practices

**Common Playwright roles:**
- `role=button[name='Text']` - Buttons, clickable elements
- `role=textbox[name='Label']` - Input fields
- `role=link[name='Link text']` - Links
- `role=checkbox[name='Label']` - Checkboxes
- `role=tab[name='Tab name']` - Tabs
- `role=dialog[name='Title']` - Modals, dialogs
- `role=listitem` - List items

**Fallback strategy:**

```javascript
// Try role-based first
try {
  await browser_click({ selector: "role=button[name='검색']" })
} catch (error) {
  // Fallback to aria-label
  try {
    await browser_click({ selector: "button[aria-label='검색']" })
  } catch (error) {
    // Last resort: ref
    await browser_click({ ref: 5 })
  }
}
```

### Enter Text

```javascript
// Method 1: Role-based locator (BEST)
await browser_type({
  selector: "role=textbox[name='지역 검색']",
  text: "강남역"
})

// Method 2: Attribute selector (GOOD)
await browser_type({
  selector: "input[placeholder='지역 검색']",
  text: "강남역"
})

// Method 3: Ref from snapshot (FALLBACK)
await browser_type({
  ref: 2,  // textbox from snapshot
  text: "강남역"
})

// Use case: Test search, forms, validation
```

### Wait for State Change

```javascript
// After clicking, wait for UI to update
await browser_wait_for({
  selector: "[data-loading='true']",
  timeout: 5000
})

// Then capture the loading state
const loadingSnapshot = await browser_snapshot()
await browser_take_screenshot()
// Save as: e2e/screenshots/search/loading.png
```

## State Discovery Workflow

### 1. Discover Interactive Elements

```javascript
// Navigate to page
await browser_navigate({url: base_url + "/search"})

// Get initial snapshot
const snapshot = await browser_snapshot()

// Find all interactive elements
function findInteractiveElements(node) {
  const interactive = []

  if (node.role in ["button", "link", "textbox", "combobox", "checkbox", "tab"]) {
    interactive.push({
      role: node.role,
      name: node.name,
      ref: node.ref
    })
  }

  if (node.children) {
    node.children.forEach(child => {
      interactive.push(...findInteractiveElements(child))
    })
  }

  return interactive
}

const elements = findInteractiveElements(snapshot)
// Result: [
//   {role: "button", name: "검색", ref: 1},
//   {role: "textbox", name: "지역 검색", ref: 2},
//   {role: "button", name: "필터", ref: 3},
//   ...
// ]
```

### 2. Trigger State Changes

```javascript
// Try clicking each interactive element to discover states

// Example: Click filter button
await browser_click({ref: 3})  // Filter button

// Wait for animation
await browser_wait_for({
  selector: "[data-state='open']",
  timeout: 3000
})

// Capture filter panel state
const filterOpenSnapshot = await browser_snapshot()
await browser_take_screenshot()
// Save as: e2e/screenshots/search/filter-panel.desktop.png

// Document finding:
// "Filter button (ref 3) opens filter panel with price/location/type controls"
```

### 3. Discover Error States

```javascript
// Trigger validation error
await browser_type({ref: 2, text: ""})  // Empty search
await browser_click({ref: 1})  // Search button

// Wait for error
await browser_wait_for({
  selector: "[role='alert']",
  timeout: 3000
})

// Capture error state
const errorSnapshot = await browser_snapshot()
await browser_take_screenshot()
// Save as: e2e/screenshots/search/error-validation.desktop.png

// Find error message
function findError(snapshot) {
  function search(node) {
    if (node.role === "alert") {
      return node.name  // Error message text
    }
    if (node.children) {
      for (let child of node.children) {
        const found = search(child)
        if (found) return found
      }
    }
  }
  return search(snapshot)
}

const errorText = findError(errorSnapshot)
// Result: "검색어를 입력해주세요"
```

### 4. Discover Loading States

```javascript
// Trigger async operation
await browser_type({ref: 2, text: "강남역"})
await browser_click({ref: 1})

// Immediately capture loading state (before results appear)
const loadingSnapshot = await browser_snapshot()

// Find loading indicators
function findLoadingIndicators(snapshot) {
  function search(node) {
    const indicators = []

    if (node.role === "progressbar" ||
        node.className?.includes("loading") ||
        node.className?.includes("spinner") ||
        node.className?.includes("skeleton")) {
      indicators.push({
        role: node.role,
        className: node.className,
        ref: node.ref
      })
    }

    if (node.children) {
      node.children.forEach(child => {
        indicators.push(...search(child))
      })
    }

    return indicators
  }
  return search(snapshot)
}

const loaders = findLoadingIndicators(loadingSnapshot)
// Result: [
//   {role: "progressbar", className: "search-spinner", ref: 15},
//   {className: "skeleton-card", ref: 16}
// ]

// Take screenshot
await browser_take_screenshot()
// Save as: e2e/screenshots/search/loading.png
```

## Complete Page Exploration Example

```javascript
// Full workflow for documenting search page

async function exploreSearchPage(config) {
  const devices = config.devices  // [{name: "desktop", width: 1280, height: 800}, ...]
  const baseUrl = config.base_url
  const outputDir = config.output_dir
  const screenshotDir = config.screenshot_dir

  // 1. NAVIGATE (once per page)
  await browser_navigate({url: baseUrl + "/search"})

  // 2. CAPTURE ALL DEVICES (batch)
  const deviceData = {}

  for (const device of devices) {
    await browser_resize({
      width: device.width,
      height: device.height
    })

    // Configure mobile emulation for mobile/tablet devices (Option B approach)
    if (device.name === 'mobile' || device.name === 'tablet') {
      const userAgent = device.name === 'mobile'
        ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1'
        : 'Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';

      await browser_run_code({
        code: `async (page) => {
          const ua = '${userAgent}';
          const touchPoints = ${device.name === 'mobile' ? 5 : 5};
          const platform = '${device.name === 'mobile' ? 'iPhone' : 'iPad'}';

          // 1. Route handler for HTTP User-Agent header
          await page.route('**/*', route => {
            route.continue({
              headers: { ...route.request().headers(), 'user-agent': ua }
            });
          });

          // 2. Init script for JS navigator properties
          await page.addInitScript(\`
            Object.defineProperty(navigator, 'userAgent', { get: () => '\${ua}' });
            Object.defineProperty(navigator, 'maxTouchPoints', { get: () => \${touchPoints} });
            Object.defineProperty(navigator, 'platform', { get: () => '\${platform}' });
          \`);

          // 3. Reload to apply
          await page.reload({ waitUntil: 'networkidle' });
        }`
      })
    }

    const snapshot = await browser_snapshot()
    await browser_take_screenshot()
    // Save to: {screenshotDir}/search/{device.name}/initial.{device.name}.png

    deviceData[device.name] = {
      snapshot: snapshot,
      screenshot: `initial.${device.name}.png`
    }
  }

  // 3. EXPLORE STATES (device-agnostic, done once)

  // Reset to desktop for exploration (use stored URL, not dynamic capture)
  await browser_close()
  await browser_navigate({ url: baseUrl + "/search" })  // Use the URL we stored at start
  await browser_resize({ width: 1280, height: 800 })

  const states = []

  // State 1: Empty state (no search input)
  const emptySnapshot = await browser_snapshot()
  states.push({
    name: "empty-state",
    snapshot: emptySnapshot
  })

  // State 2: Loading state
  await browser_type({selector: "input[placeholder='지역 검색']", text: "강남역"})
  await browser_click({selector: "button[aria-label='검색']"})

  // Quick capture before results load
  const loadingSnapshot = await browser_snapshot()
  states.push({
    name: "loading",
    snapshot: loadingSnapshot
  })

  // Wait for results
  await browser_wait_for({
    selector: "[data-results='loaded']",
    timeout: 10000
  })

  // State 3: Success state with results
  const resultsSnapshot = await browser_snapshot()
  states.push({
    name: "success",
    snapshot: resultsSnapshot
  })

  // State 4: Error state (simulate network error or empty results)
  await browser_type({selector: "input[placeholder='지역 검색']", text: "asdfghjkl"})
  await browser_click({selector: "button[aria-label='검색']"})
  await browser_wait_for({
    selector: "[data-empty='true']",
    timeout: 5000
  })

  const emptyResultsSnapshot = await browser_snapshot()
  states.push({
    name: "empty-results",
    snapshot: emptyResultsSnapshot
  })

  // 4. CAPTURE DEVICE-SPECIFIC STATES
  for (const state of states) {
    // Recreate state for each device
    for (const device of devices) {
      await browser_resize({
        width: device.width,
        height: device.height
      })

      // Re-trigger state (details omitted for brevity)
      // ...

      await browser_take_screenshot()
      // Save to: {screenshotDir}/search/{device.name}/{state.name}.png
    }
  }

  // 5. ANALYZE DEVICE DIFFERENCES
  const differences = []

  // Compare desktop vs mobile snapshots
  const desktopSnap = deviceData.desktop.snapshot
  const mobileSnap = deviceData.mobile.snapshot

  // Example: Search input behavior differs
  const desktopInput = findElement(desktopSnap, {role: "combobox"})
  const mobileInput = findElement(mobileSnap, {role: "searchbox"})

  if (desktopInput && !mobileInput) {
    // Desktop has combobox (autocomplete dropdown)
    // Mobile has regular searchbox (full-screen overlay)
    differences.push({
      element: "search-input",
      desktop: "Inline autocomplete dropdown",
      mobile: "Full-screen search overlay"
    })
  }

  // 6. GENERATE GHERKIN
  const gherkin = `
@search @route(/search)
Feature: Property Search
  Users can search for rental properties by location, price, and amenities.

  Background:
    Given user is on search page

  @smoke @happy-path
  Rule: Basic Search
    Scenario: Search by location keyword
      When user searches for "강남역"
      Then search results list appears
      And results count shows total number

  @desktop
  Rule: Desktop Search Experience
    Scenario: Search autocomplete
      When user focuses search input
      Then autocomplete dropdown appears below input
      And recent searches display first
      And popular locations display second

  @mobile
  Rule: Mobile Search Experience
    Scenario: Search overlay
      When user opens search
      Then full-screen search overlay opens
      And search input is auto-focused

  @empty-state @regression
  Rule: No Results Handling
    Scenario: Search with no matches
      When user searches for non-existent location
      Then empty state message appears
      And message shows "검색 결과가 없습니다"

  @loading @regression
  Rule: Loading State
    Scenario: Show loading during search
      When user submits search
      Then loading spinner appears
      And skeleton cards display
      And search is unavailable

  @error @edge-case
  Rule: Validation
    Scenario: Empty search input
      When user attempts search without input
      Then validation error appears
      And message shows "검색어를 입력해주세요"
`

  // Write to file: {outputDir}/search.feature
  // ...

  return {
    page: "/search",
    devices: devices.map(d => d.name),
    states: states.map(s => s.name),
    differences: differences,
    scenarios: 7,
    quality_score: calculateQualityScore(...)
  }
}
```

## Helper Functions

### Find Element by Role

```javascript
function findElement(snapshot, criteria) {
  function search(node) {
    // Check if node matches criteria
    let matches = true

    if (criteria.role && node.role !== criteria.role) {
      matches = false
    }

    if (criteria.name && !node.name?.includes(criteria.name)) {
      matches = false
    }

    if (criteria.tagName && node.tagName !== criteria.tagName) {
      matches = false
    }

    if (matches) {
      return node
    }

    // Search children
    if (node.children) {
      for (let child of node.children) {
        const found = search(child)
        if (found) return found
      }
    }

    return null
  }

  return search(snapshot)
}

// Usage:
const searchButton = findElement(snapshot, {
  role: "button",
  name: "검색"
})
```

### Extract All Interactive Elements

```javascript
function extractInteractiveElements(snapshot) {
  const interactiveRoles = [
    "button", "link", "textbox", "combobox", "checkbox",
    "radio", "tab", "switch", "slider", "menu", "menuitem"
  ]

  const elements = []

  function traverse(node) {
    if (interactiveRoles.includes(node.role)) {
      elements.push({
        role: node.role,
        name: node.name || "unnamed",
        ref: node.ref,
        tagName: node.tagName,
        value: node.value,
        checked: node.checked,
        selected: node.selected
      })
    }

    if (node.children) {
      node.children.forEach(traverse)
    }
  }

  traverse(snapshot)
  return elements
}

// Usage:
const elements = extractInteractiveElements(snapshot)
elements.forEach(el => {
  console.log(`Found ${el.role}: "${el.name}" (ref: ${el.ref})`)
})
```

### Detect UI Patterns

```javascript
function detectUIPatterns(snapshot) {
  const patterns = {
    hasFilters: false,
    hasInfiniteScroll: false,
    hasTabs: false,
    hasModal: false,
    hasBottomSheet: false,
    hasSkeleton: false
  }

  function traverse(node) {
    // Detect filters
    if (node.className?.includes("filter") ||
        node.role === "combobox" ||
        node.role === "checkbox") {
      patterns.hasFilters = true
    }

    // Detect tabs
    if (node.role === "tab" || node.role === "tablist") {
      patterns.hasTabs = true
    }

    // Detect modal/dialog
    if (node.role === "dialog" || node.className?.includes("modal")) {
      patterns.hasModal = true
    }

    // Detect bottom sheet (mobile pattern)
    if (node.className?.includes("bottom-sheet") ||
        node.className?.includes("BottomSheet")) {
      patterns.hasBottomSheet = true
    }

    // Detect skeleton loading
    if (node.className?.includes("skeleton")) {
      patterns.hasSkeleton = true
    }

    // Detect infinite scroll
    if (node.className?.includes("infinite-scroll") ||
        node.ariaLabel?.includes("load more") ||
        node.ariaLabel?.includes("더보기")) {
      patterns.hasInfiniteScroll = true
    }

    if (node.children) {
      node.children.forEach(traverse)
    }
  }

  traverse(snapshot)
  return patterns
}

// Usage:
const patterns = detectUIPatterns(snapshot)
if (patterns.hasFilters) {
  // Document filter scenarios
}
if (patterns.hasInfiniteScroll) {
  // Document pagination/infinite scroll scenarios
}
```

## Error Handling

### Timeout Handling

```javascript
try {
  await browser_wait_for({
    selector: "[data-results='loaded']",
    timeout: 5000
  })
} catch (error) {
  if (error.name === "TimeoutError") {
    console.log("Results didn't load in time - may indicate slow API")
    // Document as loading state or performance issue
  }
}
```

### Element Not Found

```javascript
// Attempt to click element
try {
  await browser_click({selector: "button[aria-label='필터']"})
} catch (error) {
  if (error.message.includes("not found")) {
    console.log("Filter button not present on this page")
    // Skip filter scenarios for this page
  }
}
```

### Navigation Errors

```javascript
try {
  await browser_navigate({url: base_url + "/nonexistent"})
} catch (error) {
  if (error.message.includes("404")) {
    console.log("Page not found - skip this URL")
    // Mark page as not-found, don't document
  }
}
```

## Performance Tips

### Batch Device Captures

❌ **Slow** (navigate per device):
```javascript
for (const device of devices) {
  await browser_navigate({url: page_url})
  await browser_resize(device)
  await browser_snapshot()
}
```

✅ **Fast** (navigate once, resize per device):
```javascript
await browser_navigate({url: page_url})

for (const device of devices) {
  await browser_resize(device)
  await browser_snapshot()
}
```

### Reuse Snapshots

```javascript
// Capture once
const snapshot = await browser_snapshot()

// Analyze multiple times (no additional API calls)
const interactive = extractInteractiveElements(snapshot)
const patterns = detectUIPatterns(snapshot)
const differences = compareWithMobileSnapshot(snapshot, mobileSnapshot)
```

### Parallel Screenshot Capture

If capturing multiple states, prepare states first, then batch screenshot:

```javascript
const statesToCapture = []

// Set up state 1
await triggerState1()
statesToCapture.push({name: "state1"})

// Set up state 2
await triggerState2()
statesToCapture.push({name: "state2"})

// Capture all at once
for (const state of statesToCapture) {
  await recreateState(state)
  await browser_take_screenshot()
}
```

## Integration with Ralph Loop

Ralph uses these patterns in `start.md`:

1. **Navigate** → `browser_navigate`
2. **Capture devices** → Loop: `browser_resize` + `browser_snapshot` + `browser_take_screenshot`
3. **Explore states** → `browser_click` / `browser_type` + `browser_wait_for`
4. **Analyze** → Helper functions on snapshots
5. **Document** → Generate Gherkin from analysis
6. **Validate** → Use `_validate-gherkin` utility
7. **Update state** → Use `_write-checkpoint` utility
8. **Repeat** → Select next page based on scoring

See `start.md` for the full integration details.

---

*These examples show real-world Playwright MCP usage patterns for reverse engineering web apps.*
