---
description: "Report E2E reverse engineering progress"
allowed-tools: Skill
---

# E2E Reverse Engineering Status

Report current session progress using utility commands.

## Actions

1. **Load session state**
   - Call `/e2e-reverse _check-session`
   - If session.validation.valid is false:
     - Tell user: session.validation.message
     - Tell user: session.validation.suggestion
     - Stop execution

2. **Calculate metrics**
   - Call `/e2e-reverse _calculate-metrics` with session state

3. **List features**
   - Call `/e2e-reverse _list-features` for feature file inventory

4. **Generate report**
   - Use template from [references/REPORTING.md](references/REPORTING.md#status-report-template)
   - Populate with data from utilities
   - Display to user

## Report Template

See [REPORTING.md - Status Report Template](references/REPORTING.md#status-report-template) for complete format.

**Key sections**:
- Session status and progress
- Coverage metrics (pages, scenarios)
- Quality distribution
- Page status table
- Next actions (pages needing attention)
- Feature files list
