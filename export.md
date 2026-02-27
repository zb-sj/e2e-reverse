---
description: "Export E2E reverse engineering report"
allowed-tools: Read, Write, Glob, Grep
argument-hint: "[--format markdown|json|html]"
---

# Export E2E Report

Generate a comprehensive report of the reverse engineering session.

## Steps

1. **Parse arguments**: Extract format (markdown default, json, or html)

2. **Gather data**:
   - Read `.claude/ralph-loop.local.md` for session state
   - Read `.claude/e2e-reverse.config.md` for configuration
   - List feature files in output_dir with `Glob`
   - Count scenarios per file: `grep -c "Scenario:" {file}` for each

3. **Calculate metrics**:
   - `pages_documented`: count of feature files
   - `scenarios_total`: sum of grep counts
   - `avg_scenarios_per_feature`: scenarios_total / pages_documented
   - `quality`: min(avg_scenarios_per_feature / target_per_feature, 1.0)

4. **Generate report** using template from [references/REPORTING.md](references/REPORTING.md)

5. **Write report** to `.claude/e2e-reverse-report.{format}`

6. **Confirm**: "Report exported to {path}" with summary stats

## Quick Template (Markdown)

```markdown
# E2E Reverse Engineering Report

**Generated**: {timestamp}
**Target**: {base_url}
**Status**: {status} | Iterations: {iteration}/{max_iterations}

## Summary

- Pages Documented: {pages_documented} / {pages_discovered}
- Total Scenarios: {scenarios_total}
- Avg Scenarios/Feature: {avg_scenarios_per_feature}

## Coverage Detail

| Page | Visits | Scenarios | Status |
|------|--------|-----------|--------|
| /search | 2 | 6 | documented |

## Feature Files

| File | Scenarios |
|------|-----------|
| search.feature | 6 |

## Recommendations

- Pages with fewest scenarios need revisiting
- Undocumented pages remaining: {count}
```

See [REPORTING.md](references/REPORTING.md) for JSON and HTML templates.
