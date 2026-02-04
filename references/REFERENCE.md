# E2E Reverse Engineering - Full Reference

Complete documentation for element detection, Gherkin conventions, and coverage metrics.

## Element Detection Patterns

Use these selectors to identify interactive elements in browser snapshots:

```javascript
const ELEMENT_PATTERNS = {
  // Navigation
  tabs:      '[role="tab"], [class*="tab"], [data-tab]',
  links:     'a[href^="/"], a[href^="http"]',
  menus:     '[role="menu"], [class*="menu"], nav',
  breadcrumb: '[class*="breadcrumb"], [aria-label*="breadcrumb"]',

  // Actions
  buttons:   'button, [role="button"], [class*="btn"]',
  toggles:   '[role="switch"], [type="checkbox"], [class*="toggle"]',
  dropdowns: '[role="combobox"], select, [class*="dropdown"]',

  // Inputs
  textInputs: 'input[type="text"], input[type="search"], input:not([type])',
  passwords:  'input[type="password"]',
  textareas:  'textarea',
  selects:    'select, [role="listbox"]',
  datePickers: 'input[type="date"], [class*="datepicker"], [class*="calendar"]',

  // Content
  cards:     '[class*="card"], [class*="Card"], article',
  lists:     'ul, ol, [role="list"]',
  tables:    'table, [role="table"], [class*="table"]',
  images:    'img, [role="img"], picture',

  // Overlays
  modals:    '[role="dialog"], [class*="modal"], [class*="Modal"]',
  tooltips:  '[role="tooltip"], [class*="tooltip"]',
  popovers:  '[class*="popover"], [class*="Popover"]',
  bottomSheets: '[class*="bottom-sheet"], [class*="BottomSheet"]',

  // Forms
  forms:     'form, [role="form"]',
  labels:    'label, [class*="label"]',
  errors:    '[class*="error"], [role="alert"], [aria-invalid="true"]',

  // Maps & Charts
  maps:      '#map, [class*="Map"], [class*="map-container"]',
  charts:    'canvas, svg[class*="chart"], [class*="Chart"]',

  // Filters & Search
  filters:   '[class*="filter"], [class*="Filter"]',
  chips:     '[class*="chip"], [class*="Chip"], [class*="tag"]',
  searchBox: '[type="search"], [class*="search"], [role="searchbox"]',

  // Loading & Status
  loaders:   '[class*="loading"], [class*="spinner"], [aria-busy="true"]',
  skeletons: '[class*="skeleton"], [class*="Skeleton"]',
  progress:  'progress, [role="progressbar"]',
};
```

## Standard State Definitions

These are the canonical UI states to document for each feature:

```yaml
standard_states:
  # Core user flows
  happy_path:
    name: "happy-path"
    description: "Successful operation with valid data"
    priority: critical
    tags: ["@smoke", "@happy-path"]

  # Empty/initial states
  empty_state:
    name: "empty-state"
    description: "No data available, initial view"
    priority: high
    tags: ["@empty-state", "@regression"]

  # Loading states
  loading:
    name: "loading"
    description: "Async operation in progress"
    priority: high
    tags: ["@loading", "@regression"]

  # Error conditions
  error_network:
    name: "error-network"
    description: "Network failure, offline, timeout"
    priority: critical
    tags: ["@error", "@edge-case"]

  error_validation:
    name: "error-validation"
    description: "Invalid input, validation failure"
    priority: high
    tags: ["@error", "@regression"]

  error_permission:
    name: "error-permission"
    description: "Unauthorized, forbidden access"
    priority: medium
    tags: ["@error", "@edge-case"]

  # Edge cases
  partial_data:
    name: "partial"
    description: "Incomplete results, pagination needed"
    priority: medium
    tags: ["@edge-case", "@regression"]

  rate_limited:
    name: "rate-limited"
    description: "Too many requests, throttled"
    priority: low
    tags: ["@edge-case"]
```

### Using State Definitions

When documenting a feature, aim to cover:

1. **Critical states** (priority: critical) - Must document
2. **High priority states** (priority: high) - Should document
3. **Medium/low states** (priority: medium/low) - Nice to have

**Quality score calculation** considers state coverage:

- Critical state missing: -0.3 per state
- High priority missing: -0.2 per state
- Medium/low missing: -0.1 per state

## Gherkin Conventions

### File Naming

```text
{feature-name}.feature

Examples:
- search.feature
- apartment-detail.feature
- user-profile.feature
- chat-room.feature
```

### Feature Structure

```gherkin
@route(/path) @feature-tag
Feature: Feature Name
  Brief description of what this feature does.

  Background:
    Given common preconditions for all scenarios

  @priority-tag @state-tag
  Rule: Logical grouping of scenarios
    Description of what this rule covers.

    @device-tag
    Scenario: Specific test case
      Given precondition
      When action
      Then expected result
```

### Tag Categories

| Category | Tags | Usage |
| -------- | ---- | ----- |
| Route | `@route(/path)` | URL mapping, one per feature |
| Feature | `@search`, `@apt`, `@chat` | Feature categorization |
| Priority | `@smoke`, `@regression`, `@edge-case` | Test priority |
| State | `@happy-path`, `@empty-state`, `@loading`, `@error` | UI state |
| Role/Auth | `@role(anonymous)`, `@role(user)`, `@role(admin)`, `@role(*)` | User authentication/authorization requirements |
| Device | `@desktop`, `@mobile`, `@tablet` | Device-specific |

**Role Tag Examples**:

- `@role(anonymous)` - Guest/unauthenticated users only
- `@role(user)` - Authenticated users
- `@role(admin)` - Admin/privileged users
- `@role(moderator)` - Custom role (any role name supported)
- `@role(premium)` - Custom role for premium/paid users

**Role Tag Scope**:

- **Feature-level**: All scenarios inherit the role requirement
- **Scenario-level**: Override feature-level role for specific scenarios

```gherkin
@user-profile @role(user)
Feature: User Profile Management
  # All scenarios require authenticated user

  @role(admin)
  Scenario: Delete user account
    # This specific scenario requires admin role
```

### Step Conventions

**Given** - Preconditions (state setup)
```gherkin
Given user is logged in
Given user is on the home page
Given user has no saved apartments
Given network is offline
```

**When** - Actions (user interactions)
```gherkin
When user taps search bar           # mobile
When user clicks search input       # desktop
When user enters "강남역"
When user scrolls down
When user swipes left on card
When user waits 500ms
```

**Then** - Assertions (expected results)
```gherkin
Then search results appear
Then error message shows "네트워크 오류"
Then loading spinner is visible
Then results count shows "총 42개"
Then map centers on selected location
```

**And/But** - Additional steps
```gherkin
And search input shows placeholder "검색어 입력"
And results are sorted by price ascending
But premium listings appear first
```

### Device-Specific Scenarios

Pattern 1: Separate scenarios with device tags
```gherkin
@desktop
Scenario: Search on desktop
  When user clicks search input
  Then dropdown autocomplete appears

@mobile
Scenario: Search on mobile
  When user taps search bar
  Then full-screen overlay opens
```

Pattern 2: Same scenario name, different device variants
```gherkin
Rule: Search Flow (All Devices)

  Scenario: Enter search term
    When user activates search
    Then suggestions appear

  @desktop
  Scenario: Enter search term
    When user clicks search input
    Then dropdown shows below input

  @mobile
  Scenario: Enter search term
    When user taps search bar
    Then full-screen suggestions appear
```

### State Coverage Matrix

| State | Trigger | Example |
| ----- | ------- | ------- |
| Empty | No data | "검색 결과가 없습니다" |
| Loading | Async operation | Spinner, skeleton |
| Success | Data loaded | Results list |
| Error | Network/validation | Error message |
| Partial | Some data | "더보기" button |

## Coverage Metrics

### Page Status

| Status | Criteria |
| ------ | -------- |
| `pending` | Discovered but not documented |
| `documented` | Has feature file (can always be revisited) |
| `in-progress` | Currently being documented this iteration |

