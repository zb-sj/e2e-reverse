---
name: e2e-reverse:_write-checkpoint
description: "Internal: Write checkpoint atomically"
user-invocable: false
allowed-tools: Edit, Write
---

# Write Checkpoint

Internal utility for atomic checkpoint creation. Ensures transactional consistency when pausing or saving session state.

## Purpose

Centralizes checkpoint writing logic to ensure pause.md and auto-checkpointing in start.md use the same reliable mechanism.

## Input

Takes:
- `state`: Complete session state object
- `checkpoint_message`: Optional custom message (default: "Session checkpointed")

## Actions

1. **Update state files atomically (BOTH locations)**
   - **Primary**: Edit `.claude/ralph-loop.local.md`
   - **Backup**: Edit `{output_dir}/.ralph-state.md` (more resilient - inside git-tracked directory)
   - Update session status, iteration, coverage
   - Preserve all visit_history data
   - Use atomic write (write to temp, then rename)

2. **Create checkpoint summary**
   - Write `.claude/e2e-reverse-checkpoint.md`
   - Include timestamp, progress, summary

3. **Verify writes succeeded**
   - Read back ALL THREE files to confirm
   - If primary write failed but backup succeeded, log warning but continue
   - If both state writes failed, return error

## Checkpoint File Format

`.claude/e2e-reverse-checkpoint.md`:

```yaml
---
checkpointed_at: "2026-02-04T10:30:00Z"
iteration: 7
max_iterations: 15
progress: 47%

checkpoint:
  last_page: "/search"
  pages_documented: 8
  pages_pending: 4
  total_scenarios: 42
  avg_quality_score: 0.72

message: "Session checkpointed"
---

# E2E Reverse Engineering Checkpoint

Session checkpointed at iteration 7/15 (47% complete).

## Progress

- **Pages discovered**: 12
- **Pages documented**: 8 (67%)
- **Scenarios written**: 42
- **Average quality**: 0.72 / 1.0

## Last Activity

- **Page**: /search
- **Action**: Added 2 scenarios (error states)
- **Quality improved**: 0.65 → 0.85

## Next Steps

Resume with `/e2e-reverse start` to continue from this checkpoint.

Ralph will automatically detect and resume from this checkpoint.
```

## Atomic Write Strategy

To prevent corruption if interrupted:

1. **Write to temporary files**:
   - `.claude/ralph-loop.local.md.tmp` (primary)
   - `{output_dir}/.ralph-state.md.tmp` (backup)
   - `.claude/e2e-reverse-checkpoint.md.tmp`

2. **Verify writes succeeded**:
   - Check all temp files exist
   - Check file sizes > 0
   - Parse YAML to ensure valid

3. **Atomic rename**:
   - Rename `.tmp` files to actual files
   - Filesystem guarantees atomicity of rename operation
   - If rename fails, temp files remain for debugging
   - **Write backup FIRST** (to output_dir) - this is more resilient

4. **Cleanup on success**:
   - Remove any stale `.tmp` files

## State Recovery on Resume

When starting a session, check for existing state in this order:

1. **Primary**: `.claude/ralph-loop.local.md`
2. **Backup**: `{output_dir}/.ralph-state.md`

Use whichever has the higher iteration number (more recent). If both are missing, start fresh.

## Usage Example

```markdown
# In pause.md or start.md auto-checkpoint

Load current session state via `/e2e-reverse _check-session`

Call `/e2e-reverse _write-checkpoint` with:
  state: session
  checkpoint_message: "Session paused by user"

If write succeeds:
  Tell user: "Checkpoint saved at iteration {iteration}/{max_iterations}"
Else:
  Tell user: "Failed to save checkpoint: {error}"
  Do not mark session as paused
```

## Error Handling

**Write failure**:
```yaml
{
  success: false,
  error: "Failed to write state file: permission denied",
  rollback: "Temporary files removed"
}
```

**Verification failure**:
```yaml
{
  success: false,
  error: "State file write succeeded but verification failed",
  action: "Manual inspection of `.claude/ralph-loop.local.md` required"
}
```

**Success**:
```yaml
{
  success: true,
  checkpoint_path: ".claude/e2e-reverse-checkpoint.md",
  state_path: ".claude/ralph-loop.local.md"
}
```

## Implementation

Now atomically write the checkpoint files with proper error handling and rollback support.
