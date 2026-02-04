# Error Recovery Guide

How Ralph handles errors and recovers from common issues during reverse engineering.

## Philosophy

Ralph is designed to be resilient. When errors occur, Ralph should:
1. **Detect** the issue through error messages or validation failures
2. **Analyze** the root cause
3. **Recover** by adjusting strategy or retrying with different approach
4. **Document** the limitation if recovery isn't possible
5. **Continue** exploring other pages

## Common Errors and Recovery Strategies

### 1. Browser Errors

#### Page Load Timeout

**Symptom**:
```
Error: Navigation timeout exceeded (30000ms)
```

**Causes**:
- Slow network
- Large JavaScript bundles
- Blocked by server
- Infinite loading spinner

**Recovery**:
```javascript
try {
  await browser_navigate({url: page_url})
} catch (error) {
  if (error.message.includes("timeout")) {
    // Strategy 1: Retry with longer timeout
    try {
      await browser_navigate({
        url: page_url,
        timeout: 60000  // 60 seconds
      })
    } catch (retryError) {
      // Strategy 2: Skip this page, mark as problematic
      console.log(`Page ${page_url} consistently times out - skipping`)

      // Update state: mark page as "timeout" status
      state.visit_history[page_url] = {
        status: "timeout",
        last_attempt: new Date().toISOString(),
        error: "Page load timeout",
        recommendation: "Manually verify page accessibility"
      }

      // Continue to next page
      return selectNextPage(state)
    }
  }
}
```

**Prevention**:
- Increase `timeouts.page_load` in config for known slow pages
- Add slow pages to `ignore_paths`

#### Element Not Found

**Symptom**:
```
Error: Element not found: button[aria-label='검색']
```

**Causes**:
- Element doesn't exist on this page
- Element rendered asynchronously (still loading)
- Dynamic class names changed
- Incorrect selector

**Recovery**:
```javascript
try {
  await browser_click({selector: "button[aria-label='검색']"})
} catch (error) {
  if (error.message.includes("not found")) {
    // Strategy 1: Wait and retry
    try {
      await browser_wait_for({
        selector: "button[aria-label='검색']",
        timeout: 5000
      })
      await browser_click({selector: "button[aria-label='검색']"})
    } catch (waitError) {
      // Strategy 2: Try alternative selectors
      const alternativeSelectors = [
        "button:has-text('검색')",
        "[data-testid='search-button']",
        ".search-button"
      ]

      for (const selector of alternativeSelectors) {
        try {
          await browser_click({selector})
          console.log(`Found element using alternative selector: ${selector}`)
          break
        } catch {
          continue
        }
      }

      // Strategy 3: Use snapshot ref instead
      const snapshot = await browser_snapshot()
      const searchButton = findElement(snapshot, {role: "button", name: "검색"})

      if (searchButton && searchButton.ref) {
        await browser_click({ref: searchButton.ref})
      } else {
        // Strategy 4: Skip this interaction, document limitation
        console.log("Search button not found - documenting limited scenario")

        // Write scenario without this step
        // Add note to feature file about limitation
      }
    }
  }
}
```

**Prevention**:
- Prefer using `ref` from snapshots over selectors
- Always take snapshot first, then use refs for interactions

#### Snapshot Timeout

**Symptom**:
```
Error: Timeout while capturing accessibility tree
```

**Causes**:
- Page has extremely deep DOM tree
- Accessibility tree calculation is expensive
- Page still loading/rendering

**Recovery**:
```javascript
try {
  const snapshot = await browser_snapshot()
} catch (error) {
  if (error.message.includes("timeout")) {
    // Strategy 1: Wait for page to settle
    await wait(3000)

    try {
      const snapshot = await browser_snapshot()
    } catch (retryError) {
      // Strategy 2: Use screenshot-only approach
      console.log("Snapshot unavailable - using screenshot-only documentation")

      await browser_take_screenshot()
      // Document visual elements from screenshot description
      // Skip detailed interaction documentation

      // Write basic scenario based on URL and visual observation
      const basicScenario = `
Scenario: View ${page_name} page
  Given user navigates to ${page_url}
  Then page loads successfully
  # Note: Detailed interactions not documented due to snapshot limitations
`
    }
  }
}
```

### 2. Validation Errors

#### Gherkin Syntax Error

**Symptom**:
```javascript
validation = {
  valid: false,
  errors: [{
    type: "syntax",
    line: 15,
    message: "Invalid step keyword",
    auto_fixable: false
  }]
}
```

