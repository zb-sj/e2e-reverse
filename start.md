---
description: "Start E2E reverse engineering session"
allowed-tools: Skill, Read, Write, Edit, Glob, Grep, ToolSearch
argument-hint: "[https://example.com] [--max-iterations 15]"
---

# E2E Reverse Engineering Session

**CRITICAL: Follow these steps IN ORDER before doing anything else:**

## Step 1: Check Config File (BLOCKING REQUIREMENT)

Read the config file at `.claude/e2e-reverse.config.md`.

**If the file does NOT exist:**

Display this error message to the user:

```
❌ PREREQUISITE FAILED: Configuration file not found

REQUIRED ACTION:
Run `/e2e-reverse setup` to configure your project first.

The setup process will ask you for:
• Base URL to explore
• Output directory for Gherkin specs
• Language preference (Korean/English)
• Device configurations (desktop/mobile/tablet)

Cannot proceed without configuration. Session stopped.
```

Then STOP execution immediately. Do NOT proceed with any other steps. Do NOT ask the user for manual input.

**If the file exists:**

- Parse the config to extract: ralph_loop_skill, base_url, output_dir, screenshot_dir, max_iterations, devices, etc.
- Validate config structure (required fields present, including `ralph_loop_skill`)
- If `ralph_loop_skill` field is missing, display error:
  ```text
  ❌ CONFIG ERROR: Missing ralph_loop_skill field

  Your config was created with an older version of e2e-reverse.

  REQUIRED ACTION:
  Run `/e2e-reverse setup` to update your configuration.

  This will detect the correct Ralph Loop skill name for your environment.
  ```
  Then STOP execution immediately.
- Continue to Step 2

## Step 2: Parse Command Arguments

Check if the user provided arguments:

- URL argument (e.g., `https://example.com`) - overrides base_url from config
- `--max-iterations N` - overrides max_iterations from config

## Step 3: Load Playwright MCP Tools (BLOCKING REQUIREMENT)

Use ToolSearch to load Playwright tools:

**CRITICAL**: Load ALL required tools before proceeding. Execute multiple ToolSearch calls:

1. Search for: "select:mcp__plugin_playwright_playwright__browser_navigate"
2. Search for: "select:mcp__plugin_playwright_playwright__browser_resize"
3. Search for: "select:mcp__plugin_playwright_playwright__browser_snapshot"
4. Search for: "select:mcp__plugin_playwright_playwright__browser_take_screenshot"
5. Search for: "select:mcp__plugin_playwright_playwright__browser_click"
6. Search for: "select:mcp__plugin_playwright_playwright__browser_type"
7. Search for: "select:mcp__plugin_playwright_playwright__browser_wait_for"
8. **Search for: "select:mcp__plugin_playwright_playwright__browser_run_code"** (Required for mobile emulation)

All 8 tools must be loaded successfully before continuing.

**If Playwright tools are NOT available:**

Display this error message to the user:

```
❌ PREREQUISITE FAILED: Playwright MCP server not found

REQUIRED ACTION:
Install Playwright MCP server to enable browser automation.

Installation instructions:
https://github.com/modelcontextprotocol/servers/tree/main/src/playwright

Once installed, restart Claude Code and try again.

Cannot proceed without Playwright. Session stopped.
```

Then STOP execution immediately.

## Step 4: Mobile Device Configuration (INFO ONLY)

If config includes mobile or tablet devices, silently note:
- Ralph will use **best-effort mobile emulation** (browser_run_code with addInitScript)
- Effectiveness: ~70-80% for most responsive sites
- Works for: JavaScript checks, CSS media queries, viewport sizing
- Limitations: HTTP User-Agent headers, true touch events (rare edge cases)

**Optional enhancement** (only mention if user reports mobile issues):
- Users can configure Playwright MCP with --device flag for 95%+ accuracy
- See setup.md Step 4 for instructions

**Default behavior**: Proceed with best-effort emulation. No user prompt needed.

## Step 5: Load Reference Documentation (BLOCKING REQUIREMENT)

