---
description: "Report E2E reverse engineering progress"
allowed-tools: Read, Glob, Grep
---

# E2E Reverse Engineering Status

## Steps

1. **Read session state** from `.claude/ralph-loop.local.md`
   - If file doesn't exist: "No active E2E session. Run `/e2e-reverse setup` then `/e2e-reverse start`."
   - If exists: extract iteration, status, visit_history, coverage

2. **Read config** from `.claude/e2e-reverse.config.md`
   - Extract max_iterations, output_dir, base_url

3. **Count actual scenarios** across all feature files:
   ```bash
   grep -c "Scenario:" {output_dir}/*.feature
   ```

4. **Calculate simple quality metric**:
   - `quality = scenarios_total / (pages_documented × target_per_feature)`
   - Where `target_per_feature` defaults to config.quality.min_scenarios_per_feature (default: 3)

5. **Display report** to user:

```
## E2E Session Status

**Target**: {base_url}
**Status**: {status} | Iteration {iteration}/{max_iterations} | Session #{session_count}

### Coverage
- Pages discovered: {pages_discovered}
- Pages documented: {pages_documented} ({pages_documented/pages_discovered}%)
- Total scenarios: {scenarios_total} (from grep)

### Quality
- Avg scenarios/feature: {scenarios_total / pages_documented}
- Target: {target_per_feature} scenarios/feature

### Pages
| Page | Status | Visits | Scenarios |
|------|--------|--------|-----------|
| /path | documented | 2 | 6 |

### Next Actions
- Pages needing attention (fewest scenarios)
- Undocumented pages remaining
```
