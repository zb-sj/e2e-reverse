# E2E Reverse Engineering - Quick Start Guide

Get started reverse-engineering your app into Gherkin specs in under 5 minutes.

## Prerequisites

1. **Playwright MCP Server** must be running
   - Check: Run `/browser_navigate` - if it works, you're ready
   - Install: See [Playwright MCP docs](https://github.com/anthropics/mcp-server-playwright)

2. **Your app must be accessible**
   - Running locally (e.g., `http://localhost:3000`)
   - Or deployed (e.g., `https://your-app.com`)

## 3-Step Setup

### Step 1: Initialize Configuration

```bash
/e2e-reverse setup
```

Answer the prompts:
- **Base URL**: Where your app is running (e.g., `http://localhost:3000`)
- **Output directory**: Where to save feature files (default: `e2e/features`)
- **Language**: Korean (`ko`) or English (`en`)
- **Devices**: Desktop + Mobile (recommended for most apps)

This creates `.claude/e2e-reverse.config.md` with your settings.

### Step 2: Start Exploration

```bash
/e2e-reverse start
```

Ralph (the autonomous agent) will:
1. Navigate to your base URL
2. Discover pages by following links
3. Capture screenshots for each device
4. Document UI components and interactions
5. Generate Gherkin scenarios
6. Auto-validate and self-correct quality issues

**Progress tracking**: Ralph updates `.claude/ralph-loop.local.md` every 3 iterations

**Auto-resume**: If interrupted, just run `/e2e-reverse start` again - Ralph picks up where it left off

### Step 3: Export Results

```bash
/e2e-reverse export
```

Generates:
- **Feature files**: `e2e/features/*.feature` (one per feature)
- **Screenshots**: `e2e/screenshots/{feature}/{device}/` (organized by feature and device)
- **Report**: `.claude/e2e-reverse-report.md` (comprehensive coverage analysis)

## What Ralph Documents

For each page, Ralph creates scenarios covering:

✅ **Happy paths** - Successful user flows with valid data
✅ **Empty states** - Initial views, no data available
✅ **Loading states** - Async operations, spinners, skeletons
✅ **Error states** - Network failures, validation errors
✅ **Edge cases** - Boundary conditions, rate limits
✅ **Device variations** - Desktop vs mobile UI differences
✅ **User roles** - Anonymous vs authenticated behaviors

## Example Output

**File**: `e2e/features/search.feature`

```gherkin
@search @route(/search)
Feature: Property Search
  Users can search for rental properties by location, price, and amenities.

  Background:
    Given user is on search page

  @smoke @happy-path
  Rule: Basic Search
    Scenario: Search by location keyword
      When user searches for "강남역"
      Then properties near Gangnam Station appear
      And result count reflects total available properties
      And results are sorted by relevance

  @desktop
  Rule: Desktop Search Experience
    Scenario: Search autocomplete
      When user focuses search input
      Then inline autocomplete dropdown appears
      And recent searches display first
      And popular locations display second

  @mobile
  Rule: Mobile Search Experience
    Scenario: Search overlay
      When user opens search
      Then full-screen search overlay appears
      And search input is auto-focused
      And recent searches are displayed

  @empty-state @regression
  Rule: No Results Handling
    Scenario: Search with no matches
      When user searches for non-existent location
      Then empty state message appears
      And message shows "검색 결과가 없습니다"
      And suggestions for refining search appear

  @error @edge-case
  Rule: Error Handling
    Scenario: Network error during search
      Given network is offline
      When user attempts search
      Then error message appears
      And message shows "네트워크 오류"
      And retry option is available
```

**Directory structure after export**:

```
e2e/
├── features/
│   ├── search.feature
│   ├── apartment-detail.feature
│   ├── user-profile.feature
│   └── chat-room.feature
├── screenshots/
│   ├── search/
│   │   ├── initial.png           # Device-agnostic (same across all)
│   │   ├── initial.desktop.png   # Desktop-specific
│   │   ├── initial.mobile.png    # Mobile-specific
│   │   ├── results.png
│   │   ├── empty-state.png
│   │   └── overlay.mobile.png    # Mobile-only (overlay)
│   └── apartment-detail/
│       ├── initial.png
│       ├── initial.desktop.png
│       ├── initial.mobile.png
│       └── gallery.png
└── .claude/
    ├── e2e-reverse.config.md
    └── e2e-reverse-report.md
```

## Monitoring Progress

While Ralph explores, you can check progress anytime:

```bash
/e2e-reverse status
```

Shows:
- Pages discovered vs documented
- Current iteration and quality score
- Coverage gaps and recommendations
- Next page Ralph will explore

## Customizing Exploration

Edit `.claude/e2e-reverse.config.md` to customize:

### Limit iterations
```yaml
max_iterations: 10  # Stop after 10 pages
```

### Skip paths
```yaml
ignore_paths:
  - "/admin/*"    # Skip admin pages
  - "/api/*"      # Skip API routes
  - "/_next/*"    # Skip Next.js internals
```

### Adjust quality targets
```yaml
quality:
  min_scenarios_per_feature: 5   # Require more scenarios
  target_quality_score: 0.85     # Higher quality threshold
```

### Add more devices
```yaml
devices:
  - name: "desktop"
    width: 1920
    height: 1080
  - name: "mobile"
    width: 390
    height: 844
  - name: "tablet"
    width: 820
    height: 1180
    device: "iPad Air"
```

## Troubleshooting

### "No config found"
Run `/e2e-reverse setup` first to create the config file.

### "Browser not available"
Ensure Playwright MCP server is running. Test with `/browser_navigate`.

### "Ralph stopped unexpectedly"
Run `/e2e-reverse start` again - Ralph will auto-resume from the last checkpoint.

### "Quality score too low"
Increase `max_iterations` or reduce `target_quality_score` in config.

### "Too many pages discovered"
Add more patterns to `ignore_paths` to skip irrelevant pages.

## Advanced Usage

### Resume from checkpoint
```bash
/e2e-reverse start  # Automatically detects and resumes
```

### Export as HTML
```bash
/e2e-reverse export --format html
```

### Export as JSON (for CI/CD)
```bash
/e2e-reverse export --format json
```

### Stop exploration early
```bash
/e2e-reverse cancel
```

## Next Steps

1. **Review generated specs**: Check `e2e/features/` for accuracy
2. **Run tests**: Use these specs with Cucumber, Playwright, or Cypress
3. **Iterate**: Re-run exploration as your app evolves
4. **Customize**: Adjust config and re-run for better coverage

## Tips for Best Results

✅ **Start with a clean state**: Clear cookies/storage before running
✅ **Use authentication wisely**: Set `session_management.preserve_auth: true` if documenting auth-required features
✅ **Run on stable environments**: Use staging or production URLs, not local dev with hot reload
✅ **Review early iterations**: Check first few feature files to ensure Ralph understands your app
✅ **Add domain context**: Fill in the "Domain" and "Terminology" sections in config for better scenario names

## Real-World Example

Zigbang property rental app (Korean real estate platform):

```yaml
---
base_url: "https://www.zigbang.com"
output_dir: "e2e/features"
screenshot_dir: "e2e/screenshots"
max_iterations: 20
language: "ko"

ignore_paths:
  - "/admin/*"
  - "/api/*"
  - "/_next/*"
  - "/ads/*"

devices:
  - name: "desktop"
    width: 1280
    height: 800
  - name: "mobile"
    width: 390
    height: 844
    device: "iPhone 14"
---

# Project Context

## Domain
Zigbang is a Korean property rental platform connecting renters with apartments, officetels, and one-rooms. Key features: map-based search, chatting with agents, saved properties, price alerts.

## Key Entities
- 매물 (maeul) - Property listing
- 원룸 (one-room) - Studio apartment
- 투룸 (two-room) - 1-bedroom apartment
- 오피스텔 (officetel) - Mixed-use building
- 중개사 (agent) - Real estate agent
- 보증금 (deposit) - Security deposit
- 월세 (monthly rent) - Monthly rent amount

## Terminology
- 실거래가 = Actual transaction price
- 전세 = Jeonse (lump-sum deposit lease)
- 월세 = Wolse (monthly rent)
- 관리비 = Maintenance fee
- 방문예약 = Visit booking
```

After running this config, Ralph generated:
- **8 feature files** covering search, detail view, favorites, chat, profile, alerts, map, filters
- **67 scenarios** with 94% coverage of critical states
- **Screenshots for 12 unique pages** across desktop and mobile
- **Average quality score**: 0.82 / 1.0

## Support

- **Full reference**: Read [references/REFERENCE.md](references/REFERENCE.md) for complete tag system, conventions, and formulas
- **Formula details**: See [references/FORMULAS.md](references/FORMULAS.md) for scoring algorithms
- **Template examples**: Check [assets/templates/](assets/templates/) directory for sample feature files

---

*Ready to document your app? Run `/e2e-reverse setup` to begin!*