**Note**: No "complete" status - pages evolve. Quality scores indicate coverage depth, not finality.

### Session End Criteria

Session ends when max_iterations reached or user manually stops.

**Quality Indicators** to guide decisions:

1. Pages documented: How many pages have feature files
2. Average quality_score: Overall coverage depth across pages
3. Coverage gaps: Pages with low quality_score or missing states/devices
4. Scenario diversity: Variety of test types (@smoke, @error, @edge-case, etc.)

### Quality Score Configuration

Quality scores are calculated using configurable weights:

```yaml
quality_scoring:
  # Component weights (must sum to 1.0)
  weights:
    state_coverage: 0.4        # How many standard states covered
    device_coverage: 0.25      # How many devices documented
    role_coverage: 0.15        # How many user roles tested
    scenario_diversity: 0.20   # Variety of scenario types

  # State coverage scoring
  state_scoring:
    critical_state_weight: 0.3    # Impact of missing critical state
    high_state_weight: 0.2        # Impact of missing high priority state
    medium_state_weight: 0.1      # Impact of missing medium/low state

  # Device coverage expectations
  device_expectations:
    desktop: required             # Must document
    mobile: required              # Must document
    tablet: optional              # Nice to have

  # Role coverage expectations (page-type specific)
  role_expectations:
    entry-point:
      - anonymous                 # Must cover guest users
    feature:
      - anonymous
      - user                      # Authenticated users
    utility:
      - user                      # Usually requires auth
```

**Formula**:

```
quality_score = (
  (states_covered / expected_states) × state_coverage_weight +
  (devices_covered / expected_devices) × device_coverage_weight +
  (roles_covered / expected_roles) × role_coverage_weight +
  scenario_diversity_score × scenario_diversity_weight
)
```

**Benefits**:

- Customize scoring per project
- Adjust weights based on priorities
- Add new scoring components easily

### Coverage Expectations by Page Type

Different page types have different coverage requirements:

```yaml
coverage_templates:
  entry-point:
    description: "Landing pages, home, search - first user touchpoint"
    priority: critical
    expected_states:
      - happy_path
      - empty_state
      - loading
      - error_network
    expected_devices:
      - desktop
      - mobile
      - tablet
    expected_roles:
      - anonymous
    min_scenarios: 5
    target_quality_score: 0.85

  feature:
    description: "Main functionality pages - core app features"
    priority: high
    expected_states:
      - happy_path
      - empty_state
      - loading
      - error_network
      - error_validation
    expected_devices:
      - desktop
      - mobile
    expected_roles:
      - anonymous
      - user
    min_scenarios: 4
    target_quality_score: 0.75

  utility:
    description: "Settings, help, profile - supporting pages"
    priority: medium
    expected_states:
      - happy_path
      - error_validation
    expected_devices:
      - desktop
      - mobile
    expected_roles:
      - user
    min_scenarios: 3
    target_quality_score: 0.65
```

**Usage**:

- Assign page_type when discovering page (entry-point, feature, utility)
- Apply coverage template expectations
- Calculate coverage_gap based on missing states/devices/roles from template
- Guide prioritization: entry-point pages get higher scores

### Iteration Strategy

**Smart Weighted Selection**: Combines intelligent scoring (70%) with randomness (30%)

**Score Formula**:

```javascript
weighted_score = (priority × 0.3) + (coverage_gap × 0.3) + (staleness × 0.2) + (diversity × 0.2)
random_factor = random(0, 0.3)
final_score = weighted_score + random_factor
```

**Scoring Factors**:

- **Priority** (0-1): critical=1.0, high=0.75, medium=0.5, low=0.25
- **Coverage Gap** (0-1): Missing states/devices/roles
- **Staleness** (0-1): (days_since_visit / stale_days) × (1 - quality_score)
- **Diversity** (0-1): Scenario variety (1 = needs more types)

**Selection Process**:

1. Calculate scores for all non-complete pages
2. Apply ratio: if random() < ratio → pick highest scored undocumented page, else documented page
3. Fallback to other pool if selected pool empty