**CRITICAL**: Read these files to provide Ralph with complete context before starting the session.

Ralph needs these files to operate correctly:

1. **Read** `references/REFERENCE.md` - Complete guide containing:
   - Gherkin conventions and syntax rules
   - Tag system (feature, priority, state, role, device tags)
   - State file structure and field definitions
   - Configuration file format

2. **Read** `references/FORMULAS.md` - Quality scoring algorithms:
   - Page selection weighted scoring (priority, coverage_gap, staleness, diversity)
   - Quality score calculations
   - Coverage gap formulas

3. **Read** `references/REPORTING.md` - Report templates for:
   - Status reports (progress, metrics)
   - Export reports (final documentation)
   - Validation reports (quality checks)

**Why this matters**: Without these files, Ralph won't know:
- How to write proper Gherkin with correct tags
- How to calculate quality scores and prioritize pages
- What structure the state file should have
- How to generate proper reports

These files are stored in the skill directory at `/Users/zigbang/.claude/skills/e2e-reverse/references/`.

## Step 5.5: Write Instructions File (CRITICAL FOR RALPH)

**BLOCKING REQUIREMENT**: Write all essential instructions to a project-local file so Ralph can access them in each iteration.

**Why this is necessary**: When Ralph Loop feeds the prompt back to Claude in iterations, Claude doesn't automatically have access to the skill's documentation files. By writing instructions to the project's `.claude` directory, Ralph can read them in each iteration.

**Action**: Use the Write tool to create `.claude/e2e-reverse-instructions.md` with the following content:

```markdown
# E2E Reverse Engineering - Ralph Instructions

**Read this file at the START of each iteration.**

## Skill Reference (COMPREHENSIVE CONTEXT)

For detailed instructions, read these files from the skill directory:

| File | Purpose | When to Read |
|------|---------|--------------|
| `{skill_dir}/start.md` | **Core Loop**, mobile emulation, error recovery, page selection | Every iteration |
| `{skill_dir}/references/REFERENCE.md` | Gherkin conventions, tag system, state file structure | First iteration |
| `{skill_dir}/references/FORMULAS.md` | Quality scoring algorithms | When calculating scores |
| `{skill_dir}/guides/GHERKIN-BEST-PRACTICES.md` | Background, Scenario Outline patterns | When writing features |
| `{skill_dir}/guides/BROWSER-EXAMPLES.md` | Playwright selector strategy, mobile emulation code | When interacting with browser |

**Skill directory**: `{skill_dir}`

## Quick Reference

### Prerequisites (Every Iteration)

1. **Load Playwright MCP tools** via ToolSearch:
   - browser_navigate, browser_resize, browser_snapshot, browser_take_screenshot
   - browser_click, browser_type, browser_wait_for, browser_run_code

2. **Read config**: `.claude/e2e-reverse.config.md`

3. **Read state**: `.claude/ralph-loop.local.md` for iteration count

### Core Loop Summary

1. NAVIGATE → 2. CAPTURE (all devices) → 3. EXPLORE states → 4. ANALYZE differences → 5. DOCUMENT Gherkin → 6. VALIDATE → 7. UPDATE state → 8. SELECT next page

**For detailed steps including mobile emulation code**: Read `{skill_dir}/start.md` section "Core Loop"

### Mobile Emulation (CRITICAL)

For mobile/tablet devices, use `browser_run_code` with `addInitScript` to inject:
- `navigator.userAgent` override
- `navigator.maxTouchPoints` = 5
- `navigator.platform` override

**Full code example**: Read `{skill_dir}/start.md` lines 199-218

### Completion

Output `<promise>E2E_COMPLETE</promise>` when max_iterations reached.
```

**Note**: Replace placeholders when writing:

- `{skill_dir}` → The actual skill directory path (shown below)
- Values from config: base_url, output_dir, screenshot_dir

**Skill directory path**: `/Users/zigbang/.claude/skills/e2e-reverse`

## Step 6: Start Ralph Loop

Once config is loaded, Playwright tools are available, mobile configuration is verified, and reference documentation is loaded, proceed with the session below.

