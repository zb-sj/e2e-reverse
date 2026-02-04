---
description: "Show E2E reverse engineering usage guide"
allowed-tools: Read
---

# E2E Reverse Engineering

Reverse-engineer live apps into Gherkin documentation detailed enough for another agent to recreate the app.

## Quick Start

**Typical workflow** (3 commands):
1. `/e2e-reverse setup` - Configure for your project
2. `/e2e-reverse start` - Ralph explores autonomously
3. `/e2e-reverse export` - Generate final report

**Optional monitoring**:
- `/e2e-reverse status` - Check progress anytime
- `/e2e-reverse cancel` - Emergency stop (rarely needed)

## Commands

### Session Control
- `/e2e-reverse setup` - Initialize configuration for your project
- `/e2e-reverse start [URL] [--max-iterations N]` - Launch Ralph's autonomous exploration
  - Auto-detects and resumes from checkpoint if interrupted
  - Ralph handles validation, checkpointing, and quality improvement
- `/e2e-reverse cancel` - Emergency stop (use if needed)

### Monitoring & Reporting
- `/e2e-reverse status` - View current session progress (optional)
- `/e2e-reverse export [--format html|json|markdown]` - Generate comprehensive report

### Help
- `/e2e-reverse help` - Show this guide

## Ralph's Autonomous Features

Ralph handles these automatically (no separate commands needed):
- **Auto-checkpointing**: Saves progress every N iterations
- **Auto-resume**: Detects checkpoint on restart and continues
- **Inline validation**: Self-validates scenarios as they're written
- **Self-correction**: Fixes issues immediately based on quality scores
- **Iterative improvement**: Revisits pages to improve coverage

## Usage

```text
/e2e-reverse start [URL] [--max-iterations N]
```

## Examples

```text
/e2e-reverse start
/e2e-reverse start https://example.com
/e2e-reverse start --max-iterations 10
```

## Output

- Gherkin specs: `{output_dir}/*.feature` (default: `e2e/features/`)
- Screenshots: `{screenshot_dir}/{feature}/{name}[.{device}].png` (default: `e2e/screenshots/`)
  - Device-agnostic: `search/initial.png`
  - Device-specific: `search/initial.desktop.png`, `search/initial.mobile.png`

## Configuration

Project config is stored in `.claude/e2e-reverse.config.md`.

Run `/e2e-reverse setup` to create or update config.

## Full Reference

For detailed documentation:

- **Gherkin conventions & tag system**: [references/REFERENCE.md](references/REFERENCE.md)
- **Quality scoring algorithms**: [references/FORMULAS.md](references/FORMULAS.md)
- **Report templates**: [references/REPORTING.md](references/REPORTING.md)
- **Step-by-step guide**: [QUICKSTART.md](QUICKSTART.md)
