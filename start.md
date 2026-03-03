---
description: "Start E2E reverse engineering session"
allowed-tools: Skill, Read, Write, Edit, Glob, Grep, ToolSearch
argument-hint: "[https://example.com] [--max-iterations 15]"
---

# E2E Reverse Engineering Session

**Follow these steps IN ORDER before doing anything else.**

## Step 1: Check Config File (BLOCKING)

Read the config file at `.claude/e2e-reverse.config.md`.

**If the file does NOT exist:**

```
❌ PREREQUISITE FAILED: Configuration file not found

REQUIRED ACTION:
Run `/e2e-reverse setup` to configure your project first.

Cannot proceed without configuration. Session stopped.
```

Then STOP execution immediately.

**If the file exists:**

- Parse the config to extract: ralph_loop_skill, base_url, output_dir, screenshot_dir, max_iterations, devices
- If `ralph_loop_skill` field is missing:
  ```text
  ❌ CONFIG ERROR: Missing ralph_loop_skill field

  Run `/e2e-reverse setup` to update your configuration.
  ```
  Then STOP execution immediately.

## Step 2: Parse Command Arguments

- URL argument (e.g., `https://example.com`) — overrides base_url from config
- `--max-iterations N` — overrides max_iterations from config

## Step 3: Load Playwright MCP Tools (BLOCKING)

Use ToolSearch to load ALL required tools:

1. `select:mcp__plugin_playwright_playwright__browser_navigate`
2. `select:mcp__plugin_playwright_playwright__browser_resize`
3. `select:mcp__plugin_playwright_playwright__browser_snapshot`
4. `select:mcp__plugin_playwright_playwright__browser_take_screenshot`
5. `select:mcp__plugin_playwright_playwright__browser_click`
6. `select:mcp__plugin_playwright_playwright__browser_type`
7. `select:mcp__plugin_playwright_playwright__browser_wait_for`
8. `select:mcp__plugin_playwright_playwright__browser_run_code`

All 8 tools must load successfully.

**If Playwright tools are NOT available:**

```
❌ PREREQUISITE FAILED: Playwright MCP server not found

Install Playwright MCP server:
https://github.com/modelcontextprotocol/servers/tree/main/src/playwright

Cannot proceed without Playwright. Session stopped.
```

Then STOP execution immediately.

## Step 4: Load Reference Documentation (BLOCKING)

Read these files from the skill directory:

1. **`references/REFERENCE.md`** — Gherkin conventions, tag system, state file structure
2. **`references/GHERKIN-BEST-PRACTICES.md`** — Background, Scenario Outline patterns

Skill directory: `/Users/zigbang/.claude/skills/e2e-reverse`

## Step 5: Write Instructions File

Write `.claude/e2e-reverse-instructions.md` so Ralph can access context in each iteration:

```markdown
# Ralph Iteration Instructions

**Read this file at the START of each iteration.**

## Essential Files

| What | Path |
|------|------|
| Core loop (READ EVERY ITERATION) | `{skill_dir}/references/CORE-LOOP.md` |
| Gherkin conventions & tags | `{skill_dir}/references/REFERENCE.md` |
| Gherkin patterns | `{skill_dir}/references/GHERKIN-BEST-PRACTICES.md` |
| Browser examples | `{skill_dir}/references/BROWSER-EXAMPLES.md` |
| Config | `.claude/e2e-reverse.config.md` |
| State | `.claude/ralph-loop.local.md` |

## Tools (load via ToolSearch each iteration)

browser_navigate, browser_resize, browser_snapshot, browser_take_screenshot, browser_click, browser_type, browser_wait_for, browser_run_code, browser_close

## Critical Rules (NON-NEGOTIABLE)

1. **ALL {max_iterations} iterations MUST execute** — no early exit. Not when "all pages documented." Not for "diminishing returns." When undocumented pages run out, REVISIT lowest quality_score pages. The ONLY stop condition is `iteration >= {max_iterations}`.
2. **Capture ALL devices every iteration** — desktop AND mobile, including revisits. Use `browser_close()` after mobile to reset UA.
3. **Interact with 3+ elements per page (Phase D)** — after device capture, click tabs/filters/buttons, screenshot each result. Store list in state file as `interactions_captured`.
4. **Run `grep -c` after writing each feature file** — use the exact grep output for scenario_count and outline_count in state file. Do not count manually.
5. **Quality score = 5 booleans / 5** — has_mobile, has_interactions(>=3), has_scenarios(>=5), has_outline(>=1), has_valid_gherkin(no When-after-Then). Show all 5 when writing state.
6. **Write state file EVERY iteration** — primary `.claude/ralph-loop.local.md` + backup `{output_dir}/.ralph-state.md`.
7. **`mkdir -p {screenshot_dir}/{feature}/`** BEFORE any browser_take_screenshot.
8. **Page selection by formula** — log score_breakdown in history[]. When all pages documented, revisit lowest quality_score.
9. **Scenario Outlines required** — scan for 3+ similar scenarios, convert to Outline with Examples table.
10. **Output `<promise>E2E_COMPLETE</promise>`** ONLY when iteration >= {max_iterations}.
```

Replace `{skill_dir}` with the actual skill directory path, `{screenshot_dir}` with the config value, and `{max_iterations}` with the config value.

## Step 6: Start Ralph Loop

Extract from config: `ralph_loop_skill`, `base_url`, `output_dir`, `max_iterations`.

Execute the Ralph Loop skill:

- skill: `{ralph_loop_skill}` (e.g., "ralph-loop:ralph-loop")
- args: `"FIRST: Read .claude/e2e-reverse-instructions.md for complete instructions. E2E reverse engineering session. Target: {base_url}. Output: {output_dir}." --max-iterations {max_iterations} --completion-promise "E2E_COMPLETE"`

**Example** (ralph_loop_skill=`ralph-loop:ralph-loop`, base_url=`https://example.com`, output_dir=`e2e/features`, max_iterations=`15`):

```text
Skill tool:
- skill: "ralph-loop:ralph-loop"
- args: "FIRST: Read .claude/e2e-reverse-instructions.md for complete instructions. E2E reverse engineering session. Target: https://example.com. Output: e2e/features." --max-iterations 15 --completion-promise "E2E_COMPLETE"
```
