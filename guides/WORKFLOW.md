# E2E Reverse Engineering - Workflow Diagram

Visual representation of how Ralph explores and documents web applications.

## High-Level Flow

```
┌─────────────┐
│   Setup     │  User runs /e2e-reverse setup
│   Config    │  Creates .claude/e2e-reverse.config.md
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Start     │  User runs /e2e-reverse start
│   Session   │  Ralph begins autonomous exploration
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────────┐
│          Ralph Loop (Iterations)                │
│                                                 │
│  1. Select next page (smart scoring)            │
│  2. Navigate & capture (all devices)            │
│  3. Explore states (interactions)               │
│  4. Document scenarios (Gherkin)                │
│  5. Validate & self-correct                     │
│  6. Update state & checkpoint                   │
│  7. Repeat until max_iterations or complete     │
└──────┬──────────────────────────────────────────┘
       │
       ▼
┌─────────────┐
│   Export    │  User runs /e2e-reverse export
│   Report    │  Generates comprehensive report
└─────────────┘
```

## Detailed Page Exploration Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    ITERATION START                          │
│                                                             │
│  Current state: iteration N / max_iterations                │
│  Pages discovered: X, Pages documented: Y                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
              ┌────────────────┐
              │ Page Selection │
              │   (Scoring)    │
              └────────┬───────┘
                       │
            ┌──────────┴──────────┐
            ▼                     ▼
    ┌───────────────┐     ┌──────────────┐
    │ Undocumented  │     │  Documented  │
    │    Pages      │     │    Pages     │
    │  (pending)    │     │ (revisit for │
    │               │     │  coverage)   │
    └───────┬───────┘     └──────┬───────┘
            │                    │
            │  Apply ratio (70%) │
            │ new discovery vs   │
            │ 30% improvement    │
            └──────────┬─────────┘
                       │
                       ▼
              ┌────────────────┐
              │ Selected Page  │
              │   /search      │
              └────────┬───────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                   NAVIGATE TO PAGE                          │
