---
name: e2e-reverse:_check-prerequisites
description: "Validate all prerequisites for e2e-reverse commands"
user-invocable: false
allowed-tools: Read, ToolSearch, Glob
---

# Prerequisite Checker

Validates all prerequisites for e2e-reverse commands and returns structured results.

## Usage

This utility is called automatically by user-invocable commands. Returns a structured result indicating what's missing and what actions to take.

## Checks Performed

### 1. Configuration File Check

Read `.claude/e2e-reverse.config.md`:
- **If exists**: Parse and validate structure
- **If missing**: Flag as prerequisite failure

### 2. Playwright MCP Tools Check

Use ToolSearch to verify Playwright MCP server availability:

Required tools:
- `mcp__plugin_playwright_playwright__browser_navigate`
- `mcp__plugin_playwright_playwright__browser_resize`
- `mcp__plugin_playwright_playwright__browser_snapshot`
- `mcp__plugin_playwright_playwright__browser_take_screenshot`
- `mcp__plugin_playwright_playwright__browser_click`
- `mcp__plugin_playwright_playwright__browser_type`
- `mcp__plugin_playwright_playwright__browser_wait_for`
- `mcp__plugin_playwright_playwright__browser_run_code` (Required for mobile emulation)

Search query: `"select:mcp__plugin_playwright_playwright__browser_navigate"` (or search for each tool individually)

If any tool is unavailable, flag as prerequisite failure.

### 3. Directory Access Check

Verify directories exist or can be created:
- `output_dir` from config (default: `e2e/features`)
- `screenshot_dir` from config (default: `e2e/screenshots`)
- `.claude/` for state files

Use Glob to check if directories exist. If not, note that they'll be created automatically.

## Output Format

Return structured analysis:

```yaml
prerequisites:
  config_file:
    status: "ok" | "missing" | "invalid"
    path: ".claude/e2e-reverse.config.md"
    message: "..." # If not ok

  playwright_tools:
    status: "ok" | "missing" | "partial"
    available: 8 # Count of available required tools
    required: 8
    missing_tools: [] # List if any missing

  directories:
    status: "ok" | "needs_creation"
    output_dir: "e2e/features"
    screenshot_dir: "e2e/screenshots"
    message: "..." # If needs creation

overall_status: "ready" | "blocked"

blocking_issues: [] # List of MUST-FIX items

recommended_actions:
  - "Run `/e2e-reverse setup` to create configuration"
  - "Install Playwright MCP: https://github.com/modelcontextprotocol/servers/tree/main/src/playwright"
```

## Execution Flow

1. **Check config file** (BLOCKING if missing for start/export commands)
2. **Check Playwright tools** (BLOCKING if missing for start command)
3. **Check directories** (NON-BLOCKING - auto-created)
4. **Compile results** into structured output
5. **Return** analysis to calling command

## Error Handling

- If Read fails on config: Flag as missing (not error)
- If ToolSearch fails: Assume Playwright unavailable
- If Glob fails: Assume directory doesn't exist (will be created)

## Integration

Commands should call this utility FIRST before any execution:

```markdown
## Step 0: Validate Prerequisites (MANDATORY)

Call `/e2e-reverse _check-prerequisites` (internal utility).

**If overall_status = "blocked":**
- Display blocking_issues to user
- Display recommended_actions
- STOP execution immediately
- Do NOT proceed with command

**If overall_status = "ready":**
- Continue to next step
```

## Example Usage

**For start command:**
```text
Prerequisites required:
✅ Configuration file
✅ Playwright MCP tools
✅ Directories (auto-created if needed)

If any ❌, command BLOCKS.
```

**For setup command:**
```text
Prerequisites required:
(none - setup creates the config)

Always proceeds.
```

**For export command:**
```text
Prerequisites required:
✅ Configuration file
✅ Feature files exist in output_dir

If any ❌, command BLOCKS.
```