**Recovery**:
```javascript
// Call validate after writing feature file
const validation = await validate_gherkin({
  feature_file_path: feature_path,
  config: config,
  state: state
})

if (!validation.valid) {
  // Group errors by auto-fixable
  const autoFixable = validation.errors.filter(e => e.auto_fixable)
  const manualFix = validation.errors.filter(e => !e.auto_fixable)

  // Auto-fix what we can
  for (const error of autoFixable) {
    await applyAutoFix(feature_path, error)
  }

  // For manual fixes, re-write affected scenarios
  for (const error of manualFix) {
    console.log(`Validation error: ${error.message}`)
    console.log(`Suggestion: ${error.suggestion}`)

    // Re-read feature file
    const content = await readFile(feature_path)

    // Identify problematic scenario
    const lines = content.split('\n')
    const problematicLine = lines[error.line - 1]

    // Rewrite based on suggestion
    if (error.type === "convention") {
      // Add missing tag
      if (error.message.includes("missing feature-name tag")) {
        const featureTag = inferFeatureTag(feature_path)
        lines[0] = `@${featureTag}\n` + lines[0]
      }
    }

    // Write corrected content
    await writeFile(feature_path, lines.join('\n'))
  }

  // Re-validate
  const revalidation = await validate_gherkin({
    feature_file_path: feature_path,
    config: config,
    state: state
  })

  if (!revalidation.valid) {
    console.log("Still has validation errors after fixes:")
    revalidation.errors.forEach(e => console.log(`- ${e.message}`))

    // Mark feature as "needs-review" in state
    state.visit_history[page_url].quality_issues = revalidation.errors
  }
}
```

#### Coverage Gap Warnings

**Symptom**:
```javascript
validation = {
  valid: true,
  warnings: [{
    type: "coverage",
    message: "Missing error state scenarios",
    suggestion: "Add scenarios for network errors, validation errors, etc."
  }]
}
```

**Recovery**:
```javascript
// Coverage warnings don't block progress, but inform next iteration

const warnings = validation.warnings.filter(w => w.type === "coverage")

// Update state with coverage gaps for next visit
state.visit_history[page_url].coverage_gaps = warnings.map(w => ({
  missing: extractMissingType(w.message),  // "error", "empty-state", etc.
  priority: determinePriority(w),
  suggestion: w.suggestion
}))

// Adjust page's selection score based on gaps
state.visit_history[page_url].coverage_gap_score = calculateCoverageGap(
  state.visit_history[page_url],
  config.coverage_templates[state.visit_history[page_url].page_type]
)

// Page will be prioritized for revisit in future iteration
```

### 3. State File Corruption

#### State File Parse Error

**Symptom**:
```
Error: Invalid YAML in .claude/ralph-loop.local.md
```

**Causes**:
- File edited manually with syntax error
- Write interrupted mid-operation
- Disk full or permissions issue

**Recovery**:
```javascript
try {
  const state = await loadState('.claude/ralph-loop.local.md')
} catch (error) {
  if (error.message.includes("Invalid YAML")) {
    // Strategy 1: Check for checkpoint backup
    try {
      const checkpoint = await loadState('.claude/e2e-reverse-checkpoint.md')
      console.log("State file corrupted - restoring from checkpoint")
      await writeFile('.claude/ralph-loop.local.md', checkpoint)
      return checkpoint
    } catch (checkpointError) {
      // Strategy 2: Restore from temp file
      try {
        const tempState = await loadState('.claude/ralph-loop.local.md.tmp')
        console.log("Restoring from temporary state file")
        await writeFile('.claude/ralph-loop.local.md', tempState)
        return tempState
      } catch (tempError) {
        // Strategy 3: Start fresh with config
        console.log("Cannot recover state - starting new session")

        const freshState = {
          status: "running",
          iteration: 0,
          max_iterations: config.max_iterations,
          started_at: new Date().toISOString(),
          coverage: {
            pages_discovered: 0,
            pages_documented: 0,
            scenarios_total: 0,
            avg_quality_score: 0
          },
          visit_history: {}
        }

        await writeState(freshState)
        return freshState
      }
    }
  }
}
```

**Prevention**:
- Use atomic writes (write to `.tmp`, then rename)
- Write checkpoint before risky operations
- Implement `_write-checkpoint` utility properly

#### State File Missing

**Symptom**:
```
Error: File not found: .claude/ralph-loop.local.md
```