---

## Mission

Reverse-engineer the app into Gherkin documentation so detailed that another AI agent could recreate the app from scratch.

## Quality Checklist

For each feature, document:

1. **Purpose** - What problem does this solve?
2. **Entry points** - How do users reach this?
3. **UI components** - What elements on screen?
4. **Interactions** - What can users do?
5. **States** - Empty, loading, error, success
6. **Validation** - Input rules, constraints
7. **Data flow** - What data, from where?
8. **Edge cases** - Boundaries, limits

## Core Loop (Performance Optimized)

1. **RESET** (if configured) - Clear browser state
   - Clear cookies/local storage (if session_management.reset_between_iterations: true)
   - Navigate to base_url (if session_management.reset_to_homepage: true)
   - Wait for page idle (session_management.wait_for_idle_after_reset ms)

2. **NAVIGATE** - `browser_navigate` to page (once per page)

3. **CAPTURE ALL DEVICES** - Collect device-specific data in batch

   **Mobile emulation approach**:

   **Default: Best-effort emulation (works out-of-box)**
   - Uses `browser_run_code` with `addInitScript` to override navigator properties
   - No MCP server configuration needed
   - Effectiveness: ~70-80% (sufficient for most responsive sites)
   - Works: JavaScript checks, CSS media queries, viewport sizing
   - Limitation: HTTP User-Agent headers (server-side detection) - rare edge case

   **Optional: Native device emulation (if MCP configured)**
   - If user has configured Playwright MCP with `--device "iPhone 13"` flag
   - Ralph will automatically detect and use native emulation instead
   - Effectiveness: ~95-100% (handles all edge cases)

   **Implementation**:

   For each device in config.devices:

   **Desktop devices:**
     - `browser_resize` to device dimensions (e.g., 1920x1080)
     - `browser_snapshot` → store as desktop_snapshot
     - `browser_take_screenshot` → screenshot_dir/{feature}/initial.desktop.png

   **Mobile/tablet devices (best-effort emulation):**
     - `browser_resize` to device dimensions FIRST (e.g., 390x844)
     - Set up route interception + init scripts + reload in one call:

       ```javascript
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

           // 2. Override JavaScript navigator properties
           await page.addInitScript(\\\`
             Object.defineProperty(navigator, 'userAgent', {
               get: () => '\${mobileUA}'
             });
             Object.defineProperty(navigator, 'maxTouchPoints', { get: () => 5 });
             Object.defineProperty(navigator, 'platform', { get: () => 'iPhone' });
           \\\`);

           // 3. Reload - route handler modifies HTTP headers, init script runs on load
           await page.reload({ waitUntil: 'networkidle' });
         }`
       })
       ```

     - `browser_snapshot` → store as mobile_snapshot (HTTP + JS both mobile now)
     - `browser_take_screenshot` → screenshot_dir/{feature}/initial.mobile.png

     **⚠️ Why both `page.route()` AND `addInitScript()`**: `page.route()` intercepts HTTP requests (server sees mobile UA), `addInitScript()` overrides JS properties (client-side code sees mobile UA). Both are needed.

   **What works with best-effort emulation:**
   - ✅ JavaScript checks (navigator.userAgent, maxTouchPoints, window.innerWidth)
   - ✅ CSS media queries and responsive layouts
   - ✅ Viewport-based rendering (resize triggers mobile layout)
   - ⚠️ Limitation: HTTP User-Agent header not set (affects ~5-10% of sites with server-side detection)

   **Screenshot Naming Convention**:
   - Format: `{feature}/{name}.{device}.png` or `{feature}/{name}.png` (device-agnostic)
   - Examples:
     - `search/initial.desktop.png` - Desktop initial state
     - `search/initial.mobile.png` - Mobile initial state
     - `search/loading.png` - Loading state (same across devices)
     - `search/error.desktop.png` - Desktop-specific error state

   Result: `{desktop: {snapshot, screenshot}, mobile: {snapshot, screenshot}, tablet: {snapshot, screenshot}}`

4. **EXPLORE STATES** (device-agnostic, done once)
   - Click interactive elements to discover states (loading, error, empty, etc.)
   - For each discovered state:
     - Capture state name (e.g., "loading", "error", "empty")
     - Determine if state differs across devices
     - For each device (or once if device-agnostic):
       - `browser_resize` to device
       - `browser_take_screenshot` → screenshot_dir/{feature}/{state}[.{device}].png

   **Examples**:
   - Loading state (same across devices) → `search/loading.png`
   - Error state with device differences:
     - Desktop: `search/error.desktop.png`
     - Mobile: `search/error.mobile.png`
   - Overlay (mobile-only) → `search/overlay.mobile.png`

5. **ANALYZE DEVICE DIFFERENCES**
   - Compare snapshots across devices to identify device-specific behaviors
   - Examples:
     - Desktop: dropdown appears inline
     - Mobile: full-screen overlay opens
   - Flag scenarios needing device-specific variants

6. **DOCUMENT ONCE** - Write Gherkin following these rules:
   - **One feature per file**: Create separate .feature files (e.g., search.feature, user-profile.feature)
   - **Check existing files**: Before creating, check if output_dir/{feature-name}.feature exists
   - **Update, don't overwrite**: If file exists, READ it first, then ADD new scenarios
   - **Preserve structure**: Keep existing scenarios, tags, and rules intact
   - **Naming convention**: Use kebab-case matching feature tag (e.g., @apartment-detail → apartment-detail.feature)
   - **Device tags**: Add @desktop/@mobile/@tablet where behavior differs; omit when identical
   - **Background for common setup** (DRY principle - 2026 best practice):
     - Detect repeated Given steps across 2+ scenarios in the same feature
     - Extract common preconditions into Background section
     - Place Background after Feature description, before first Rule
     - Example detection: If 3+ scenarios start with "Given user is logged in", extract to Background
     - See [guides/GHERKIN-BEST-PRACTICES.md](guides/GHERKIN-BEST-PRACTICES.md) lines 40-75 for examples
   - **Scenario Outline for data-driven tests** (reduces duplication - 2026 best practice):
     - Detect repetitive scenarios: 3+ scenarios with identical structure but different data
     - Convert to Scenario Outline with Examples table
     - Example detection: "Search Seoul", "Search Busan", "Search Incheon" → Scenario Outline
     - See [guides/GHERKIN-BEST-PRACTICES.md](guides/GHERKIN-BEST-PRACTICES.md) lines 77-108 for patterns

   **Background Detection Helper**:
   ```pseudocode
   function detectCommonPreconditions(scenarios) {
     // Count Given step occurrences
     givenStepCounts = {}
     for scenario in scenarios:
       for step in scenario.givenSteps:
         givenStepCounts[step] = (givenStepCounts[step] || 0) + 1

     // Find steps that appear in 2+ scenarios
     commonGivens = givenStepCounts.filter(count >= 2)

     if (commonGivens.length > 0):
       return {
         shouldUseBackground: true,
         steps: commonGivens.keys()
       }
     return { shouldUseBackground: false }
   }
   ```

   **Scenario Outline Detection Helper**:
   ```pseudocode
   function detectRepetitiveScenarios(scenarios) {
     // Group scenarios by structure (ignoring data values)
     scenarioGroups = groupByStructure(scenarios)

     for group in scenarioGroups:
       if (group.scenarios.length >= 3):
         // Extract varying data
         parameters = identifyVaryingData(group.scenarios)

         return {
           shouldUseOutline: true,
           scenarios: group.scenarios,
           parameters: parameters  // e.g., ["location", "area", "radius"]
         }

     return { shouldUseOutline: false }
   }
   ```

   Example output with Background:
   ```gherkin
   Feature: Property Browsing

   Background:
     Given user is logged in
     And user has searched for properties

   Scenario: View property details (all devices)
     When user selects first property
     Then property detail page appears

   Scenario: Save property to favorites
     When user marks property as favorite
     Then property is saved to favorites list
   ```

   Example output with Scenario Outline:
   ```gherkin
   Scenario Outline: Search by location keyword
     When user searches for "<location>"
     Then properties near <area> appear
     And results are within <radius> of search point

     Examples:
       | location | area              | radius |
       | 강남역   | Gangnam Station   | 500m   |
       | 해운대   | Haeundae Beach    | 1km    |
       | 송도     | Songdo City       | 2km    |
   ```

   Example output with device-specific scenarios:
   ```gherkin
   Scenario: View search results (all devices)
     When user performs search
     Then results list appears

   @mobile
   Scenario: Open search - mobile overlay
     When user taps search bar
     Then full-screen search overlay opens

   @desktop
   Scenario: Open search - desktop dropdown
     When user clicks search input
     Then dropdown autocomplete appears
   ```

7. **VALIDATE & REFLECT** - Self-check with quality trend analysis (2026 Reflection Pattern)

   **Validation** (inline quality check):
   - Call `/e2e-reverse _validate-gherkin` on the feature file just written
   - Check syntax, conventions, quality, coverage gaps
   - If issues found: self-correct immediately and re-write

   **Reflection** (learning from mistakes - NEW):
   - Compare current quality_score vs. previous iteration for this page
   - Calculate quality_delta (improvement or regression)
   - Analyze validation issues to identify patterns:
     - Repeated mistakes (e.g., always forgetting device tags)
     - Improvement trends (e.g., declarative steps getting better)
     - New issue types (e.g., first time seeing missing Background)

   **Reflection Notes** (add to state file):
   ```yaml
   reflection:
     - iteration: 2
       quality_score: 0.85
       quality_delta: +0.20  # improved from 0.65
       issues_found:
         - type: "missing-device-tag"
           severity: "high"
           fixed: true
       issues_prevented:
         - "imperative-steps"  # learned from previous iteration
       notes: "Improved device tagging. Now consistently using declarative style."
       learning: "Always check for device-specific UI before writing scenario"
   ```

   **Self-Correction Logic**:
   - If quality_delta < 0 (regression): Analyze what changed, revert to previous approach
   - If same issues repeat 3+ times: Flag for human review, add to "common mistakes" tracker
   - If quality_delta > 0.1: Note successful pattern, reinforce in future iterations

   **Quality Improvement Tracking**:
   - Track rolling average of quality_score across all pages
   - Identify pages with declining quality (needs revisit)
   - Celebrate improvements (quality_delta > 0.15)

   This enables Ralph's **autonomous learning and continuous improvement** - a key 2026 best practice for long-running agents.

8. **VERIFY** - Re-read spec, ask "Could I rebuild this?"

9. **UPDATE STATE** - Batched state writes (auto-checkpointing)
   - Update `.claude/ralph-loop.local.md` with:
     - quality_score (based on coverage)
     - coverage analysis (states/devices/roles covered vs missing)
     - scenario metadata
   - State written every N iterations (config: `performance.state_file_write_interval`)
   - Auto-checkpoint when page reaches target quality (config: `checkpoint_on_page_complete`)
   - Use `/e2e-reverse _write-checkpoint` utility for atomic writes

10. **REPEAT** - Select next page until complete

**Performance Impact**:
- Before: 3 devices × (1 nav + 1 snapshot + 1 screenshot + explore + document) = 15+ operations
- After: 1 nav + (3 resize/snapshot/screenshot) + 1 explore + 1 document = 8 operations
- **Reduction**: ~53% fewer operations baseline, more savings with state exploration

## Error Recovery (CRITICAL - 2026 Best Practice)

**Ralph MUST implement error handling for long-running sessions. Follow these patterns:**

### Navigation Failures (Step 2)

```pseudocode
try {
  browser_navigate(page_url, timeout: config.timeouts.page_load)
} catch (TimeoutError) {
  // Log error to state file
  state.visit_history[page_url].errors.push({
    type: "navigation_timeout",
    timestamp: now(),
    message: "Page load exceeded timeout"
  })

  // Recovery strategy
  if (retries < 3) {
    wait(2000 * retries)  // exponential backoff
    retry navigation
  } else {
    skip this page, mark as "failed", continue to next page
  }
} catch (NetworkError) {
  // Transient network issue
  if (retries < 5) {
    wait(1000)
    retry navigation
  } else {
    skip page, mark as "failed-network"
  }
}
```

### Playwright MCP Server Disconnection

```pseudocode
// Periodic health check (every 5 iterations)
if (iteration % 5 === 0) {
  try {
    // Lightweight operation to test connectivity
    browser_snapshot()
  } catch (MCPServerUnavailable) {
    // Server disconnected mid-session
    display_to_user("⚠️ Playwright MCP server disconnected. Please check connection.")

    // Attempt reconnection
    wait(5000)
    if (still_unavailable) {
      // Graceful session pause
      write_checkpoint()  // save progress
      display_to_user("Session paused. Run `/e2e-reverse start` to resume after reconnecting MCP.")
      exit_with_resume_state
    }
  }
}
```

### Screenshot/Snapshot Failures (Steps 3-4)

```pseudocode
try {
  browser_take_screenshot(path)
} catch (ScreenshotTimeout) {
  // Screenshot failed, but don't stop entire iteration
  log_warning("Screenshot failed for {device} - continuing")
  state.visit_history[page].warnings.push({
    type: "screenshot_failed",
    device: device_name,
    timestamp: now()
  })
  continue with next device  // skip this screenshot, proceed
}
```

### Interaction Failures (Step 4 - Explore States)

```pseudocode
try {
  browser_click(element_ref, timeout: config.timeouts.interaction)
  wait(config.timeouts.state_transition)  // wait for state change
  browser_snapshot()  // capture new state
} catch (ElementNotFound) {
  // Element disappeared (dynamic UI)
  log_info("Element no longer available - UI changed")
  continue to next element
} catch (ElementNotInteractable) {
  // Element covered by overlay or disabled
  log_info("Element not interactable - skipping")
  continue to next element
} catch (ClickTimeout) {
  // Click didn't complete
  if (retries < 2) {
    wait(1000)
    retry click
  } else {
    skip element, log as non-interactive
  }
}
```

### State File Write Failures (Step 9)

```pseudocode
try {
  write_checkpoint(state_data)
} catch (FileSystemError) {
  // Disk full, permissions issue
  log_critical("Cannot write state file - session at risk")

  // Attempt recovery
  try_alternate_location(".claude/e2e-reverse-backup.md")

  if (still_fails) {
    display_to_user("⚠️ Cannot save progress. Check disk space and permissions.")
    // Continue session but warn user of data loss risk
  }
}
```

### Validation Failures (Step 7)

```pseudocode
try {
  validation_result = call_validate_gherkin(feature_file)
} catch (ValidatorError) {
  // Validator itself failed (not validation issues)
  log_warning("Validator failed to run - skipping validation for this iteration")
  // Don't block iteration, continue without validation
  continue
}

