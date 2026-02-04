---
name: e2e-reverse:_check-session
description: "Internal: Check session status and load state"
user-invocable: false
allowed-tools: Read
---

# Check Session Status

Internal utility for session management commands. Reads and validates the Ralph loop state file.

## Purpose

Centralizes session status validation to eliminate duplication across pause, resume, cancel, and status commands.

## Returns

Session object with:

```yaml
{
  # Core session state
  status: "running" | "paused" | "stopped" | "completed",
  iteration: <number>,
  max_iterations: <number>,
  started_at: "<ISO8601>",
  paused_at: "<ISO8601>" | null,

  # Coverage metrics
  coverage: {
    pages_discovered: <number>,
    pages_documented: <number>,
    scenarios_total: <number>,
    avg_quality_score: <number>
  },

  # Visit history
  visit_history: {
    "<page_path>": {
      visit_count: <number>,
      last_visited: "<ISO8601>",
      status: "pending" | "documented" | "in-progress",
      priority: "critical" | "high" | "medium" | "low",
      page_type: "entry-point" | "feature" | "utility",
      scenarios: [...],
      coverage: {...},
      quality_score: <number>
    }
  },

  # Validation result
  validation: {
    valid: <boolean>,
    message: "<string>",
    suggestion: "<string>" | null
  }
}
```

## Actions

1. **Read state file**
   - Read `.claude/ralph-loop.local.md`
   - Handle missing file gracefully

2. **Parse YAML frontmatter**
   - Extract session state
   - Parse visit_history structure
   - Extract coverage metrics

3. **Validate state**
   - Check status is valid enum value
   - Verify iteration <= max_iterations
   - Validate timestamps are ISO8601
   - Check visit_history structure

4. **Return normalized object**
   - Include validation status
   - Provide helpful error messages if invalid
   - Suggest remediation steps

## Error Handling

**Missing file**:
```yaml
{
  validation: {
    valid: false,
    message: "No active E2E reverse engineering session.",
    suggestion: "Run `/e2e-reverse start` to begin a new session."
  }
}
```

**Corrupted file**:
```yaml
{
  validation: {
    valid: false,
    message: "State file is corrupted or invalid.",
    suggestion: "Delete `.claude/ralph-loop.local.md` and run `/e2e-reverse start` to begin fresh."
  }
}
```

**Invalid status**:
```yaml
{
  validation: {
    valid: false,
    message: "Session status '<status>' is not recognized.",
    suggestion: "Expected: running, paused, stopped, or completed."
  }
}
```

## Usage Example

```markdown
Call `/e2e-reverse _check-session` to load session state.

If session.validation.valid is false:
  Tell user: session.validation.message
  Tell user: session.validation.suggestion
  Stop execution

Otherwise:
  Continue with session data
```

## Implementation

Now read `.claude/ralph-loop.local.md`, parse it, validate it, and return the normalized session object.
