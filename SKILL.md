---
name: e2e-reverse
description: Reverse-engineer live web applications into Gherkin specifications for E2E testing and recreation. Use when you need to document existing app behavior, create test scenarios from production apps, generate BDD specifications from live websites, or recreate app features based on observed interactions. Autonomous exploration via Ralph Loop with auto-validation and quality scoring.
argument-hint: "<setup|start|status|export|cancel|help> [options]"
---

# E2E Reverse Engineering - Command Router

**STEP 1: Parse Command (MANDATORY)**

Extract the first argument to determine which subcommand to execute:
- `setup` → Read and execute [setup.md](setup.md)
- `start` → Read and execute [start.md](start.md)
- `status` → Read and execute [status.md](status.md)
- `export` → Read and execute [export.md](export.md)
- `cancel` → Read and execute [cancel.md](cancel.md)
- `help` → Read and execute [help.md](help.md)
- No argument or invalid → Show help below

**If a valid subcommand is detected, IMMEDIATELY read and execute that command file. DO NOT show the documentation below.**

---

## Help Documentation (shown only when no subcommand or 'help' subcommand)

Autonomous Gherkin documentation generation from live web applications using Ralph Loop.

### Quick Start

```bash
/e2e-reverse setup      # Configure or reconfigure project
/e2e-reverse start      # Ralph explores autonomously
/e2e-reverse status     # Check progress (optional)
/e2e-reverse export     # Generate report
```

**New to E2E reverse? See [QUICKSTART.md](QUICKSTART.md) for a step-by-step guide.**

## Examples

**Documenting an e-commerce site:**
```bash
/e2e-reverse setup
# Configure: base_url = https://www.example-shop.com
/e2e-reverse start --max-iterations 20
# Ralph autonomously explores: homepage, product listings, detail pages, cart, checkout
# Auto-generates: search.feature, product-detail.feature, checkout.feature
/e2e-reverse export --format html
```

**Analyzing a SaaS dashboard:**
```bash
/e2e-reverse start https://app.saas-platform.com
# Ralph discovers: login, dashboard, settings, user management
# Creates device-specific scenarios for desktop and mobile views
/e2e-reverse status  # Check progress during exploration
```

**Property rental app (Korean):**
```bash
/e2e-reverse setup
# Configure: base_url = https://www.zigbang.com, language = ko
/e2e-reverse start
# Generates Korean Gherkin specs with @mobile, @desktop tags
```

## Commands (User-Invocable)

- **[setup.md](setup.md)** - Initialize project configuration
- **[start.md](start.md)** - Launch Ralph's autonomous exploration
- **[status.md](status.md)** - View progress (optional)
- **[export.md](export.md)** - Generate comprehensive report
- **[cancel.md](cancel.md)** - Emergency stop
- **[help.md](help.md)** - Usage guide

## Ralph's Autonomous Features

Ralph handles automatically:

- ✅ Auto-checkpointing every N iterations
- ✅ Auto-resume from interruptions
- ✅ Inline validation as scenarios are written
- ✅ Self-correction based on quality scores
- ✅ Iterative improvement via smart page selection

## Architecture

```text
e2e-reverse/
├── *.md                    # User-invocable commands (6 total)
├── scripts/                # Internal utilities (7 files, all user-invocable: false)
│   ├── calculate-metrics.md
│   ├── check-prerequisites.md
│   ├── check-session.md
│   ├── list-features.md
│   ├── load-config.md
│   ├── validate-gherkin.md
│   └── write-checkpoint.md
├── assets/templates/       # Example Gherkin features for Ralph
│   ├── user-profile.feature
│   ├── search.feature
│   ├── apartment-detail.feature
│   └── README.md
└── references/             # Agent execution reference
    ├── REFERENCE.md        # Complete Gherkin conventions, tags, config
    ├── REPORTING.md        # Report templates
    └── FORMULAS.md         # Scoring algorithms

```

## Output

**Generated files:**