if (validation_result.has_issues) {
  // Reflection: analyze issues and self-correct
  reflection_notes = analyze_validation_issues(validation_result)

  // Track improvement
  if (previous_quality_score > 0) {
    quality_delta = current_quality_score - previous_quality_score
    state.visit_history[page].reflection.push({
      iteration: current_iteration,
      issues_found: validation_result.issues,
      quality_delta: quality_delta,
      notes: reflection_notes
    })
  }

  // Self-correct and re-write
  if (validation_result.is_critical) {
    rewrite_feature_file_with_fixes()
    re_validate()
  }
}
```

### General Error Handling Pattern

**For EVERY browser operation, wrap in try-catch**:

1. **Fail fast for critical errors**: Navigation, MCP disconnection
2. **Retry with backoff**: Transient network issues, timeouts
3. **Skip and continue**: Non-critical failures (screenshot, single element)
4. **Log all errors**: Add to state file for post-session analysis
5. **Checkpoint on error**: Write state before potential crash

**Error Logging Schema** (add to state file):

```yaml
visit_history:
  /search:
    errors: []  # Critical errors that blocked iteration
    warnings: []  # Non-blocking issues
    retries: 0  # Number of retry attempts
    reflection:  # NEW: Track quality improvements
      - iteration: 2
        issues_found: ["missing-device-tag", "imperative-step"]
        quality_delta: +0.15
        notes: "Fixed device tagging, converted to declarative style"
