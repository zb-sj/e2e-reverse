# Ralph Core Loop

Read this file at the start of each iteration. This is the authoritative source for iteration logic.

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

For each iteration, execute these steps sequentially:

### 1. NAVIGATE

`browser_navigate` to the target page URL.

If configured, clear browser state first:
- Clear cookies/local storage (if session_management.reset_between_iterations: true)
- Navigate to base_url (if session_management.reset_to_homepage: true)

### 2. CAPTURE — All configured devices (MANDATORY)

**Before screenshots, create directory:**

```bash
mkdir -p {screenshot_dir}/{feature}/
```

**⚠️ MANDATORY: Capture EVERY device in config.devices. Do NOT skip any device. Do NOT defer mobile to later iterations.**

**Phase A — Desktop devices** (width >= 768):

For each desktop device in config.devices:
1. `browser_resize` to dimensions (e.g., 1280x800)
2. `browser_snapshot` → store as {device}_snapshot
3. `browser_take_screenshot` → `{screenshot_dir}/{feature}/initial.{device}.png`

**Phase B — Mobile/tablet devices** (width < 768):

**REQUIRED for every page, every iteration.** Not optional, not deferrable.

For each mobile/tablet device in config.devices:
1. `browser_resize` to device dimensions
2. **REQUIRED**: `browser_run_code` with UA injection from [BROWSER-EXAMPLES.md](BROWSER-EXAMPLES.md) "Mobile View - Option B". `browser_resize` alone is NOT enough — servers check the HTTP User-Agent header.
3. `browser_snapshot` + `browser_take_screenshot`

**Phase C — Reset to desktop** (REQUIRED after any mobile capture):

```
browser_close()
browser_navigate({ url: targetUrl })  // Use stored URL from step 1
browser_resize({ width: 1280, height: 800 })
```

**⚠️ `addInitScript()` stacks permanently.** The ONLY guaranteed reset is `browser_close()`. Always close and reopen after mobile captures.

**Screenshot naming**: `{feature}/{state}.{device}.png`
- Examples: `search/initial.desktop.png`, `search/initial.mobile.png`, `search/loading.png`

**Checklist** (verify before moving to step 3):
- [ ] All desktop devices captured
- [ ] All mobile/tablet devices captured with UA injection
- [ ] `browser_close()` called after mobile captures
- [ ] Browser reopened and resized to desktop for EXPLORE step

### 3. EXPLORE — Discover states

Done once on desktop (device-agnostic exploration):
- Click interactive elements to discover states (loading, error, empty, etc.)
- For each discovered state:
  - Capture snapshot and screenshot
  - Note if state differs across devices
  - Use naming: `{feature}/{state}.png` (device-agnostic) or `{feature}/{state}.{device}.png`

**Target states to capture** (prioritized):
1. **initial** — default page load (already captured in CAPTURE)
2. **loading** — skeleton, spinner, or progress bar during async ops
3. **empty-state** — no data available, first-time user experience
4. **error** — network failure, validation error, permission denied
5. **active/expanded** — tabs selected, filters open, modals shown
6. **partial** — paginated results, "load more" visible

Aim for 3+ state screenshots per page. Don't settle for only the initial state.

### 4. DOCUMENT — Write Gherkin

**Rules:**
- **One feature per file**: Create separate .feature files (e.g., search.feature, user-profile.feature)
- **Check existing files**: Before creating, check if output_dir/{feature-name}.feature exists
- **Update, don't overwrite**: If file exists, READ it first, then ADD new scenarios
- **Preserve structure**: Keep existing scenarios, tags, and rules intact
- **Naming convention**: Use kebab-case matching feature tag (e.g., @apartment-detail → apartment-detail.feature)
- **Device tags**: Add @desktop/@mobile/@tablet where behavior differs; omit when identical
- **Background for common setup**: Detect repeated Given steps across 2+ scenarios, extract to Background. See [GHERKIN-BEST-PRACTICES.md](GHERKIN-BEST-PRACTICES.md)
- **Scenario Outline for data-driven tests**: Detect 3+ scenarios with identical structure but different data, convert to Scenario Outline

**Validation after writing (MANDATORY — do not skip):**

Run this checklist on every feature file after writing/updating:

1. **Syntax**: Feature declaration exists with description
2. **Steps**: Every Scenario has at least Given/When/Then
3. **Uniqueness**: No duplicate scenario names within the feature
4. **Tags**: Feature has `@route()` tag, scenarios have priority tag (`@smoke`/`@regression`/`@edge-case`)
5. **Device coverage**: If config has mobile, at least one `@mobile` scenario exists (or all scenarios are device-agnostic)
6. **Vague steps**: No "Then it works", "Then success", or placeholder steps (TODO, TBD, ...)

