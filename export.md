---
description: "Export E2E reverse engineering report"
allowed-tools: Skill, Write
argument-hint: "[--format markdown|json|html]"
---

# Export E2E Report

Generate a comprehensive report of the reverse engineering session using utility commands.

## Actions

1. **Parse arguments**
   - Extract format: markdown (default), json, or html
   - Usage: `/e2e-reverse export` or `/e2e-reverse export --format json`

2. **Gather data using utilities**
   - Call `/e2e-reverse _check-session` for session state
   - Call `/e2e-reverse _load-config` for configuration
   - Call `/e2e-reverse _list-features` for feature file inventory

3. **Calculate metrics**
   - Call `/e2e-reverse _calculate-metrics` with session state and config

4. **Generate report based on format**
   - Select template from [references/REPORTING.md](references/REPORTING.md#export-report-templates)
   - Populate variables with data from utilities
   - Write to `.claude/e2e-reverse-report.{format}`

5. **Confirm to user**
   - "Report exported to `.claude/e2e-reverse-report.{format}`"
   - Show summary: "{pages_documented} pages, {scenarios_total} scenarios, quality {avg_quality_score.toFixed(2)}"

## Report Templates

See [REPORTING.md - Export Report Templates](references/REPORTING.md#export-report-templates) for complete formats:
   ```markdown
   # E2E Reverse Engineering Report

   **Generated**: {timestamp}
   **Session Status**: {status}
   **Iterations**: {iteration}/{max_iterations}

   ## Summary

   - Total Pages Discovered: {pages_discovered}
   - Pages Documented: {pages_documented}
   - Total Scenarios: {scenarios_total}
   - Average Quality Score: {avg_quality_score} / 1.0

   ## Quality Breakdown

   | Quality Range | Pages | Percentage |
   |---------------|-------|------------|
   | 0.85+ (Excellent) | 3 | 25% |
   | 0.70-0.84 (Good) | 4 | 33% |
   | 0.50-0.69 (Fair) | 2 | 17% |
   | <0.50 (Needs Work) | 3 | 25% |

   ## Coverage Detail

   | Page | Priority | Quality | Visits | Scenarios | Coverage Gaps |
   |------|----------|---------|--------|-----------|---------------|
   | /search | critical | 0.90 | 2 | 6 | tablet device |
   | /apt/:id | high | 0.65 | 1 | 3 | mobile, error states, user role |

   ## Recommendations

   - Revisit 3 pages with quality < 0.50
   - Add missing error state scenarios across 5 pages
   - Document mobile variants for 4 pages

   ## Feature Files

   - search.feature (6 scenarios, quality: 0.90)
   - apartment-detail.feature (3 scenarios, quality: 0.65)

   ## Configuration

   - Base URL: {base_url}
   - Devices: {device_names}
   - Language: {language}
   ```

   **JSON format** (`.claude/e2e-reverse-report.json`):
   ```json
   {
     "generated_at": "ISO8601",
     "session": {
       "status": "running",
       "iteration": 7,
       "max_iterations": 15
     },
     "coverage": {
       "pages_discovered": 12,
       "pages_documented": 8,
       "scenarios_total": 42,
       "avg_quality_score": 0.72
     },
     "quality_distribution": {
       "excellent": 3,
       "good": 4,
       "fair": 2,
       "needs_work": 3
     },
     "pages": [
       {
         "path": "/search",
         "priority": "critical",
         "quality_score": 0.90,
         "scenarios": 6,
         "coverage_gap_score": 0.10,
         "coverage": {
           "states_covered": ["happy-path", "empty-state", "error", "loading"],
           "devices_covered": ["desktop", "mobile"],
           "roles_covered": ["anonymous", "user"]
         }
       }
     ],
     "feature_files": [
       {
         "path": "e2e/features/search.feature",
         "scenarios": 6
       }
     ],
     "recommendations": [...]
   }
   ```

   **HTML format** (`.claude/e2e-reverse-report.html`):
   - Full styled report with tables
   - Progress indicators for quality scores
   - Sortable/filterable tables
   - Links to feature files

5. **Save report**
   - Write to `.claude/e2e-reverse-report.{format}`
   - Confirm to user: "Report exported to {path}"
   - Show summary stats in confirmation