│                                                             │
│  browser_navigate(base_url + "/search")                    │
│  Wait for page load (timeout: 30s)                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              CAPTURE ALL DEVICES (Batch)                    │
│                                                             │
│  ┌──────────────────────────────────────────────────┐      │
│  │ For each device (desktop, mobile, tablet):       │      │
│  │                                                   │      │
│  │  1. browser_resize(width, height)                │      │
│  │  2. snapshot = browser_snapshot()                │      │
│  │  3. browser_take_screenshot()                    │      │
│  │     → save to screenshots/search/{device}/       │      │
│  │                       initial.png                 │      │
│  │                                                   │      │
│  │  Store: deviceData[device] = {snapshot, path}    │      │
│  └──────────────────────────────────────────────────┘      │
│                                                             │
│  Result: Desktop, Mobile, Tablet initial states captured   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              EXPLORE STATES (Device-agnostic)               │
│                                                             │
│  Reset to desktop for exploration                          │
│  browser_resize(1280, 800)                                 │
│                                                             │
│  ┌────────────────────────────────────────────────┐        │
│  │ Discover interactive elements from snapshot:   │        │
│  │                                                 │        │
│  │  - Buttons (role: button)                      │        │
│  │  - Inputs (role: textbox)                      │        │
│  │  - Links (role: link)                          │        │
│  │  - Dropdowns (role: combobox)                  │        │
│  │  - ... etc                                     │        │
│  └────────────────────────────────────────────────┘        │
│                                                             │
│  For each interactive element:                             │
│  ┌────────────────────────────────────────────────┐        │
│  │ Trigger interaction:                           │        │
│  │  - browser_click(element_ref)                  │        │
│  │  - browser_type(input_ref, "강남역")           │        │
│  │  - browser_wait_for(state_change)              │        │
│  │                                                 │        │
│  │ Capture state:                                 │        │
│  │  - snapshot = browser_snapshot()               │        │
│  │  - Identify state name (loading, error, etc.)  │        │
│  │                                                 │        │
│  │ Capture for all devices:                       │        │
│  │  For each device:                              │        │
│  │    - browser_resize(device)                    │        │
│  │    - browser_take_screenshot()                 │        │
│  │      → screenshots/search/{device}/{state}.png │        │
│  └────────────────────────────────────────────────┘        │
│                                                             │
│  States discovered:                                        │
│    ✅ empty-state (initial, no input)                      │
│    ✅ loading (after search clicked)                       │
│    ✅ success (results loaded)                             │
│    ✅ error-validation (empty input)                       │
│    ✅ empty-results (no matches)                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│           ANALYZE DEVICE DIFFERENCES                        │
│                                                             │
│  Compare snapshots: desktop vs mobile vs tablet            │
│                                                             │
│  ┌────────────────────────────────────────────────┐        │
│  │ Example differences found:                     │        │
│  │                                                 │        │
│  │ Desktop:                                        │        │
│  │  - Inline autocomplete dropdown                │        │
│  │  - Multi-column results grid                   │        │
│  │  - Filter panel always visible                 │        │
│  │                                                 │        │
│  │ Mobile:                                         │        │
│  │  - Full-screen search overlay                  │        │
│  │  - Single-column results list                  │        │
│  │  - Filter panel in bottom sheet                │        │
│  └────────────────────────────────────────────────┘        │
│                                                             │
│  Flag scenarios needing device-specific variants           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              DOCUMENT SCENARIOS (Gherkin)                   │
│                                                             │
│  1. Check if feature file exists:                          │
│     - features/search.feature                              │
│                                                             │
│  2. If exists:                                              │
│     - READ existing content                                │
│     - IDENTIFY where to add new scenarios                  │
│     - PRESERVE existing scenarios                          │
│     - APPEND new scenarios to appropriate Rules            │
│                                                             │
│     If not exists:                                          │
│     - CREATE new file with Feature header                  │
│                                                             │
│  3. Generate Gherkin from analysis:                        │
│                                                             │
│     @search @route(/search)                                │
│     Feature: Property Search                               │
│                                                             │
│       Background:                                           │
│         Given user is on search page                       │
│                                                             │
│       @smoke @happy-path                                   │
│       Rule: Basic Search                                   │
│         Scenario: Search by location keyword               │
│           When user enters "강남역"                         │
│           And user clicks search button                    │
│           Then search results list appears                 │
│                                                             │
│       @desktop                                             │
│       Rule: Desktop Search                                 │
│         Scenario: Autocomplete dropdown                    │
│           When user clicks search input                    │
│           Then dropdown appears below input                │
│                                                             │
│       @mobile                                              │
│       Rule: Mobile Search                                  │
│         Scenario: Full-screen overlay                      │
│           When user taps search bar                        │
│           Then full-screen overlay opens                   │
│                                                             │
│       @empty-state @regression                             │
│       Rule: No Results                                     │
│         Scenario: Search with no matches                   │
│           When user searches for "asdfghjkl"               │
│           Then empty message appears                       │
│                                                             │
│       @error @edge-case                                    │
│       Rule: Validation                                     │
│         Scenario: Empty search input                       │
│           When user clicks search without input            │
│           Then validation error appears                    │
│                                                             │
│       @loading @regression                                 │
│       Rule: Loading State                                  │
│         Scenario: Show loading during search               │
│           When user submits search                         │
│           Then loading spinner appears                     │
│                                                             │
│  4. WRITE feature file:                                    │
│     - features/search.feature                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│         VALIDATE GHERKIN (Self-correction)                  │
│                                                             │
│  Call: _validate-gherkin(features/search.feature)          │
│                                                             │
│  Checks:                                                    │
│  ✅ Syntax (valid Gherkin structure)                       │
│  ✅ Conventions (tags, naming, step keywords)              │
│  ✅ Quality (specific steps, no placeholders)              │
│  ✅ Coverage (states, devices, roles)                      │
│                                                             │
│  If validation.valid = false:                              │
│    - Apply auto-fixes (indentation, missing tags)          │
│    - Re-write problematic scenarios                        │
│    - Re-validate until clean                               │
│                                                             │
│  If validation.warnings exist:                             │
│    - Log coverage gaps for next visit                      │
│    - Update page.coverage_gaps                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              CALCULATE METRICS                              │
│                                                             │
│  Call: _calculate-metrics(visit_history, config)           │
│                                                             │
│  For this page:                                            │
│    - states_covered: [happy-path, empty-state, loading,    │
│                       error-validation, empty-results]     │
│    - devices_covered: [desktop, mobile]                    │
│    - roles_covered: [anonymous]                            │
│    - scenario_diversity: 0.71 (5/7 types)                  │
│                                                             │
│  Calculate quality_score:                                  │
│    state_coverage = 5/5 = 1.0                              │
│    device_coverage = 2/3 = 0.67 (missing tablet)           │
│    role_coverage = 1/1 = 1.0 (anonymous only expected)     │
│    scenario_diversity = 0.71                               │
│                                                             │
│    quality_score = (1.0 × 0.4) +   # state weight          │
│                    (0.67 × 0.25) +  # device weight        │
│                    (1.0 × 0.15) +   # role weight          │
│                    (0.71 × 0.20)    # diversity weight     │
│                  = 0.86                                     │
│                                                             │
│  Result: High quality! (target: 0.75)                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              UPDATE STATE & CHECKPOINT                      │
│                                                             │
│  Update visit_history["/search"]:                          │
│    visit_count: 1                                           │
│    last_visited: "2026-02-04T12:00:00Z"                    │
│    status: "documented"                                    │
│    priority: "critical"                                    │
│    page_type: "entry-point"                                │
│    scenarios: [7 scenarios with metadata]                  │
│    coverage: {states, devices, roles}                      │
│    quality_score: 0.86                                     │
│    scenario_diversity: 0.71                                │
│    coverage_gap_score: 0.14                                │
│                                                             │
│  Update global coverage:                                   │
│    pages_documented: Y + 1                                 │
│    scenarios_total: Z + 7                                  │
│    avg_quality_score: recalculate across all pages         │
│                                                             │
│  Check if should write state:                              │
│    - Every 3 iterations? (iteration % 3 === 0)             │
│    - Page reached target quality? (0.86 > 0.75) ✅         │
│    - On error/interruption?                                │
│                                                             │
│  Write checkpoint:                                         │
│    Call: _write-checkpoint(state, "Page quality target")  │
│    Writes:                                                 │
│      - .claude/ralph-loop.local.md (state file)           │
│      - .claude/e2e-reverse-checkpoint.md (summary)        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
              ┌────────────────┐
              │ Iteration Done │
              └────────┬───────┘
                       │
            ┌──────────┴──────────┐
            │                     │
            ▼                     ▼
    iteration < max?       User stopped?
            │                     │
            │ YES                 │ NO
            │                     │
            ▼                     ▼
    ┌────────────┐       ┌──────────────┐
    │ Continue   │       │  Complete    │
    │ Next Page  │       │  Session     │
    └─────┬──────┘       └──────┬───────┘
          │                     │
          │                     ▼
          │              Output completion
          │              promise
          │
          └──────────┐
                     │
                     ▼
            ITERATION START (loop back)