- `{output_dir}/*.feature` - Gherkin specifications (one per feature)
- `{output_dir}/.ralph-state.md` - **Backup state file** (resilient - inside git-tracked directory)
- `{screenshot_dir}/{feature}/{name}[.{device}].png` - Screenshots organized by feature
  - Device-agnostic: `search/initial.png`
  - Device-specific: `search/initial.desktop.png`, `search/initial.mobile.png`
- `.claude/ralph-loop.local.md` - Primary session state tracking (may be lost if session crunched)
- `.claude/e2e-reverse-report.{format}` - Final report (markdown/json/html)

## Documentation

### For Users (Human-Readable)

- **[QUICKSTART.md](QUICKSTART.md)** - Complete beginner's guide (start here!)
- **[help.md](help.md)** - Command reference and usage guide
- **[guides/ARCHITECTURE.md](guides/ARCHITECTURE.md)** - Architecture and optimization details
- **[guides/WORKFLOW.md](guides/WORKFLOW.md)** - Visual workflow diagrams
- **[guides/BROWSER-EXAMPLES.md](guides/BROWSER-EXAMPLES.md)** - Playwright MCP integration examples
- **[guides/ERROR-RECOVERY.md](guides/ERROR-RECOVERY.md)** - Error handling strategies
- **[references/FORMULAS.md](references/FORMULAS.md)** - Quality scoring algorithms
- **[assets/templates/README.md](assets/templates/README.md)** - Template usage guide

### For Claude (Agent Reference)

- **[references/REFERENCE.md](references/REFERENCE.md)** - Gherkin conventions, tag system, config structure
- **[references/REPORTING.md](references/REPORTING.md)** - Report templates for status, export, validation

## Configuration

Project config stored in `.claude/e2e-reverse.config.md`:

```yaml
---
base_url: "https://example.com"
output_dir: "e2e/features"
screenshot_dir: "e2e/screenshots"
max_iterations: 15
language: "ko"
devices:
  - name: desktop
    width: 1920
    height: 1080
  - name: mobile
    width: 375
    height: 667
---
```

Run `/e2e-reverse setup` to create or update.

## Philosophy

**Ralph-centric design**: Optimized for autonomous agent operation, not manual human execution.

- Minimal commands (setup → start → export)
- Auto-validation, auto-checkpointing, auto-resume
- Self-correction via quality scoring
- Iterative improvement until sufficient coverage

**DRY & Efficient**: Shared utilities eliminate duplication, batched operations reduce overhead.

## Guidelines (MANDATORY REQUIREMENTS)

When using this skill, Claude MUST:

1. **BLOCKING REQUIREMENT: Validate prerequisites** - Check Playwright MCP server availability before starting exploration. Do NOT proceed if unavailable.
2. **BLOCKING REQUIREMENT: Respect user configuration** - Load and apply settings from `.claude/e2e-reverse.config.md`. Do NOT proceed without valid config (except for setup command).
3. **MANDATORY: Follow Gherkin best practices** - Use Given/When/Then structure, feature-oriented organization, proper tagging. No exceptions.
4. **MANDATORY: Maintain session state** - Auto-checkpoint progress, enable resume on interruption. This is not optional.
5. **MANDATORY: Prioritize quality over quantity** - Use scoring algorithms to guide iterative improvement. Do NOT skip validation.
6. **MANDATORY: Document device-specific behavior** - Create separate scenarios for desktop/mobile/tablet when differences exist. Do NOT merge device-specific behaviors.
7. **MANDATORY: Use descriptive naming** - Feature files named after functionality (search.feature, not page1.feature). Do NOT use generic names.
8. **MANDATORY: Capture visual evidence** - Take screenshots for key states, organized by feature. Do NOT skip screenshots.
9. **MANDATORY: Generate actionable output** - Gherkin specs MUST be detailed enough for recreation or test automation. Insufficient detail is a failure.

---

*For detailed usage, run `/e2e-reverse help` or see [references/REFERENCE.md](references/REFERENCE.md)*