```

**See also**: [guides/ERROR-RECOVERY.md](guides/ERROR-RECOVERY.md) for comprehensive recovery strategies.

## File Management Strategy

**CRITICAL**: Multiple feature files, not one monolithic file!

1. **Identify feature scope**:
   - What's the logical feature? (e.g., "Search", "User Profile", "Apartment Detail")
   - One feature = one .feature file

2. **File naming**:
   - Use kebab-case matching the feature tag
   - Examples: `@search` → `search.feature`, `@user-profile` → `user-profile.feature`

3. **Before writing**:

   ```pseudocode
   IF file exists at output_dir/{feature-name}.feature:
     READ existing file completely
     APPEND new scenarios to appropriate Rule sections
     PRESERVE all existing content
   ELSE:
     CREATE new file with Feature header
   ```

4. **Updating existing files**:
   - Add scenarios to existing Rules when relevant
   - Create new Rules for different aspects
   - Never delete existing scenarios
   - Maintain consistent tag structure

## Playwright MCP Tools

- `browser_navigate` - Go to URL
- `browser_resize` - Set viewport per device
- `browser_snapshot` - Read UI elements (preferred over screenshot for understanding)
- `browser_click` - Click element by ref or selector
- `browser_type` - Enter text in input
- `browser_take_screenshot` - Capture visual state

## Tag System

Use tags to categorize scenarios by feature, priority, state, role, and device.

**Common tags**:
- **Feature**: `@search`, `@user-profile`, `@checkout`
- **Priority**: `@smoke`, `@regression`, `@edge-case`
- **State**: `@happy-path`, `@empty-state`, `@loading`, `@error`
- **Role**: `@role(anonymous)`, `@role(user)`, `@role(admin)`
- **Device**: `@desktop`, `@mobile`, `@tablet`
- **Route**: `@route(/path)` (optional)

**Complete documentation**: See [REFERENCE.md - Tag System](references/REFERENCE.md#tag-categories) for:
- Full tag reference and usage rules
- When to use `@route()` tags
- Tag scope (feature-level vs scenario-level)
- Role tag examples and patterns

## Gherkin Structure

Write scenarios using Feature → Rule → Scenario hierarchy with proper tags.

**Basic structure**:
```gherkin
@feature-name @role(user)
Feature: Feature Name

  Rule: Logical Grouping
    Scenario: Specific test case
      Given precondition
      When action
      Then expected result
