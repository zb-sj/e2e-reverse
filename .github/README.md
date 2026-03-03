# E2E Reverse Engineering

Autonomous Gherkin documentation generation from live web applications using Ralph Loop.

## Quick Start

```bash
npx skills add zb-sj/e2e-reverse

/e2e-reverse setup      # Configure project
/e2e-reverse start      # Ralph explores autonomously
/e2e-reverse export     # Generate report
```

## What This Skill Does

Ralph autonomously explores your web application and generates detailed Gherkin specifications. These specs are detailed enough for another AI agent to recreate the app from scratch - or for your QA team to build comprehensive E2E tests.

**Key Features:**

- Autonomous exploration with no manual intervention
- Multi-device testing (desktop, mobile, tablet)
- Auto-validation and quality scoring
- Self-correction based on reflection patterns
- Auto-resume from interruptions

## Documentation

| Document | Purpose |
| -------- | ------- |
| [QUICKSTART.md](QUICKSTART.md) | Step-by-step beginner guide |
| [SKILL.md](SKILL.md) | Full skill definition and commands |
| [references/REFERENCE.md](references/REFERENCE.md) | Gherkin conventions, tag system |
| [guides/GHERKIN-BEST-PRACTICES.md](guides/GHERKIN-BEST-PRACTICES.md) | Writing good Gherkin |

## Commands

| Command | Description |
| ------- | ----------- |
| `/e2e-reverse setup` | Configure project settings |
| `/e2e-reverse start` | Launch autonomous exploration |
| `/e2e-reverse status` | Check progress (optional) |
| `/e2e-reverse export` | Generate final report |
| `/e2e-reverse cancel` | Emergency stop |
| `/e2e-reverse help` | Show usage guide |

## Output

Generated files are placed in configured directories:

- `{output_dir}/*.feature` - Gherkin specifications
- `{screenshot_dir}/{feature}/*.png` - Visual evidence

---

*Run `/e2e-reverse help` for detailed usage or see [SKILL.md](SKILL.md) for full documentation.*
