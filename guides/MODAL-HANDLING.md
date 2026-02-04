# Modal and Dialog Handling Guide

How Ralph should handle modals, dialogs, and overlays that block interaction during exploration.

## Problem

Modals are challenging because:
1. **Blocking behavior**: They prevent interaction with underlying content
2. **Dynamic timing**: They may appear asynchronously
3. **Unstable refs**: Element references from snapshots may not be reliable
4. **Need dismissal**: Must be closed before continuing exploration

## Detection

### Identify Modals in Snapshot

```javascript
function findModals(snapshot) {
  const modals = []

  function traverse(node) {
    // Check for modal/dialog roles
    if (node.role === "dialog" ||
        node.role === "alertdialog" ||
        node.className?.includes("modal") ||
        node.className?.includes("Modal") ||
        node.className?.includes("overlay") ||
        node.className?.includes("Overlay")) {
      modals.push(node)
    }

    if (node.children) {
      node.children.forEach(traverse)
    }
  }

  traverse(snapshot)
  return modals
}
```

## Dismissal Strategies

### Strategy 1: Find Close Button by Semantic Attributes (PREFERRED)

```javascript
async function dismissModalBySemantic(modal) {
  // Try multiple semantic selectors
  const closeSelectors = [
    "[aria-label*='close' i]",
    "[aria-label*='닫기' i]",
    "[aria-label*='dismiss' i]",
    "[title*='close' i]",
    "[title*='닫기' i]",
    "button:has-text('닫기')",
    "button:has-text('Close')",
    "button:has-text('✕')",
    "button:has-text('×')",
    "[data-testid*='close']",
    "[data-testid*='dismiss']",
    ".close-button",
    ".modal-close",
    ".dialog-close"
  ]

  for (const selector of closeSelectors) {
    try {
      await browser_click({ selector, timeout: 2000 })
      console.log(`✅ Modal dismissed using selector: ${selector}`)

      // Wait for modal to disappear
      await browser_wait_for({
        selector: "[role='dialog']",
        state: "hidden",
        timeout: 3000
      })

      return true
    } catch (error) {
      continue
    }
  }

  return false
}
```

### Strategy 2: Find Close Button in Modal Structure

```javascript
async function dismissModalByStructure(modal) {
  // Look for buttons within the modal
  function findCloseButton(node) {
    if (node.role === "button") {
      const text = (node.name || "").toLowerCase()
      const ariaLabel = (node.ariaLabel || "").toLowerCase()

      // Check for close-related text
      if (text.includes("close") || text.includes("닫기") ||
          text.includes("dismiss") || text === "✕" || text === "×" ||
          ariaLabel.includes("close") || ariaLabel.includes("닫기")) {
        return node
      }
    }

    if (node.children) {
      for (const child of node.children) {
        const found = findCloseButton(child)
        if (found) return found
      }
    }

    return null
  }

  const closeButton = findCloseButton(modal)

  if (closeButton) {
    // Try using ref (less reliable but worth attempting)
    if (closeButton.ref) {
      try {
        await browser_click({ ref: closeButton.ref, timeout: 2000 })
        console.log(`✅ Modal dismissed using ref: ${closeButton.ref}`)
        return true
      } catch (error) {
        console.log(`⚠️ Ref click failed: ${error.message}`)
      }
    }
  }

  return false
}
```

### Strategy 3: Click Modal Backdrop/Overlay

```javascript
async function dismissModalByBackdrop() {
  const backdropSelectors = [
    ".modal-backdrop",
    ".overlay",
    ".dialog-overlay",
    "[data-backdrop='true']",
    ".ReactModal__Overlay"
  ]

  for (const selector of backdropSelectors) {
    try {
      await browser_click({ selector, timeout: 2000 })
      console.log(`✅ Modal dismissed by clicking backdrop: ${selector}`)

      // Verify modal is gone
      await browser_wait_for({
        selector: "[role='dialog']",
        state: "hidden",
        timeout: 3000
      })

      return true
    } catch (error) {
      continue
    }
  }

  return false
}
```

### Strategy 4: Press Escape Key

```javascript
async function dismissModalByEscape() {
  try {
    await browser_run_code({
      code: `async (page) => {
        await page.keyboard.press('Escape');
      }`
    })

    console.log(`✅ Modal dismissed using Escape key`)

    // Wait for modal to disappear
    await browser_wait_for({
      selector: "[role='dialog']",
      state: "hidden",
      timeout: 3000
    })

    return true
  } catch (error) {
    console.log(`⚠️ Escape key failed: ${error.message}`)
    return false
  }
}
```

### Strategy 5: JavaScript Force Dismiss (LAST RESORT)

```javascript
async function dismissModalByJavaScript() {
  try {
    await browser_run_code({
      code: `async (page) => {
        // Remove all modals/dialogs from DOM
        await page.evaluate(() => {
          // Find and remove modal elements
          const modals = document.querySelectorAll(
            '[role="dialog"], [role="alertdialog"], .modal, .Modal, .overlay, .Overlay'
          );
          modals.forEach(modal => modal.remove());

          // Remove backdrop elements
          const backdrops = document.querySelectorAll(
            '.modal-backdrop, .overlay, .ReactModal__Overlay'
          );
          backdrops.forEach(backdrop => backdrop.remove());

          // Re-enable body scroll (often disabled by modals)
          document.body.style.overflow = '';
          document.body.style.position = '';
        });
      }`
    })

    console.log(`✅ Modal force-dismissed using JavaScript`)
    return true
  } catch (error) {
    console.log(`⚠️ JavaScript dismiss failed: ${error.message}`)
    return false
  }
}
```

## Complete Dismissal Flow