```

**Complete documentation**: See [REFERENCE.md - Gherkin Conventions](references/REFERENCE.md#gherkin-conventions) for:
- Feature structure with examples
- Step conventions (Given/When/Then)
- Device-specific scenario patterns
- Tag scope and inheritance rules

## Page Selection Strategy

**Smart Weighted Selection with Randomness**

Uses intelligent scoring (70%) + randomness (30%) to balance optimal coverage with exploration diversity.

### Score Calculation

For each page, calculate:

```javascript
weighted_score = (priority × 0.3) + (coverage_gap × 0.3) + (staleness × 0.2) + (diversity × 0.2)
random_factor = random(0, 0.3)
final_score = weighted_score + random_factor
```

### Scoring Factors

1. **Priority (0-1)**: Page importance
   - `critical` (1.0) - Login, search, checkout, main flows
   - `high` (0.75) - Key features, user profiles
   - `medium` (0.5) - Secondary features
   - `low` (0.25) - Utility pages, settings

2. **Coverage Gap (0-1)**: Missing scenario types
   - Calculate: `1 - (states_covered + devices_covered + roles_covered) / (total_expected)`
   - High score = many gaps → prioritize revisit
   - Example: Missing @error, @loading, @mobile → score 0.8

3. **Staleness (0-1)**: Time + quality decay
   - Calculate: `(days_since_visit / stale_days) × (1 - quality_score)`
   - High score = old + low quality → needs revisit
   - Example: 5 days old, quality 0.6 → score 0.57

4. **Diversity (0-1)**: Scenario variety
   - Calculate: `1 - (unique_scenario_types / expected_types)`
   - High score = repetitive scenarios → needs variety
   - Example: Only @happy-path scenarios → score 0.8

**Selection Process**:

1. **Separate pools**:
   - Undocumented pages (status: `pending`)
   - Documented pages (status: `documented`, `in-progress`)

2. **Calculate scores** for all pages (no exclusions - pages evolve!)

3. **Apply ratio** (config.iteration.new_discovery_ratio):
   - Roll dice: if < ratio → pick highest scored undocumented page
   - Otherwise → pick highest scored documented page

4. **Fallback logic**:
   - If selected pool empty, use the other pool
   - If max_iterations reached, session done

**Page Status Lifecycle**:

- `pending` - Discovered, not yet documented
- `documented` - Has feature file (can always be revisited - quality_score indicates coverage depth)
- `in-progress` - Currently being documented (this iteration)

**Note**: No "complete" status - pages evolve, new edge cases emerge. Quality scores indicate coverage depth, not finality.

## State Tracking

Ralph tracks progress in `.claude/ralph-loop.local.md` with:

**Key fields**:
- `status`: running | paused | stopped | completed
- `iteration`: current iteration number
- `visit_history`: detailed per-page tracking
  - visit_count, last_visited, status (pending/documented/in-progress)
  - priority (critical/high/medium/low), page_type (entry-point/feature/utility)
  - scenarios metadata with tags and timestamps
  - coverage analysis (states/devices/roles covered vs missing)
  - quality_score, scenario_diversity, coverage_gap_score

**Complete documentation**: See [REFERENCE.md - State File Reference](references/REFERENCE.md#state-file-reference) for:
- Full state file structure with examples
- Field definitions and data types
- Quality metric calculations
- Page status lifecycle

## Completion Criteria

Output `<promise>E2E_COMPLETE</promise>` when max_iterations reached or user manually stops.

**Quality Indicators** (not completion gates):

- Pages documented: Track how many pages have feature files
- Average quality_score: Indicates overall coverage depth
- Coverage gaps: Pages with low quality_score need attention
- Scenario diversity: Variety of test types across the app

**Note**: Testing is never truly "complete" - use quality metrics to decide when sufficient coverage is reached for current goals.

## Start Session

**You have already loaded the config in Step 1.** Now use those values to start the session:

1. **Extract values** from the config you loaded in Step 1:
   - `ralph_loop_skill` (the resolved skill name from setup)
   - `base_url` (or use URL override from command arguments if provided)
   - `output_dir`
   - `max_iterations` (or use override from `--max-iterations` argument if provided)

2. **Substitute placeholders** in the command below with the actual values:
   - Replace `{ralph_loop_skill}` with the actual ralph_loop_skill value
   - Replace `{base_url}` with the actual base_url
   - Replace `{output_dir}` with the actual output_dir
   - Replace `{max_iterations}` with the actual max_iterations

3. **Execute the Ralph Loop skill** using the Skill tool with the resolved skill name:

Use the Skill tool with:
- skill: `{ralph_loop_skill}` (e.g., "ralph-loop:ralph-loop")
- args: `"FIRST: Read .claude/e2e-reverse-instructions.md for complete instructions. E2E reverse engineering session. Target: {base_url}. Output: {output_dir}." --max-iterations {max_iterations} --completion-promise "E2E_COMPLETE"`

**Example** (if ralph_loop_skill=`ralph-loop:ralph-loop`, base_url=`https://example.com`, output_dir=`e2e/features`, max_iterations=`15`):

```text
Skill tool with:
- skill: "ralph-loop:ralph-loop"
- args: "FIRST: Read .claude/e2e-reverse-instructions.md for complete instructions. E2E reverse engineering session. Target: https://example.com. Output: e2e/features." --max-iterations 15 --completion-promise "E2E_COMPLETE"
```
