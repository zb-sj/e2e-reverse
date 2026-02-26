---
description: "Start E2E reverse engineering session"
allowed-tools: Skill, Read, Write, Edit, Glob, Grep, ToolSearch
argument-hint: "[https://example.com] [--max-iterations 15]"
---

# E2E Reverse Engineering Session

**CRITICAL: Follow these steps IN ORDER before doing anything else:**

## Table of Contents

- [Step 1: Check Config File](#step-1-check-config-file-blocking-requirement)
- [Step 2: Parse Command Arguments](#step-2-parse-command-arguments)
- [Step 3: Load Playwright MCP Tools](#step-3-load-playwright-mcp-tools-blocking-requirement)
- [Step 4: Mobile Device Configuration](#step-4-mobile-device-configuration-info-only)
- [Step 5: Load Reference Documentation](#step-5-load-reference-documentation-blocking-requirement)
- [Step 6: Start Ralph Loop](#step-6-start-ralph-loop)
- [Error Recovery](#error-recovery)
- [File Management Strategy](#file-management-strategy)
- [Completion Criteria](#completion-criteria)

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

Mobile/tablet devices use `browser_run_code` for UA + navigator override. See [references/BROWSER-EXAMPLES.md](references/BROWSER-EXAMPLES.md) "Mobile View - Option B" for the full code. Desktop uses `browser_resize` only.

**Default behavior**: Proceed with best-effort emulation (~70-80% effective). No user prompt needed.

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
| `{skill_dir}/references/GHERKIN-BEST-PRACTICES.md` | Background, Scenario Outline patterns | When writing features |
| `{skill_dir}/references/BROWSER-EXAMPLES.md` | Playwright selector strategy, mobile emulation code | When interacting with browser |

**Skill directory**: `{skill_dir}`

## Quick Reference

### Prerequisites (Every Iteration)

1. **Load Playwright MCP tools** via ToolSearch:
   - browser_navigate, browser_resize, browser_snapshot, browser_take_screenshot
   - browser_click, browser_type, browser_wait_for, browser_run_code

2. **Read config**: `.claude/e2e-reverse.config.md`

3. **Read state**: `.claude/ralph-loop.local.md` for iteration count

### Core Loop Summary

1. NAVIGATE → 2. CAPTURE (desktop first, then mobile) → 3. EXPLORE states → 4. DOCUMENT Gherkin → 5. UPDATE state → 6. SELECT next page → **IMMEDIATELY CONTINUE**

**⚠️ CRITICAL: DO NOT PAUSE BETWEEN ITERATIONS**
- After step 6, immediately start the next iteration
- NEVER output "I will continue..." and stop
- Continue until max_iterations reached

**For detailed steps including mobile emulation code**: Read `{skill_dir}/start.md` section "Core Loop"

### Mobile Emulation (CRITICAL)

For mobile/tablet devices, use `browser_run_code` with route interception + addInitScript.

**Full code**: Read `{skill_dir}/references/BROWSER-EXAMPLES.md` section "Mobile View - Option B"

**Capture order**: Desktop devices first → Mobile/tablet with emulation → `browser_close()` to reset

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

## Core Loop

For each iteration, execute these 6 steps sequentially:

### 1. NAVIGATE

`browser_navigate` to the target page URL.

If configured, clear browser state first:
- Clear cookies/local storage (if session_management.reset_between_iterations: true)
- Navigate to base_url (if session_management.reset_to_homepage: true)

### 2. CAPTURE — Screenshot all devices

**Before screenshots, create directory:**

```bash
mkdir -p {screenshot_dir}/{feature}/
```

**Phase A: Desktop devices**

For each desktop device in config.devices:
- `browser_resize` to dimensions (e.g., 1280x800)
- `browser_snapshot` → store as {device}_snapshot
- `browser_take_screenshot` → `{screenshot_dir}/{feature}/initial.{device}.png`

**Phase B: Mobile/tablet devices (with emulation)**

For each mobile/tablet device:
1. `browser_resize` to device dimensions FIRST (e.g., 390x844)
2. Apply mobile emulation via `browser_run_code`:
   - `page.route('**/*')` to override HTTP User-Agent header
   - `page.addInitScript()` to override navigator.userAgent, maxTouchPoints, platform
   - `page.reload({ waitUntil: 'networkidle' })`
3. **Full code**: See [references/BROWSER-EXAMPLES.md](references/BROWSER-EXAMPLES.md) "Mobile View - Option B"
4. `browser_snapshot` → store as {device}_snapshot
5. `browser_take_screenshot` → `{screenshot_dir}/{feature}/initial.{device}.png`

**Phase C: Reset to desktop**

After all mobile captures:
1. `browser_close()` (clears all stacked init scripts and route handlers)
2. `browser_navigate` to same URL (fresh browser, no emulation residue)
3. `browser_resize` to desktop dimensions

**Screenshot naming**: `{feature}/{state}.{device}.png`
- Examples: `search/initial.desktop.png`, `search/initial.mobile.png`, `search/loading.png`

### 3. EXPLORE — Discover states

Done once on desktop (device-agnostic exploration):
- Click interactive elements to discover states (loading, error, empty, etc.)
- For each discovered state:
  - Capture snapshot and screenshot
  - Note if state differs across devices
  - Use naming: `{feature}/{state}.png` (device-agnostic) or `{feature}/{state}.{device}.png`

Compare desktop vs mobile snapshots to identify device-specific behaviors:
- Desktop: dropdown appears inline → Mobile: full-screen overlay opens
- Flag scenarios needing device-specific variants with `@desktop`/`@mobile` tags

### 4. DOCUMENT — Write Gherkin

**Rules:**
- **One feature per file**: Create separate .feature files (e.g., search.feature, user-profile.feature)
- **Check existing files**: Before creating, check if output_dir/{feature-name}.feature exists
- **Update, don't overwrite**: If file exists, READ it first, then ADD new scenarios
- **Preserve structure**: Keep existing scenarios, tags, and rules intact
- **Naming convention**: Use kebab-case matching feature tag (e.g., @apartment-detail → apartment-detail.feature)
- **Device tags**: Add @desktop/@mobile/@tablet where behavior differs; omit when identical
- **Background for common setup**: Detect repeated Given steps across 2+ scenarios, extract to Background. See [references/GHERKIN-BEST-PRACTICES.md](references/GHERKIN-BEST-PRACTICES.md) for examples
- **Scenario Outline for data-driven tests**: Detect 3+ scenarios with identical structure but different data, convert to Scenario Outline. See [references/GHERKIN-BEST-PRACTICES.md](references/GHERKIN-BEST-PRACTICES.md) for patterns

**After writing, count scenarios accurately:**

```bash
grep -c "Scenario:" {output_dir}/{feature-name}.feature
```

Store this as `scenario_count` in state.

**Example output:**

```gherkin
@search @route(/search) @role(anonymous)
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

  @mobile
  Rule: Mobile Search Experience
    Scenario: Search overlay
      When user opens search
      Then full-screen search overlay opens

  @empty-state @regression
  Rule: No Results Handling
    Scenario: Search with no matches
      When user searches for non-existent location
      Then empty state message appears
```

### 5. UPDATE — Write state file

Write the full state to `.claude/ralph-loop.local.md` using the Write tool.

**Key fields to update:**
- `iteration`: increment
- `status`: running
- `visit_history`: update page entry with visit_count, last_visited, status, coverage, scenario_count
- `coverage.pages_discovered`, `coverage.pages_documented`, `coverage.scenarios_total`

**Use `scenario_count` from grep** — do not manually count scenarios.

### 6. SELECT — Pick next page and continue

Use weighted scoring to select the next page:

```
final_score = (priority × 0.3) + (coverage_gap × 0.3) + (staleness × 0.2) + (diversity × 0.2) + random(0, 0.3)
```

See [references/FORMULAS.md](references/FORMULAS.md) for full calculation details.

**Immediately start the next iteration.** Do not pause, do not summarize, do not wait for user input.

## Continuous Execution (DO NOT PAUSE)

**Ralph MUST continue iterating without stopping.** These rules are non-negotiable:

1. **MUST** immediately proceed to the next page after updating state
2. **MUST** start the next iteration without any pause or summary
3. **NEVER** output "I will continue in the next iteration" and stop
4. **NEVER** wait for user input between iterations
5. **NEVER** end the turn with a summary of what was done

```pseudocode
while (current_iteration <= max_iterations) {
  navigate_to_page()
  capture_all_devices()    // desktop first, then mobile, then reset
  explore_states()
  document_gherkin()
  update_state()

  next_page = select_next_page_by_score()
  current_iteration++
  // DO NOT STOP — immediately continue the loop
}

output("<promise>E2E_COMPLETE</promise>")
```

**Why this matters**: If Ralph outputs a summary and stops, the session may be terminated or crunched. Continuous execution ensures all iterations complete within a single session.

## Error Recovery

**Ralph MUST handle errors gracefully. Follow these patterns:**

### Navigation Failures

```pseudocode
try {
  browser_navigate(page_url, timeout: config.timeouts.page_load)
} catch (TimeoutError) {
  if (retries < 3) {
    wait(2000 * retries)  // exponential backoff
    retry navigation
  } else {
    skip this page, mark as "failed", continue to next page
  }
} catch (NetworkError) {
  if (retries < 5) {
    wait(1000)
    retry
  } else {
    skip page, mark as "failed-network"
  }
}
```

### Screenshot Failures

```pseudocode
try {
  browser_take_screenshot(path)
} catch (ScreenshotTimeout) {
  // Don't stop entire iteration
  log_warning("Screenshot failed for {device} - continuing")
  continue with next device
}
```

### Interaction Failures

```pseudocode
try {
  browser_click(element_ref, timeout: config.timeouts.interaction)
  browser_snapshot()
} catch (ElementNotFound) {
  log_info("Element no longer available - UI changed")
  continue to next element
} catch (ElementNotInteractable) {
  log_info("Element not interactable - skipping")
  continue to next element
} catch (ClickTimeout) {
  if (retries < 2) {
    wait(1000)
    retry
  } else {
    skip element
  }
}
```

### General Error Handling

1. **Fail fast** for critical errors: Navigation, MCP disconnection
2. **Retry with backoff** for transient issues: Timeouts, network
3. **Skip and continue** for non-critical failures: Screenshot, single element
4. **Log all errors** in state file visit_history for post-session analysis
5. **Write state before potential crash** — checkpoint on error

**See also**: [references/ERROR-RECOVERY.md](references/ERROR-RECOVERY.md) for comprehensive recovery strategies.

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
- `browser_run_code` - Execute JS (required for mobile emulation)

## Tag System

Use tags to categorize scenarios by feature, priority, state, role, and device.

**Common tags**:
- **Feature**: `@search`, `@user-profile`, `@checkout`
- **Priority**: `@smoke`, `@regression`, `@edge-case`
- **State**: `@happy-path`, `@empty-state`, `@loading`, `@error`
- **Role**: `@role(anonymous)`, `@role(user)`, `@role(admin)`
- **Device**: `@desktop`, `@mobile`, `@tablet`
- **Route**: `@route(/path)` (optional)

**Complete documentation**: See [REFERENCE.md - Tag System](references/REFERENCE.md#tag-categories) for full reference.

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

**Complete documentation**: See [REFERENCE.md - Gherkin Conventions](references/REFERENCE.md#gherkin-conventions) for full reference.

## Page Selection Strategy

Uses intelligent scoring (70%) + randomness (30%) to balance coverage with exploration.

**Score Formula**:

```javascript
weighted_score = (priority × 0.3) + (coverage_gap × 0.3) + (staleness × 0.2) + (diversity × 0.2)
final_score = weighted_score + random(0, 0.3)
```

**Scoring Factors**:
- **Priority** (0-1): critical=1.0, high=0.75, medium=0.5, low=0.25
- **Coverage Gap** (0-1): Missing states/devices/roles from template
- **Staleness** (0-1): (days_since_visit / stale_days) × (1 - quality_score)
- **Diversity** (0-1): 1 - (unique_scenario_types / expected_types)

**Selection Process**:
1. Separate pools: undocumented (pending) vs documented pages
2. Apply ratio (config.iteration.new_discovery_ratio): roll dice to pick pool
3. Pick highest scored page from selected pool
4. Fallback to other pool if selected pool empty

**Complete formulas**: See [references/FORMULAS.md](references/FORMULAS.md) for detailed calculations.

## State Tracking

Ralph tracks progress in `.claude/ralph-loop.local.md`.

**Key fields**:
- `status`: running | paused | stopped | completed
- `iteration`: current iteration number
- `visit_history`: detailed per-page tracking
  - visit_count, last_visited, status (pending/documented/in-progress)
  - priority (critical/high/medium/low), page_type (entry-point/feature/utility)
  - scenarios metadata with tags and timestamps
  - coverage analysis (states/devices/roles covered vs missing)
  - scenario_count (from `grep -c "Scenario:"`)

**On session start**, check `.claude/ralph-loop.local.md`. If missing, start fresh from iteration 1.

**Complete documentation**: See [REFERENCE.md - State File Reference](references/REFERENCE.md#state-file-reference) for full structure.

## Completion Criteria

Output `<promise>E2E_COMPLETE</promise>` when max_iterations reached or user manually stops.

**Quality Indicators** (not completion gates):

- Pages documented: Track how many pages have feature files
- Quick progress metric: `pages_documented / pages_discovered`
- Coverage gaps: Pages with missing states/devices need attention

**Note**: Testing is never truly "complete" — use quality metrics to decide when sufficient coverage is reached.

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