## Config File Reference

Full `.claude/e2e-reverse.config.md` structure:

```yaml
---
# Target
base_url: "https://example.com"

# Output
output_dir: "e2e/features"
screenshot_dir: "e2e/screenshots"

# Session
max_iterations: 15
language: "ko"  # ko, en

# Paths to skip
ignore_paths:
  - "/admin/*"
  - "/debug/*"
  - "/_next/*"

# URL Normalization Rules
url_normalization:
  ignore_trailing_slash: true        # /search and /search/ are same page
  ignore_query_params: false         # /search?q=1 and /search?q=2 are different
  ignore_fragments: true             # /page#top and /page are same page
  case_sensitive: false              # /Search and /search are same page
  excluded_query_params: []          # Params to ignore (e.g., utm_source, fbclid)

# Browser Operation Timeouts (milliseconds)
timeouts:
  page_load: 30000           # Wait for navigation to complete
  element_wait: 10000        # Wait for element to appear
  snapshot: 5000             # Timeout for accessibility tree snapshot
  interaction: 3000          # Click/type operation timeout
  state_transition: 5000     # Wait for UI state change after action
  network_idle: 2000         # Wait for network requests to settle

# Session Management
session_management:
  reset_between_iterations: true      # Clear cookies/storage between pages
  preserve_auth: true                 # Keep authentication state across iterations
  reset_to_homepage: false            # Navigate to base_url before each page
  wait_for_idle_after_reset: 2000     # ms to wait after reset

# Performance Optimization
cache:
  enabled: true
  reuse_snapshots_within_hours: 24     # Don't re-snapshot if captured recently
  reuse_screenshots: false             # Always capture fresh screenshots (visual changes)
  invalidate_on_url_change: true       # URL query params changed = new snapshot
  cache_dir: ".claude/e2e-reverse-cache"

performance:
  state_file_write_interval: 3         # Write state every N iterations
  checkpoint_on_page_complete: true    # Write when page quality reaches target

# Device configurations
devices:
  - name: "desktop"
    width: 1280
    height: 800
  - name: "mobile"
    width: 390
    height: 844
    device: "iPhone 14"
  - name: "tablet"
    width: 820
    height: 1180
    device: "iPad Air"

# Iteration strategy
iteration:
  new_discovery_ratio: 0.7
  stale_days: 7

# Quality targets (guidance, not gates)
quality:
  min_scenarios_per_feature: 3
  target_quality_score: 0.75
---

# Project Context

## Domain
[What the app does, key user problems it solves]

## Key Entities
- Entity1 (한국어명) - description
- Entity2 (한국어명) - description

## Terminology
- term1 = definition
- term2 = definition

## Business Rules
- Rule 1: description
- Rule 2: description
```

### URL Normalization

URL normalization rules determine when two different URLs should be considered the same page:

**ignore_trailing_slash**: `true` (recommended)
- `/search` and `/search/` → treated as same page
- Prevents duplicate documentation

**ignore_query_params**: `false` (default)
- `/search?q=foo` and `/search?q=bar` → treated as different pages
- Set to `true` if query params don't change page content
- Use `excluded_query_params` for specific params to ignore

**ignore_fragments**: `true` (recommended)
- `/docs#intro` and `/docs#advanced` → treated as same page
- Fragments are client-side navigation, don't change server content

**case_sensitive**: `false` (recommended)
- `/Search` and `/search` → treated as same page
- Most web servers are case-insensitive

**excluded_query_params**: `[]` (customize as needed)
- List of query param names to always ignore
- Common examples: `["utm_source", "utm_medium", "utm_campaign", "fbclid", "gclid", "ref"]`
- Useful for tracking parameters that don't affect page content

**Examples**:

```yaml
# E-commerce site - query params matter
url_normalization:
  ignore_trailing_slash: true
  ignore_query_params: false         # /products?sort=price vs /products?sort=name are different
  ignore_fragments: true
  case_sensitive: false
  excluded_query_params: ["utm_source", "utm_medium", "fbclid"]

# Documentation site - query params don't matter
url_normalization:
  ignore_trailing_slash: true
  ignore_query_params: true          # /docs?v=1.0 vs /docs?v=2.0 show same content
  ignore_fragments: true
  case_sensitive: false
  excluded_query_params: []
```

