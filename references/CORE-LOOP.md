# Ralph Core Loop

Read this file at the start of each iteration. This is the authoritative source for iteration logic.

## Mission

Reverse-engineer the app into Gherkin documentation so detailed that another AI agent could recreate the app from scratch.

## Step Output Chain

Each step produces a **mandatory output** consumed by the next step. Skipping a step means the next step has no input — you must fabricate data, which violates the rules. **Print the output line exactly as shown** after each step.

```
NAVIGATE → target_url
CAPTURE  → devices_captured (list)  ← must match config.devices.length
EXPLORE  → interactions (list of 3+) ← GATE: cannot proceed if < 3
DOCUMENT → scenario_count, outline_count, validation (7 checks)
UPDATE   → quality_score (computed, not assigned)
SELECT   → next_page, score_breakdown
```

## Core Loop

### 1. NAVIGATE

`browser_navigate` to the target page URL.

If configured, clear browser state first:
- Clear cookies/local storage (if session_management.reset_between_iterations: true)
- Navigate to base_url (if session_management.reset_to_homepage: true)

**Output** (print this line):
```
→ NAVIGATE: url={url}
```

### 2. CAPTURE — All configured devices (MANDATORY)

**Before screenshots, create directory:**

```bash
mkdir -p {screenshot_dir}/{feature}/
```

**⚠️ MANDATORY: Capture EVERY device in config.devices — on new pages AND revisits. Never defer mobile.**

**Phase A — Desktop devices** (width >= 768):

For each desktop device in config.devices:
1. `browser_resize` to dimensions (e.g., 1280x800)
2. `browser_snapshot` → store as {device}_snapshot
3. `browser_take_screenshot` → `{screenshot_dir}/{feature}/initial.{device}.png`

**Phase B — Mobile/tablet devices** (width < 768):

For each mobile/tablet device in config.devices:
1. `browser_resize` to device dimensions
2. **REQUIRED**: `browser_run_code` with UA injection from [BROWSER-EXAMPLES.md](BROWSER-EXAMPLES.md) "Mobile View - Option B". `browser_resize` alone is NOT enough — servers check the HTTP User-Agent header.
3. `browser_snapshot` + `browser_take_screenshot`

**Phase C — Reset to desktop** (REQUIRED after any mobile capture):

```
browser_close()
browser_navigate({ url: target_url })  // Use stored URL from step 1
browser_resize({ width: 1280, height: 800 })
```

**⚠️ `addInitScript()` stacks permanently.** The ONLY guaranteed reset is `browser_close()`. Always close and reopen after mobile captures.

**Screenshot naming**: `{feature}/{state}.{device}.png`

**Output** (print this line — list every device captured):
```
→ CAPTURE: devices=[desktop, mobile] (2/2)
```

**GATE: If devices captured < config.devices.length, go back and capture the missing devices.**

### 3. EXPLORE — Discover states (minimum 3 interactions)

Done once on desktop (device-agnostic exploration). **Do NOT skip this step** — screenshots alone are insufficient. You must interact with the page to discover states that aren't visible on initial load.

For each interaction:
1. Click/interact with an element (tab, filter, button, link, input)
2. Capture screenshot of the resulting state
3. Note what changed (new content, modal, error, loading state, etc.)

**Target states** (prioritized):
1. **initial** — default page load (already captured in CAPTURE)
2. **loading** — skeleton, spinner, or progress bar during async ops
3. **empty-state** — no data available, first-time user experience
4. **error** — network failure, validation error, permission denied
5. **active/expanded** — tabs selected, filters open, modals shown
6. **partial** — paginated results, "load more" visible

**On revisits**: interact with 3+ NEW elements not covered in existing scenarios. Try invalid inputs, check loading states, test edge cases.

**Output** (print this line — list each element interacted with):
```
→ EXPLORE: interactions=[clicked 서울 tab, opened price filter, scrolled to pagination] (3/3)
```

**GATE: If interactions < 3, go back and interact with more elements. Cannot proceed to DOCUMENT.**

### 4. DOCUMENT — Write Gherkin

**Rules:**
- **One feature per file**: Create separate .feature files (kebab-case matching feature tag)
- **Check existing files**: Before creating, check if output_dir/{feature-name}.feature exists
- **Update, don't overwrite**: If file exists, READ it first, then ADD new scenarios
- **Background for common setup**: Detect repeated Given steps across 2+ scenarios, extract to Background
- **Device tags**: Add @desktop/@mobile/@tablet where behavior differs; omit when identical

**Scenario Outline enforcement**: After writing all scenarios, scan for 3+ scenarios with identical Given/When/Then structure but different nouns/data. Convert to Scenario Outline with Examples table. Run:

```bash
grep -c "Scenario Outline:" {output_dir}/{feature-name}.feature
```

Store as `outline_count`.

**Validation (run all 7, print each result):**

