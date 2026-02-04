---
description: "Cancel E2E reverse engineering session"
allowed-tools: Skill, Read, Bash
---

# Cancel E2E Reverse Engineering Session

## Steps

1. Check if session is active by reading `.claude/ralph-loop.local.md`
2. If active, delegate to `/cancel-ralph` to stop the loop
3. Report final status before cancellation

## Report

```
## E2E Session Cancelled

**Final Status**:
- Iterations completed: {iteration}
- Pages documented: {pages_documented}
- Scenarios written: {scenarios_total}

Feature files saved to: {output_dir}/

To resume later, run `/e2e-reverse start`.
```

## If No Session Active

Report:
```
No active E2E reverse engineering session to cancel.
```