If any check fails, fix the issue immediately before proceeding. Log the fix in visit_history.warnings[].

**After writing and validating, count scenarios accurately:**

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

  @empty-state @regression
  Rule: No Results Handling
    Scenario: Search with no matches
      When user searches for non-existent location
      Then empty state message appears
```

**Tag system**: See [REFERENCE.md](REFERENCE.md) for complete tag reference (feature, priority, state, role, device tags).

### 5. UPDATE — Write state file (EVERY iteration)

Write the full state to `.claude/ralph-loop.local.md` using the Write tool (rewrite entire file, not Edit).

**⚠️ MANDATORY: Write state file EVERY iteration. Not every 3rd, not at the end. EVERY iteration.**

**Also write backup** to `{output_dir}/.ralph-state.md` (same content, dual-write for crash recovery).

**Key fields to update:**
- `iteration`: increment
- `status`: running
- `visit_history`: update page entry with visit_count, last_visited, status, coverage, scenario_count
- `coverage.pages_discovered`, `coverage.pages_documented`, `coverage.scenarios_total`
- `coverage.avg_quality_score`: **Recalculate** using formula from REFERENCE.md § Quality Score Configuration

**Use `scenario_count` from grep** — do not manually count scenarios.

**Calculate quality_score per page** (do not fabricate):
```
states_score   = states_covered.length / expected_states.length
devices_score  = devices_covered.length / expected_devices.length
scenarios_score = min(scenario_count / min_scenarios_per_feature, 1.0)
quality_score  = (states_score × 0.4) + (devices_score × 0.35) + (scenarios_score × 0.25)
```

**Update `devices_missing` accurately**: Only remove a device from `devices_missing` when you actually captured screenshots for that device on this page. Never silently delete the field.

### 6. SELECT — Pick next page and continue

**⚠️ MANDATORY: Use the scoring formula below. Do NOT pick pages by intuition.**

For each candidate page, calculate:

```
priority_score  = { critical: 1.0, high: 0.75, medium: 0.5, low: 0.25 }[page.priority]
coverage_gap    = 1 - min(scenario_count / min_scenarios_per_feature, 1.0)
staleness       = page.visit_count == 0 ? 1.0 : 0.5  // simple: unvisited=1.0, visited=0.5
diversity       = page.page_type != last_visited_page_type ? 1.0 : 0.3

final_score = (priority_score × 0.3) + (coverage_gap × 0.3) + (staleness × 0.2) + (diversity × 0.2) + random(0, 0.3)
```

**Log the score breakdown** in `history[]` for the current iteration:

```yaml
- iteration: N
  page: /selected-page
  action: "..."
  score_breakdown:
    priority: 0.75
    coverage_gap: 0.6
    staleness: 1.0
    diversity: 1.0
    random: 0.15
    final: 0.88
```

**Selection process**: Separate undocumented vs documented pools. Use config.iteration.new_discovery_ratio to pick pool, then highest scored page from that pool.

**Immediately start the next iteration.** Do not pause, do not summarize, do not wait for user input.

## Continuous Execution (DO NOT PAUSE)

**Ralph MUST continue iterating without stopping.** These rules are non-negotiable:

1. **MUST** immediately proceed to the next page after updating state
2. **NEVER** output "I will continue in the next iteration" and stop
3. **NEVER** wait for user input between iterations
4. **NEVER** end the turn with a summary of what was done

```pseudocode
while (current_iteration <= max_iterations) {
  navigate_to_page()
  capture_devices()
  explore_states()
  document_gherkin()
  update_state()
  next_page = select_next_page_by_score()
  current_iteration++
}
output("<promise>E2E_COMPLETE</promise>")
```

## File Management

**Multiple feature files, not one monolithic file.**

- One feature = one .feature file
- Kebab-case matching feature tag: `@search` → `search.feature`
- Before writing: check if file exists → READ it first → ADD new scenarios
- Never delete existing scenarios

## Error Recovery

Retry transient errors (timeouts, network) up to 3 times with exponential backoff. Skip and continue on non-critical failures (screenshot, element interaction). Log all errors in state visit_history. Write state checkpoint before any potentially-crashing operation.

## State Tracking

Ralph tracks progress in `.claude/ralph-loop.local.md`.

**On session start**:
- **If missing**: Start fresh — initialize state with iteration: 0, session_count: 1
- **If exists**: Resume — reset iteration to 0, set status: running, increment session_count, keep all existing data

See [REFERENCE.md](REFERENCE.md) for complete state file structure.

## Completion

Ralph declares E2E_COMPLETE when `current_iteration >= max_iterations`.

Output `<promise>E2E_COMPLETE</promise>` when max_iterations reached.

Coverage is never "done" — state persists, user can run more sessions.