```
  [1] Feature declaration with description? YES/NO
  [2] Every Scenario has Given/When/Then?   YES/NO
  [3] No duplicate scenario names?          YES/NO
  [4] Feature has @route(), scenarios have priority tags? YES/NO
  [5] At least one @mobile scenario (if mobile in config)? YES/NO
  [6] No vague steps (TODO, TBD, "it works")? YES/NO
  [7] No When after Then in any scenario?   YES/NO
```

Fix any NO immediately before proceeding. Log fixes in visit_history.warnings[].

**Count scenarios accurately:**

```bash
grep -c "Scenario:" {output_dir}/{feature-name}.feature
```

Store as `scenario_count`.

**Output** (print this line):
```
→ DOCUMENT: file={feature}.feature, scenarios={N}, outlines={M}, validation=7/7
```

**GATE: If validation < 7/7, fix failures before proceeding.**

### 5. UPDATE — Write state file (EVERY iteration)

Write the full state to `.claude/ralph-loop.local.md` using the Write tool (rewrite entire file, not Edit).

**Also write backup** to `{output_dir}/.ralph-state.md` — identical content, written immediately after primary.

**Calculate quality_score** (show your work — do not assign a number without computing it):

```
has_mobile       = 1 if "mobile" in devices_captured, else 0
has_explore      = 1 if interactions.length >= 3, else 0
has_scenarios    = 1 if scenario_count >= 5, else 0
has_outline      = 1 if outline_count >= 1, else 0
has_validation   = 1 if validation == 7/7, else 0
quality_score    = (has_mobile + has_explore + has_scenarios + has_outline + has_validation) / 5
```

This uses the outputs from CAPTURE (devices_captured), EXPLORE (interactions), and DOCUMENT (scenario_count, outline_count, validation). If you skipped those steps, you cannot compute this score.

**Key fields to update:**
- `iteration`: increment
- `status`: running
- `visit_history`: update page entry with coverage, scenario_count, quality_score
- `coverage.scenarios_total`, `coverage.avg_quality_score`
- `devices_missing`: only remove when actually captured

**Output** (print this line — show the 5 boolean components):
```
→ UPDATE: quality=0.80 (mobile=1, explore=1, scenarios=1, outline=1, validation=0)
```

### 6. SELECT — Pick next page and continue

**⚠️ Use scoring formula. Do NOT pick pages by intuition.**

For each candidate page, calculate:

```
priority_score  = { critical: 1.0, high: 0.75, medium: 0.5, low: 0.25 }[page.priority]
coverage_gap    = 1 - min(scenario_count / min_scenarios_per_feature, 1.0)
staleness       = page.visit_count == 0 ? 1.0 : 0.5
diversity       = page.page_type != last_visited_page_type ? 1.0 : 0.3

final_score = (priority_score × 0.3) + (coverage_gap × 0.3) + (staleness × 0.2) + (diversity × 0.2) + random(0, 0.3)
```

Log `score_breakdown` in `history[]` for EVERY iteration.

**Selection process**: Separate undocumented vs documented pools. Use config.iteration.new_discovery_ratio to pick pool, then highest scored page.

**If all pages are documented**: Revisit pages with the lowest quality_score. Target pages with quality < 1.0 — they are missing mobile, explore, scenarios, outlines, or validation.

**Output** (print this line):
```
→ SELECT: next={page} (score={final}, priority={p}, gap={g}, stale={s}, diverse={d}, rand={r})
```

**Immediately start the next iteration.**

## Revisit Protocol

When revisiting a documented page, follow the SAME 6 steps. No shortcuts:
1. NAVIGATE — same as new visit
2. CAPTURE — **must recapture all devices** (especially mobile if quality_score shows has_mobile=0)
3. EXPLORE — **interact with 3+ NEW elements** not covered in existing scenarios
4. DOCUMENT — **add NEW scenarios** for discovered states. Convert to Scenario Outline if 3+ similar.
5. UPDATE — recalculate quality_score using same 5-boolean formula
6. SELECT — continue to next

**A revisit that adds zero scenarios is a wasted iteration.** Explore deeper: try invalid inputs, check loading states, test edge cases, switch tabs.

## Continuous Execution (DO NOT PAUSE)

**Ralph MUST continue iterating without stopping.** These rules are non-negotiable:

1. **MUST** immediately proceed to the next page after printing SELECT output
2. **NEVER** output "I will continue in the next iteration" and stop
3. **NEVER** wait for user input between iterations
4. **NEVER** end the turn with a summary of what was done
5. **NEVER** set status to "completed" before reaching max_iterations
6. **NEVER** claim "diminishing returns" as a reason to stop

```pseudocode
while (current_iteration <= max_iterations) {
  navigate_to_page()        // → target_url
  capture_devices()         // → devices_captured
  explore_states()          // → interactions (≥3)
  document_gherkin()        // → scenario_count, outline_count, validation
  update_state()            // → quality_score
  next_page = select_next() // → next_page, score_breakdown
  current_iteration++
}
output("<promise>E2E_COMPLETE</promise>")
```

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