### Path Ignore Patterns

Uses glob syntax (same as .gitignore):

**Pattern Syntax**:
- `*` matches any characters except `/`
- `**` matches any characters including `/`
- `?` matches single character
- Case-insensitive by default (configurable via `url_normalization.case_sensitive`)

**Examples**:

```yaml
ignore_paths:
  - "/admin/*"           # Matches: /admin/users, /admin/settings
                         # NOT: /admin (exact), /admin/users/123 (nested)

  - "/admin/**"          # Matches: /admin/users, /admin/users/123, /admin/a/b/c

  - "/api/*/debug"       # Matches: /api/v1/debug, /api/v2/debug
                         # NOT: /api/debug, /api/v1/v2/debug

  - "**/_next/**"        # Matches: /_next/static/abc, /app/_next/chunk.js

  - "/temp-*"            # Matches: /temp-123, /temp-abc
```

**Common Patterns**:

```yaml
# Next.js app
ignore_paths:
  - "/_next/**"          # Build artifacts
  - "/api/**"            # API routes (document separately)
  - "**/*.map"           # Source maps

# Admin panel
ignore_paths:
  - "/admin/**"          # All admin pages
  - "/dashboard/**"      # Internal dashboards

# Development/debug
ignore_paths:
  - "/debug/**"
  - "/test/**"
  - "**/__test__/**"
```

### Browser Timeouts

Timeouts control how long to wait for browser operations before considering them failed:

**page_load** (30000ms / 30s)
- How long to wait for page navigation to complete
- Increase for slow servers or complex SPAs with large bundles
- Decrease for fast local development environments

**element_wait** (10000ms / 10s)
- Maximum time to wait for elements to appear in DOM
- Increase for slow-loading content or lazy-loaded components
- Covers `browser_click`, `browser_type` operations

**snapshot** (5000ms / 5s)
- Timeout for capturing accessibility tree snapshot
- Usually fast, rarely needs adjustment
- Increase if snapshots frequently timeout on complex pages

**interaction** (3000ms / 3s)
- Time to wait for click/type actions to execute
- Increase if interactions trigger slow animations or transitions
- Usually sufficient for most interactions

**state_transition** (5000ms / 5s)
- Wait time after interaction for UI state to settle
- Increase for slow API responses or heavy computations
- Critical for capturing loading/error states

**network_idle** (2000ms / 2s)
- How long to wait with no network activity before considering page "loaded"
- Increase for pages with many analytics requests
- Decrease for faster iteration on simple pages

**When to Adjust**:

```yaml
# Slow production environment
timeouts:
  page_load: 60000      # 60s for slow backend
  element_wait: 15000   # 15s for lazy loading
  network_idle: 5000    # 5s for analytics

# Fast local development
timeouts:
  page_load: 10000      # 10s is plenty
  element_wait: 5000    # 5s is sufficient
  network_idle: 500     # 500ms is enough

# Heavy SPA with slow API
timeouts:
  page_load: 45000      # Large bundle takes time
  state_transition: 10000  # API calls are slow
  network_idle: 3000    # Many requests
```

### Session Management

Controls browser state between page iterations to prevent state leakage:

**reset_between_iterations** (`true` recommended)
- Clear cookies, localStorage, sessionStorage between pages
- Prevents authentication/cart state from affecting unrelated pages
- Ensures each page is documented in clean state
- Set to `false` only if you want state to persist (e.g., testing authenticated flows across pages)

**preserve_auth** (`true` recommended with reset_between_iterations)
- When `true`: Keep authentication cookies while clearing other state
- Useful for documenting features that require login
- Specific cookies to preserve can be configured (implementation detail)
- Set to `false` to test fully logged-out scenarios

