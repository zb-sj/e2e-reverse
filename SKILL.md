---
name: e2e-reverse
description: "Reverse-engineer live web applications into Gherkin specifications for E2E testing and recreation. Use when you need to document existing app behavior, create test scenarios from production apps, generate BDD specifications from live websites, or recreate app features based on observed interactions. Autonomous exploration via Ralph Loop with auto-validation and quality scoring. Requires Playwright MCP server for browser automation."
compatibility: "Requires Playwright MCP server"
---

# E2E Reverse Engineering - Command Router

Parse the first argument to determine which subcommand to execute:
- `setup` → Read and execute [setup.md](setup.md)
- `start` → Read and execute [start.md](start.md)
- `status` → Read and execute [status.md](status.md)
- `export` → Read and execute [export.md](export.md)
- `cancel` → Read and execute [cancel.md](cancel.md)
- `help` → Read and execute [help.md](help.md)
- No argument or invalid → Show quick start below

If a valid subcommand is detected, IMMEDIATELY read and execute that command file. Do not continue reading this file.

---

## Quick Start

```bash
/e2e-reverse setup      # Configure project (base URL, devices, language)
/e2e-reverse start      # Ralph explores autonomously
/e2e-reverse export     # Generate report
```

## Examples

**E-commerce site:**
```bash
/e2e-reverse setup
# Configure: base_url = https://www.example-shop.com
/e2e-reverse start --max-iterations 20
/e2e-reverse export --format html
```

**SaaS dashboard:**
```bash
/e2e-reverse start https://app.saas-platform.com
/e2e-reverse status  # Check progress during exploration
```

## Mandatory Requirements

1. **BLOCKING**: Validate Playwright MCP server availability before starting exploration.
2. **BLOCKING**: Load and apply settings from `.claude/e2e-reverse.config.md`.
3. Follow Gherkin best practices (Given/When/Then, feature-oriented, proper tagging).
4. Maintain session state with auto-checkpointing; enable resume on interruption.
5. Use quality scoring algorithms to prioritize quality over quantity.
6. Document device-specific behavior separately (do not merge desktop/mobile/tablet).
7. Name feature files after functionality (`search.feature`, not `page1.feature`).
8. Capture screenshots for key states, organized by feature.
9. Generate Gherkin specs detailed enough for recreation or test automation.

## References

- **[references/REFERENCE.md](references/REFERENCE.md)** - Gherkin conventions, tag system, config structure
- **[references/FORMULAS.md](references/FORMULAS.md)** - Quality scoring algorithms
- **[references/REPORTING.md](references/REPORTING.md)** - Report templates
- **[references/BROWSER-EXAMPLES.md](references/BROWSER-EXAMPLES.md)** - Playwright MCP integration examples
- **[references/ERROR-RECOVERY.md](references/ERROR-RECOVERY.md)** - Error handling strategies
- **[references/ARCHITECTURE.md](references/ARCHITECTURE.md)** - System design and optimization
- **[references/WORKFLOW.md](references/WORKFLOW.md)** - Visual workflow diagrams
- **[references/GHERKIN-BEST-PRACTICES.md](references/GHERKIN-BEST-PRACTICES.md)** - Writing standards
- **[references/MODAL-HANDLING.md](references/MODAL-HANDLING.md)** - Dialog/modal handling

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