```javascript
async function dismissModal(snapshot) {
  console.log("⏺ Modal detected - attempting dismissal...")

  const modals = findModals(snapshot)

  if (modals.length === 0) {
    console.log("✅ No modals found")
    return true
  }

  console.log(`Found ${modals.length} modal(s)`)

  // Try strategies in order of preference
  const strategies = [
    { name: "Semantic selectors", fn: dismissModalBySemantic },
    { name: "Modal structure", fn: () => dismissModalByStructure(modals[0]) },
    { name: "Backdrop click", fn: dismissModalByBackdrop },
    { name: "Escape key", fn: dismissModalByEscape },
    { name: "JavaScript force", fn: dismissModalByJavaScript }
  ]

  for (const strategy of strategies) {
    console.log(`⏺ Trying strategy: ${strategy.name}`)

    try {
      const success = await strategy.fn()

      if (success) {
        console.log(`✅ Modal dismissed successfully using: ${strategy.name}`)

        // Take a fresh snapshot to verify
        await wait(500)  // Brief pause for animations
        const newSnapshot = await browser_snapshot()
        const remainingModals = findModals(newSnapshot)

        if (remainingModals.length === 0) {
          console.log("✅ All modals cleared - continuing exploration")
          return true
        } else {
          console.log(`⚠️ ${remainingModals.length} modal(s) still present`)
          continue
        }
      }
    } catch (error) {
      console.log(`⚠️ Strategy failed: ${error.message}`)
      continue
    }
  }

  // All strategies failed
  console.log("❌ Unable to dismiss modal - will document it as a feature")
  return false
}
```

## Integration with Ralph Loop

### When to Check for Modals

```javascript
// In start.md Core Loop, after navigation:

// 1. NAVIGATE
await browser_navigate({ url: page_url })

// 2. CHECK FOR MODALS (before capturing states)
const initialSnapshot = await browser_snapshot()
const modalDismissed = await dismissModal(initialSnapshot)

if (!modalDismissed) {
  // Modal couldn't be dismissed - document it
  console.log("⏺ Persistent modal detected - documenting as feature")

  // Capture modal as a state
  await browser_take_screenshot()
  // Save as: {screenshot_dir}/{feature}/modal.png

  // Document modal in Gherkin
  const modalScenario = `
  @smoke
  Rule: App Installation Modal
    Scenario: Modal appears on page load
      Given user navigates to page
      Then app installation modal appears
      And modal shows "앱 설치" prompt
  `

  // Continue exploration with modal present (if possible)
  // Or skip this page and mark it for manual review
}

// 3. CAPTURE ALL DEVICES (continue normal flow)
```

### Documenting Modals as Features

If a modal cannot be dismissed, treat it as a feature to document:

```gherkin
@modal @app-promotion @smoke
Feature: App Installation Prompt

  Rule: Modal Display
    @role(anonymous)
    Scenario: Modal appears on first visit
      Given user visits site for first time
      Then app installation modal appears
      And modal has "앱 설치" text
      And modal has close button in top-right corner

  Rule: Modal Dismissal
    Scenario: User can close modal
      Given app installation modal is open
      When user clicks close button
      Then modal disappears
      And underlying page is accessible

    @mobile
    Scenario: User can dismiss with backdrop
      Given app installation modal is open
      When user taps backdrop outside modal
      Then modal disappears
```

## Error Handling

```javascript
// In browser interaction code, wrap with timeout and fallback:

async function safeClick(element) {
  // Strategy 1: Try ref if available
  if (element.ref) {
    try {
      await browser_click({ ref: element.ref, timeout: 5000 })
      return true
    } catch (error) {
      console.log(`⚠️ Ref click failed for ref ${element.ref}: ${error.message}`)
    }
  }

  // Strategy 2: Try semantic selector
  if (element.ariaLabel) {
    try {
      await browser_click({
        selector: `[aria-label="${element.ariaLabel}"]`,
        timeout: 5000
      })
      return true
    } catch (error) {
      console.log(`⚠️ Selector click failed: ${error.message}`)
    }
  }

  // Strategy 3: Try text-based selector
  if (element.name) {
    try {
      await browser_click({
        selector: `button:has-text("${element.name}")`,
        timeout: 5000
      })
      return true
    } catch (error) {
      console.log(`⚠️ Text-based click failed: ${error.message}`)
    }
  }

  console.log("❌ All click strategies failed for element")
  return false
}
```

## Best Practices

1. **Always check for modals** after navigation and before state exploration
2. **Prefer semantic selectors** over refs (more stable)
3. **Use multiple fallback strategies** - don't rely on a single method
4. **Document persistent modals** as features rather than treating them as bugs
5. **Verify dismissal** by taking a new snapshot after attempted dismissal
6. **Handle gracefully** - if modal can't be dismissed, document it and continue

## Example: Complete Modal Handling in Exploration

```javascript
async function explorePage(page_url) {
  // Navigate
  await browser_navigate({ url: page_url })

  // Handle modals
  let snapshot = await browser_snapshot()
  let attempts = 0
  const maxAttempts = 3

  while (attempts < maxAttempts) {
    const modals = findModals(snapshot)

    if (modals.length === 0) {
      break  // No modals, proceed
    }

    console.log(`⏺ Found ${modals.length} modal(s) - attempt ${attempts + 1}/${maxAttempts}`)

    const dismissed = await dismissModal(snapshot)

    if (dismissed) {
      // Refresh snapshot
      snapshot = await browser_snapshot()
      attempts++
    } else {
      console.log("⚠️ Modal persists - will document it")
      break
    }
  }

  // Continue with normal exploration flow
  // ...
}
```

---

*This guide ensures Ralph can handle modals robustly and continues exploration even when modals are persistent.*