**reset_to_homepage** (`false` default)
- Navigate to `base_url` before each page iteration
- Adds extra navigation overhead
- Useful if pages have complex interdependencies
- Usually not needed with proper `reset_between_iterations`

**wait_for_idle_after_reset** (2000ms default)
- Time to wait after clearing state before navigating to next page
- Allows browser to settle after storage clear
- Increase if experiencing race conditions
- Decrease for faster iteration on simple sites

**Examples**:

```yaml
# Default: Clean state between pages, keep auth
session_management:
  reset_between_iterations: true
  preserve_auth: true
  reset_to_homepage: false
  wait_for_idle_after_reset: 2000

# Test as anonymous user (no auth preserved)
session_management:
  reset_between_iterations: true
  preserve_auth: false
  reset_to_homepage: false
  wait_for_idle_after_reset: 2000

# Preserve all state (e.g., testing cart across pages)
session_management:
  reset_between_iterations: false
  preserve_auth: true
  reset_to_homepage: false
  wait_for_idle_after_reset: 0

# Complex app with state dependencies
session_management:
  reset_between_iterations: true
  preserve_auth: true
  reset_to_homepage: true      # Reset to homepage each time
  wait_for_idle_after_reset: 3000
```

**State Leakage Issues Fixed**:
- Shopping cart items appearing on unrelated pages
- Search filters persisting across iterations
- Authentication state affecting anonymous pages
- Form inputs pre-filled from previous pages
- localStorage preferences affecting default states

### Performance Caching

Cache snapshots and screenshots to avoid redundant browser operations when revisiting pages:

**enabled** (`true` default)
- Enable/disable caching system
- Set to `false` to always capture fresh data
- Useful for debugging or testing caching behavior

**reuse_snapshots_within_hours** (24 hours default)
- Reuse snapshot if captured within this time window
- Snapshots capture UI structure (accessibility tree)
- Safe to cache longer since structure changes less frequently
- Set to `0` to never reuse (always fresh)

**reuse_screenshots** (`false` default)
- Whether to reuse screenshot images
- Recommended `false` - visual changes are common (CSS, images, content updates)
- Set to `true` only if your UI is completely static
- Screenshots are cheap to capture (< 1s per device)

**invalidate_on_url_change** (`true` recommended)
- Clear cache entry when URL query params change
- Prevents `/search?q=foo` from using cached `/search?q=bar` data
- Set to `false` if query params don't affect page content

**cache_dir** (`.claude/e2e-reverse-cache` default)
- Directory to store cached data
- Relative to project root
- Can be safely deleted to clear cache

**Cache Key Format**:
```
{url_normalized}_{device_name}_{state}
```

**Cache Entry Structure**:
```json
{
  "snapshot": {...},              // Accessibility tree
  "screenshot_path": "...",       // Relative path to screenshot
  "captured_at": "ISO8601",       // Timestamp
  "url": "https://...",           // Original URL
  "device": "desktop",            // Device name
  "state": "initial"              // UI state (initial, loading, error, etc.)
}
```

**Examples**:

```yaml
# Aggressive caching (fast iterations, rarely changing UI)
cache:
  enabled: true
  reuse_snapshots_within_hours: 72     # 3 days
  reuse_screenshots: true              # Reuse images too
  invalidate_on_url_change: false      # Query params don't matter
  cache_dir: ".claude/e2e-reverse-cache"

# Conservative caching (default)
cache:
  enabled: true
  reuse_snapshots_within_hours: 24     # 1 day
  reuse_screenshots: false             # Always capture fresh images
  invalidate_on_url_change: true       # Query params matter
  cache_dir: ".claude/e2e-reverse-cache"

# No caching (always fresh data)
cache:
  enabled: false
```

**When Cache Helps**:
- Revisiting pages to add missing states/devices
- Iterating on quality_score improvement
- Exploring similar pages with shared components
- Recovery after interruption

**Cache Invalidation**:
- Automatically after `reuse_snapshots_within_hours` expires
- Manually delete `cache_dir` to force refresh
- URL change triggers new cache entry (if `invalidate_on_url_change: true`)