```

## Page Selection Algorithm

```
┌─────────────────────────────────────────────────────────────┐
│                  SELECT NEXT PAGE                           │
│                                                             │
│  1. Separate pools:                                         │
│     ┌─────────────────┐    ┌─────────────────┐            │
│     │ Undocumented    │    │  Documented     │            │
│     │ (pending)       │    │  (revisit for   │            │
│     │                 │    │   coverage)     │            │
│     │ /apt/:id        │    │ /search ✓       │            │
│     │ /user/profile   │    │ /home ✓         │            │
│     │ /chat/:id       │    │                 │            │
│     └─────────────────┘    └─────────────────┘            │
│                                                             │
│  2. Calculate scores for ALL pages:                        │
│                                                             │
│     For each page:                                         │
│       priority_score = {critical: 1.0, high: 0.75, ...}    │
│       coverage_gap = missing states/devices/roles          │
│       staleness = (days_old / 7) × (1 - quality_score)     │
│       diversity = 1 - (unique_types / expected_types)      │
│                                                             │
│       weighted = (priority × 0.3) +                        │
│                  (coverage_gap × 0.3) +                    │
│                  (staleness × 0.2) +                       │
│                  (diversity × 0.2)                         │
│                                                             │
│       random_factor = random(0, 0.3)                       │
│       final_score = weighted + random_factor               │
│                                                             │
│  3. Example scores:                                        │
│                                                             │
│     /search (documented, 1 day old, quality 0.86):         │
│       priority: 1.0 (critical)                             │
│       coverage_gap: 0.14 (missing tablet)                  │
│       staleness: (1/7) × (1-0.86) = 0.02                   │
│       diversity: 1 - 0.71 = 0.29                           │
│       weighted: (1.0×0.3)+(0.14×0.3)+(0.02×0.2)+(0.29×0.2) │
│                = 0.40                                       │
│       random: 0.12                                          │
│       final: 0.52                                           │
│                                                             │
│     /apt/:id (undocumented):                               │
│       priority: 0.75 (high)                                │
│       coverage_gap: 1.0 (nothing covered yet)              │
│       staleness: 0 (never visited)                         │
│       diversity: 1.0 (no scenarios yet)                    │
│       weighted: (0.75×0.3)+(1.0×0.3)+(0×0.2)+(1.0×0.2)     │
│                = 0.725                                      │
│       random: 0.22                                          │
│       final: 0.945                                          │
│                                                             │
│  4. Apply discovery ratio (0.7 = 70% new pages):           │
│                                                             │
│     roll = random() = 0.42                                 │
│     if roll < 0.7: pick from undocumented pool             │
│     else: pick from documented pool                        │
│                                                             │
│     result: 0.42 < 0.7 → pick undocumented                 │
│                                                             │
│  5. Select highest scored page from chosen pool:           │
│                                                             │
│     undocumented pool scores:                              │
│       /apt/:id: 0.945 ← WINNER                             │
│       /user/profile: 0.62                                  │
│       /chat/:id: 0.58                                      │
│                                                             │
│     → Navigate to /apt/:id                                 │
└─────────────────────────────────────────────────────────────┘
```

## Error Recovery Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    ERROR OCCURS                             │
│                                                             │
│  Examples:                                                  │
│  - Page load timeout                                        │
│  - Element not found                                        │
│  - Snapshot timeout                                         │
│  - Network error                                            │
│  - Validation failed                                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
              ┌────────────────┐
              │ Detect Error   │
              │    Type        │
              └────────┬───────┘
                       │
         ┌─────────────┼─────────────┐
         │             │             │
         ▼             ▼             ▼
    ┌────────┐   ┌────────┐   ┌─────────┐
    │ Browser│   │Network │   │Validation│
    │ Error  │   │ Error  │   │  Error   │
    └───┬────┘   └────┬───┘   └────┬────┘
        │             │             │
        ▼             ▼             ▼
    ┌────────────────────────────────────┐
    │    RECOVERY STRATEGY               │
    │                                    │
    │  1. Retry with variations          │
    │     - Longer timeout               │
    │     - Alternative selectors        │
    │     - Wait and retry               │
    │                                    │
    │  2. Degrade gracefully             │
    │     - Skip feature if unavailable  │
    │     - Document limitation          │
    │     - Use partial data             │
    │                                    │
    │  3. Auto-fix if possible           │
    │     - Fix syntax errors            │
    │     - Add missing tags             │
    │     - Normalize indentation        │
    │                                    │
    │  4. Log and continue               │
    │     - Record error in state        │
    │     - Mark page status             │
    │     - Move to next page            │
    └────────────┬───────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
    Success?          Failed?
        │                 │
        │                 ▼
        │         ┌───────────────┐
        │         │ Check Error   │
        │         │    Rate       │
        │         └───────┬───────┘
        │                 │
        │          ┌──────┴──────┐
        │          │             │
        │          ▼             ▼
        │      < 50%?        >= 50%?
        │          │             │
        │          ▼             ▼
        │      Continue     Pause Session
        │      Next Page    Write Checkpoint
        │          │             │
        └──────────┴─────────────┘
                   │
                   ▼
           Continue Exploration
```