**Recovery**:
```javascript
try {
  const state = await loadState('.claude/ralph-loop.local.md')
} catch (error) {
  if (error.code === 'ENOENT') {
    console.log("No existing session found - starting new session")

    const newState = initializeState(config)
    await writeState(newState)
    return newState
  }
}
```

### 4. Quality Issues

#### Quality Score Below Target

**Symptom**:
```javascript
page.quality_score = 0.42  // Below target of 0.75
```

**Recovery**:
```javascript
// This is expected during early iterations
// Use quality score to prioritize revisit

if (page.quality_score < config.quality.target_quality_score) {
  // Calculate what's missing
  const template = config.coverage_templates[page.page_type]

  const missing = {
    states: template.expected_states.filter(
      s => !page.coverage.states_covered.includes(s)
    ),
    devices: template.expected_devices.filter(
      d => !page.coverage.devices_covered.includes(d)
    ),
    roles: template.expected_roles.filter(
      r => !page.coverage.roles_covered.includes(r)
    )
  }

  // Plan next visit focus
  page.next_visit_focus = {
    priority_states: missing.states.filter(s =>
      standard_states[s].priority === 'critical'
    ),
    priority_devices: missing.devices.filter(d =>
      template.device_expectations[d] === 'required'
    ),
    priority_roles: missing.roles
  }

  // Update selection score to prioritize this page
  page.staleness_score = calculateStaleness(page)
  page.coverage_gap_score = calculateCoverageGap(page, template)

  console.log(`Page ${page.url} below quality target - will revisit to add ${missing.states.length} states, ${missing.devices.length} devices, ${missing.roles.length} roles`)
}
```

#### Duplicate Scenarios

**Symptom**:
```javascript
validation.warnings = [{
  type: "quality",
  message: "Duplicate scenario name: 'Search by location'",
  suggestion: "Make scenario names unique or use device tags"
}]
```

**Recovery**:
```javascript
// Read existing feature file
const content = await readFile(feature_path)
const scenarios = parseScenarios(content)

// Find duplicates
const names = scenarios.map(s => s.name)
const duplicates = names.filter((name, index) => names.indexOf(name) !== index)

// Rename duplicates with device or state suffix
for (const dupName of duplicates) {
  const instances = scenarios.filter(s => s.name === dupName)

  instances.forEach((scenario, index) => {
    if (index === 0) return // Keep first instance unchanged

    // Determine suffix from tags or context
    const deviceTag = scenario.tags.find(t => ['@desktop', '@mobile', '@tablet'].includes(t))
    const stateTag = scenario.tags.find(t => ['@error', '@loading', '@empty-state'].includes(t))

    const suffix = deviceTag ? deviceTag.slice(1) :
                   stateTag ? stateTag.slice(1) :
                   `variant-${index + 1}`

    scenario.name = `${dupName} (${suffix})`
  })
}

// Rewrite file with unique names
const updated = generateGherkin(scenarios)
await writeFile(feature_path, updated)
```

### 5. Network and API Errors

#### Network Offline

**Symptom**:
```
Error: Network error: ERR_INTERNET_DISCONNECTED
```

**Recovery**:
```javascript
try {
  await browser_navigate({url: page_url})
} catch (error) {
  if (error.message.includes("INTERNET_DISCONNECTED")) {
    console.log("Network is offline - cannot continue exploration")

    // Pause session
    state.status = "paused"
    state.paused_at = new Date().toISOString()
    state.pause_reason = "Network offline"

    await writeCheckpoint(state, "Session paused due to network issue")

    // Tell user
    console.log("Session paused. Run /e2e-reverse start to resume when network is restored.")

    // Exit Ralph loop
    return "<promise>E2E_PAUSED</promise>"
  }
}
```

#### Rate Limiting

**Symptom**:
```
Error: HTTP 429 Too Many Requests
```

**Recovery**:
```javascript
try {
  await browser_navigate({url: page_url})
} catch (error) {
  if (error.message.includes("429") || error.message.includes("rate limit")) {
    console.log("Rate limited - implementing exponential backoff")

    let delay = 5000  // Start with 5 seconds
    let attempts = 0
    const maxAttempts = 3

    while (attempts < maxAttempts) {
      await wait(delay)

      try {
        await browser_navigate({url: page_url})
        console.log(`Successfully navigated after ${attempts + 1} attempts`)
        break
      } catch (retryError) {
        attempts++
        delay *= 2  // Exponential backoff

        if (attempts >= maxAttempts) {
          console.log("Rate limit persists - pausing session for 5 minutes")

          await writeCheckpoint(state, "Session paused due to rate limiting")
          await wait(5 * 60 * 1000)  // Wait 5 minutes

          // Resume with slower pace
          config.iteration.pace = "slow"  // Add delays between pages
        }
      }
    }
  }
}
```