### State File I/O Optimization

Batched writes to reduce disk I/O overhead during long sessions:

**state_file_write_interval** (3 default)
- Write state file every N iterations
- Reduces disk I/O from 15 writes (1 per iteration) to 5 writes (every 3 iterations)
- Higher values = less I/O, but longer gap before state is persisted
- Set to `1` to write every iteration (safest, but slower)
- Set to `5` or higher for faster iterations (riskier if interrupted)

**checkpoint_on_page_complete** (`true` recommended)
- Write state immediately when a page reaches target quality_score
- Ensures progress isn't lost for completed pages
- Complements `state_file_write_interval` for important milestones
- Set to `false` to rely only on interval-based writes

**Write Triggers** (state file is written when ANY of these occur):
1. Every N iterations (per `state_file_write_interval`)
2. Page reaches target quality_score (if `checkpoint_on_page_complete: true`)
3. On error/interruption (crash recovery)
4. On manual pause (`/e2e-reverse pause`)
5. On session completion (max_iterations reached)

**Implementation**:
- State kept in memory during session
- Atomic writes (write to temp file, then rename) prevent corruption
- Background write doesn't block browser operations

**Examples**:

```yaml
# Aggressive performance (minimal writes)
performance:
  state_file_write_interval: 5       # Write every 5 iterations
  checkpoint_on_page_complete: false # No checkpoint writes

# Balanced (default)
performance:
  state_file_write_interval: 3       # Write every 3 iterations
  checkpoint_on_page_complete: true  # Checkpoint on milestones

# Safe (frequent writes)
performance:
  state_file_write_interval: 1       # Write every iteration
  checkpoint_on_page_complete: true  # Checkpoint on milestones
```

**Tradeoffs**:
- Higher interval = faster iterations, but risk losing more work on crash
- Lower interval = slower iterations, but safer against data loss
- Recommendation: Use default (3) unless you have specific needs

## State File Reference

`.claude/ralph-loop.local.md` structure with enhanced tracking:

```yaml
---
status: running          # running | paused | stopped | completed
iteration: 3
max_iterations: 15
started_at: "2026-02-04T10:00:00Z"
paused_at: null

coverage:
  pages_discovered: 12
  pages_documented: 8
  scenarios_total: 45
  avg_quality_score: 0.72

iteration_strategy:
  new_discovery_ratio: 0.7
  stale_days: 7

visit_history:
  /search:
    # Basic tracking
    visit_count: 2
    last_visited: "2026-02-04T10:30:00Z"
    status: documented

    # Priority & classification
    priority: critical          # critical | high | medium | low
    page_type: entry-point      # entry-point | feature | utility

    # Scenario metadata
    scenarios:
      - id: "search-happy-path-desktop"
        tags: ["@smoke", "@happy-path", "@desktop"]
        added_at: "2026-02-04T10:00:00Z"
      - id: "search-empty-state-mobile"
        tags: ["@empty-state", "@mobile"]
        added_at: "2026-02-04T10:30:00Z"
      - id: "search-error-network"
        tags: ["@error", "@edge-case", "@desktop"]
        added_at: "2026-02-04T11:00:00Z"
      - id: "search-loading-debounce"
        tags: ["@loading", "@desktop"]
        added_at: "2026-02-04T11:15:00Z"

    # Coverage analysis
    coverage:
      states_covered: ["happy-path", "empty-state", "error", "loading"]
      states_missing: []
      devices_covered: ["desktop", "mobile"]
      devices_missing: ["tablet"]
      roles_covered: ["anonymous", "user"]
      roles_missing: []

    # Quality metrics
    quality_score: 0.90           # 0-1 overall quality
    scenario_diversity: 0.85      # variety of scenario types
    coverage_gap_score: 0.10      # how much is missing (lower = better)
    staleness_score: 0.05         # time + quality decay (lower = fresher)

    # Reflection tracking (NEW - 2026 best practice)
    reflection:
      - iteration: 2
        quality_score: 0.90
        quality_delta: +0.20      # improved from 0.70
        issues_found:
          - type: "missing-device-tag"
            severity: "high"
            fixed: true
        issues_prevented:
          - "imperative-steps"    # learned from iteration 1
        notes: "Improved device tagging consistency. Now using declarative style."
        learning: "Always check for device-specific UI differences before writing scenarios"

    # Error tracking
    errors: []                    # critical errors that blocked iteration
    warnings: []                  # non-blocking issues
    retries: 0                    # number of retry attempts

  /apt/:id:
    visit_count: 1
    last_visited: "2026-02-04T11:00:00Z"
    status: documented
    priority: high
    page_type: feature
    scenarios:
      - id: "apt-detail-view-desktop"
        tags: ["@smoke", "@happy-path", "@desktop"]
        added_at: "2026-02-04T11:00:00Z"
    coverage:
      states_covered: ["happy-path"]
      states_missing: ["empty-state", "error", "loading"]
      devices_covered: ["desktop"]
      devices_missing: ["mobile", "tablet"]
      roles_covered: ["anonymous"]
      roles_missing: ["user"]
    quality_score: 0.35
    scenario_diversity: 0.25
    coverage_gap_score: 0.65
    staleness_score: 0.15

  /my:
    visit_count: 0
    status: pending
    priority: medium
    page_type: feature

history:
  - iteration: 1
    page: /search
    action: "Documented search.feature (4 scenarios)"
    score_breakdown:
      priority: 1.0
      coverage_gap: 1.0
      staleness: 0.0
      diversity: 1.0
      random: 0.15
      final: 1.15
  - iteration: 2
    page: /search
    action: "Added 2 more scenarios"
    score_breakdown:
      priority: 1.0
      coverage_gap: 0.4
      staleness: 0.2
      diversity: 0.5
      random: 0.22
      final: 0.82
---
```