## State File Evolution

```
Iteration 0 (Start):
──────────────────────────────────────
visit_history: {}
pages_discovered: 0
pages_documented: 0

Iteration 1 (/search discovered and documented):
──────────────────────────────────────
visit_history:
  /search:
    status: "documented"
    quality_score: 0.86
    coverage: {states: 5, devices: 2, roles: 1}
    scenarios: 7

pages_discovered: 1
pages_documented: 1

Iteration 2 (/apt/:id documented):
──────────────────────────────────────
visit_history:
  /search: {status: "documented", quality: 0.86, ...}
  /apt/:id: {status: "documented", quality: 0.45, ...}

pages_discovered: 2
pages_documented: 2

Iteration 3 (/search revisited for tablet):
──────────────────────────────────────
visit_history:
  /search:
    visit_count: 2  ← increased
    quality_score: 0.92  ← improved
    coverage: {states: 5, devices: 3, roles: 1}  ← tablet added
    scenarios: 10  ← 3 more scenarios
  /apt/:id: {status: "documented", quality: 0.45, ...}

pages_discovered: 2
pages_documented: 2
```

## Export Process

```
┌─────────────────────────────────────────────────────────────┐
│            USER RUNS /e2e-reverse export                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
              ┌────────────────┐
              │ Read State     │
              │ & Config       │
              └────────┬───────┘
                       │
                       ▼
              ┌────────────────┐
              │ Calculate      │
              │ Final Metrics  │
              └────────┬───────┘
                       │
                       ▼
       ┌───────────────────────────────┐
       │ Generate Report               │
       │                               │
       │ - Executive Summary           │
       │ - Coverage Analysis           │
       │ - Quality Distribution        │
       │ - Page-by-Page Breakdown      │
       │ - Coverage Gaps               │
       │ - Recommendations             │
       └───────────┬───────────────────┘
                   │
          ┌────────┴────────┐
          │                 │
          ▼                 ▼
    ┌──────────┐      ┌──────────┐
    │ Markdown │      │  HTML    │
    │ Report   │      │ Report   │
    └──────────┘      └──────────┘

Output files:
  ✅ features/*.feature (Gherkin specs)
  ✅ screenshots/{feature}/{device}/*.png
  ✅ .claude/e2e-reverse-report.md
  ✅ .claude/e2e-reverse-report.html (if requested)
  ✅ .claude/e2e-reverse-report.json (if requested)
```

## Key Design Patterns

### 1. Batch Operations
- Navigate **once**, capture **all devices**
- Reduces browser operations by ~53%

### 2. Atomic Writes
- Write to `.tmp` files first
- Rename for atomicity
- Prevents corruption on interruption

### 3. Self-Correction Loop
- Validate → Fix → Re-validate
- Auto-fixes where possible
- Logs issues for human review

### 4. Smart Prioritization
- 70% deterministic (quality metrics)
- 30% random (exploration diversity)
- Balances coverage with discovery

### 5. Progressive Enhancement
- Start with basic scenarios
- Revisit to add coverage
- Never "complete", always improvable

---

*This workflow ensures Ralph explores efficiently and documents comprehensively.*