### 6. Checkpoint and Resume Errors

#### Checkpoint Detection Failure

**Symptom**:
Ralph doesn't detect existing checkpoint and starts from scratch

**Recovery**:
```javascript
// In start.md, explicit checkpoint detection
async function detectCheckpoint() {
  // Check for state file
  try {
    const state = await loadState('.claude/ralph-loop.local.md')

    if (state.status === "paused" || state.iteration > 0) {
      console.log(`Found existing session at iteration ${state.iteration}/${state.max_iterations}`)
      console.log(`Last visited: ${state.visit_history[Object.keys(state.visit_history).pop()]?.last_visited}`)

      // Ask user if they want to resume or start fresh
      const resume = await askUser("Resume from checkpoint? (yes/no)")

      if (resume === "yes") {
        state.status = "running"
        state.paused_at = null
        return state
      } else {
        console.log("Starting fresh session")
        return initializeState(config)
      }
    }
  } catch (error) {
    // No checkpoint found, start fresh
    return initializeState(config)
  }
}
```

### 7. Device-Specific Errors

#### Screenshot Failure on Mobile Device

**Symptom**:
```
Error: Screenshot failed on mobile viewport
```

**Recovery**:
```javascript
for (const device of devices) {
  try {
    await browser_resize({width: device.width, height: device.height})
    await browser_take_screenshot()
  } catch (error) {
    if (error.message.includes("screenshot failed")) {
      console.log(`Screenshot failed on ${device.name} - skipping`)

      // Document without screenshot
      deviceData[device.name] = {
        snapshot: await browser_snapshot(),
        screenshot: null,
        error: "Screenshot capture failed"
      }

      // Add note to scenario
      // "Note: Visual documentation unavailable for mobile device"
    }
  }
}
```

## Error Logging Strategy

Ralph should maintain an error log for debugging:

```javascript
// Add to state file
state.errors = state.errors || []

function logError(error, context) {
  state.errors.push({
    timestamp: new Date().toISOString(),
    iteration: state.iteration,
    page: context.page_url,
    error_type: error.name,
    error_message: error.message,
    recovery_attempted: context.recovery_strategy,
    recovery_successful: context.recovery_success
  })

  // Keep only last 50 errors
  if (state.errors.length > 50) {
    state.errors = state.errors.slice(-50)
  }
}

// Usage
try {
  await browser_navigate({url: page_url})
} catch (error) {
  const recovery = attemptRecovery(error)

  logError(error, {
    page_url: page_url,
    recovery_strategy: recovery.strategy,
    recovery_success: recovery.success
  })
}
```

## When to Give Up

Ralph should stop attempting recovery and pause the session when:

1. **Repeated failures**: Same error occurs 3+ times for same page
2. **Unrecoverable errors**: Disk full, permissions denied, etc.
3. **User intervention needed**: Auth expired, CAPTCHA required
4. **Safety limit**: Error rate > 50% across multiple pages

```javascript
// Track error rate
const recentErrors = state.errors.filter(e =>
  Date.now() - new Date(e.timestamp).getTime() < 5 * 60 * 1000  // Last 5 minutes
)

if (recentErrors.length > 10) {
  console.log("High error rate detected - pausing session for investigation")

  state.status = "paused"
  state.pause_reason = "High error rate"

  await writeCheckpoint(state, "Session paused due to repeated errors")

  console.log("Error summary:")
  recentErrors.forEach(e => {
    console.log(`- ${e.error_type}: ${e.error_message}`)
  })

  console.log("\nPlease investigate errors and run /e2e-reverse start to resume")

  return "<promise>E2E_PAUSED</promise>"
}
```

## Summary

Ralph's error recovery follows these principles:

1. **Retry with variations** (longer timeouts, alternative selectors, different strategies)
2. **Degrade gracefully** (skip features if unavailable, document limitations)
3. **Preserve progress** (checkpoint before risky operations)
4. **Learn from errors** (log patterns, adjust strategy)
5. **Know when to pause** (high error rates, unrecoverable issues)

The goal is to maximize coverage while being resilient to common web app quirks and network issues.

---

*For implementation details, see utility files in `scripts/` directory.*