### Enhanced State Tracking Fields

**Page Priority**:

- `critical` - Login, search, checkout, main flows
- `high` - Key features, user profiles
- `medium` - Secondary features
- `low` - Utility pages, settings

**Page Types**:

- `entry-point` - Landing, home, search
- `feature` - Main functionality pages
- `utility` - Settings, help, legal

**Scenario Metadata**:

Each scenario tracks:

- `id` - Unique identifier (kebab-case)
- `tags` - All Gherkin tags used
- `added_at` - Timestamp

**Coverage Analysis**:

Tracks what's covered vs. missing:

- States: happy-path, empty-state, error, loading
- Devices: desktop, mobile, tablet
- Roles: anonymous, user, admin, etc.

**Quality Metrics**:

- `quality_score` - Overall completeness (0-1)
- `scenario_diversity` - Variety of scenario types (0-1)
- `coverage_gap_score` - Missing coverage (0-1, lower is better)
- `staleness_score` - Time + quality decay (0-1, lower is fresher)

**Reflection Tracking** (NEW - 2026 best practice):

- `reflection[]` - Array of reflection notes from each iteration
  - `iteration` - Iteration number
  - `quality_score` - Quality score at this iteration
  - `quality_delta` - Change from previous iteration (+/-)
  - `issues_found[]` - Validation issues detected
  - `issues_prevented[]` - Mistakes avoided (learned from previous iterations)
  - `notes` - Human-readable summary of improvements
  - `learning` - Pattern/insight extracted for future iterations

**Error Tracking**:

- `errors[]` - Critical errors that blocked iteration
- `warnings[]` - Non-blocking issues encountered
- `retries` - Number of retry attempts for this page

## Playwright MCP Tools Reference

| Tool | Parameters | Purpose |
| ---- | ---------- | ------- |
| `browser_navigate` | url | Navigate to URL |
| `browser_resize` | width, height | Set viewport size |
| `browser_snapshot` | - | Get accessibility tree |
| `browser_click` | ref or selector | Click element |
| `browser_type` | ref or selector, text | Enter text |
| `browser_take_screenshot` | - | Capture screenshot |
| `browser_evaluate` | script | Run JavaScript |
| `browser_wait_for` | selector, timeout | Wait for element |
