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

1. **Capture ALL devices every iteration** — desktop AND mobile. Do NOT defer mobile to later iterations. See CORE-LOOP.md step 2.
2. **`browser_close()` after mobile captures** — `addInitScript()` stacks permanently. Only `browser_close()` resets UA. Then `browser_navigate` to stored URL.
3. **Write state file EVERY iteration** — primary: `.claude/ralph-loop.local.md`, backup: `{output_dir}/.ralph-state.md`. Not every 3rd. EVERY iteration.
4. **Calculate quality scores with formula** — NEVER fabricate scores. Use: `(states_score × 0.4) + (devices_score × 0.35) + (scenarios_score × 0.25)`. See REFERENCE.md.
5. **Validate Gherkin after writing** — check syntax, tags, device coverage, vague steps. Fix before proceeding.
6. **Use scoring formula for page selection** — calculate and log score_breakdown in history[]. Do NOT pick pages by intuition.
7. **Track `devices_missing` accurately** — only remove a device when you actually captured it. Never silently delete the field.
8. **`mkdir -p {screenshot_dir}/{feature}/`** BEFORE any browser_take_screenshot
9. **`grep -c "Scenario:"`** for accurate counts — do not count manually
10. **DO NOT PAUSE** between iterations — continue until max_iterations reached
11. **Output `<promise>E2E_COMPLETE</promise>`** when done
```

Replace `{skill_dir}` with the actual skill directory path and `{screenshot_dir}` with the config value.

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
