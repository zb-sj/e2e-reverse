---
name: e2e-reverse:_validate-gherkin
description: "Internal: Validate Gherkin feature files"
user-invocable: false
allowed-tools: Read
---

# Validate Gherkin

Internal utility for inline validation of Gherkin feature files. Used by Ralph for self-correction during writing.

## Purpose

Enables Ralph to self-validate scenarios as they're written, providing immediate feedback for autonomous quality improvement.

## Input

Takes:
- `feature_file_path`: Path to .feature file to validate
- `config`: Config object (for quality targets)
- `state`: Session state (for coverage expectations)

## Returns

Validation result object:

```yaml
{
  valid: <boolean>,
  errors: [
    {
      type: "syntax" | "convention" | "quality" | "coverage",
      line: <number> | null,
      severity: "error" | "warning",
      message: "<string>",
      suggestion: "<string>",
      auto_fixable: <boolean>
    }
  ],
  warnings: [
    {
      type: "convention" | "quality",
      line: <number> | null,
      message: "<string>",
      suggestion: "<string>"
    }
  ],
  summary: {
    scenario_count: <number>,
    syntax_errors: <number>,
    convention_issues: <number>,
    quality_issues: <number>,
    coverage_gaps: <number>
  }
}
```

## Validation Rules

### 1. Syntax Issues (errors)

**Missing Feature declaration**:
- Check: First non-comment line must contain "Feature:"
- Message: "Missing Feature declaration"
- Suggestion: "Add 'Feature: <name>' at the beginning of the file"

**Scenario without steps**:
- Check: Each Scenario must have at least one step (Given/When/Then/And/But)
- Message: "Scenario '<name>' has no steps"
- Suggestion: "Add at least one Given/When/Then step"

**Invalid tag format**:
- Check: Tags must start with @ and have no spaces
- Examples of invalid: `@tag with spaces`, `@route path` (should be `@route(/path)`)
- Message: "Invalid tag format: '<tag>'"
- Suggestion: "Use '@tag-name' or '@route(/path)' format"

**Inconsistent indentation**:
- Check: Steps should be indented consistently (2 or 4 spaces)
- Message: "Inconsistent indentation at line <line>"
- Suggestion: "Use consistent indentation (2 spaces recommended)"

**Invalid step keyword**:
- Check: Steps must start with Given/When/Then/And/But
- Message: "Invalid step keyword at line <line>"
- Suggestion: "Use Given/When/Then/And/But"

### 2. Convention Issues (warnings)

**Feature without feature-name tag**:
- Check: Feature should have at least one feature-identifying tag (@search, @user-profile, etc.)
- Message: "Feature missing feature-name tag"
- Suggestion: "Add a feature tag like '@search' or '@user-profile'"

**Scenario without priority tag**:
- Check: Scenario should have @smoke, @regression, or @edge-case tag
- Message: "Scenario '<name>' missing priority tag"
- Suggestion: "Add @smoke, @regression, or @edge-case tag"

**Device-specific scenario missing device tag**:
- Check: If scenario name contains "desktop", "mobile", or "tablet", it should have corresponding tag
- Message: "Scenario references device but missing device tag"
- Suggestion: "Add @desktop, @mobile, or @tablet tag"

**Auth scenario missing role tag**:
- Check: Scenarios involving login/auth should have @role() tag
- Message: "Auth scenario missing @role() tag"
- Suggestion: "Add @role(anonymous), @role(user), or @role(admin)"

### 3. Quality Issues (warnings)

**Duplicate scenario names**:
- Check: Scenario names within feature should be unique
- Message: "Duplicate scenario name: '<name>'"
- Suggestion: "Make scenario names unique or use device tags to differentiate"

**Empty scenarios**:
- Check: Scenario has no steps
- Message: "Empty scenario: '<name>'"
- Suggestion: "Add steps or remove scenario"

**Steps with placeholders**:
- Check: Steps containing "TODO", "...", "TBD", "<placeholder>"
- Message: "Placeholder in step at line <line>"
- Suggestion: "Replace placeholder with actual step description"

**Non-specific assertions**:
- Check: Then steps like "Then it works", "Then success", "Then OK"
- Message: "Vague assertion at line <line>"
- Suggestion: "Be specific about expected result (e.g., 'Then search results appear')"

**Vague steps**:
- Check: Steps like "When user does something", "Given something happens"
- Message: "Vague step at line <line>"
- Suggestion: "Be specific about the action or state"

### 4. Coverage Gaps (warnings)

**Feature with too few scenarios**:
- Check: Feature has < min_scenarios_per_feature (from config)
- Message: "Feature has only <n> scenarios (minimum: <min>)"
- Suggestion: "Add more scenarios to cover different states and edge cases"

**No error state scenarios**:
- Check: No scenarios with @error tag
- Message: "Missing error state scenarios"
- Suggestion: "Add scenarios for network errors, validation errors, etc."

**No empty state scenarios**:
- Check: No scenarios with @empty-state tag
- Message: "Missing empty state scenarios"
- Suggestion: "Add scenario for initial/empty data state"

**Missing device coverage**:
- Check: Feature mentions devices but doesn't cover all (desktop, mobile, tablet from config)
- Message: "Missing device coverage: <devices>"
- Suggestion: "Add scenarios or device tags for <devices>"

**Missing role coverage**:
- Check: Feature type (from page_type) expects certain roles but they're not covered
- Message: "Missing role coverage: <roles>"
- Suggestion: "Add scenarios for <roles>"

## Auto-Fix Capability

Some issues can be automatically fixed:

**Auto-fixable**:
- Inconsistent indentation → normalize to 2 spaces
- Missing feature tag → infer from filename
- Missing priority tag → add @regression as default
- Duplicate scenario names → append device or state to differentiate

**Not auto-fixable** (require human/Ralph decision):
- Vague steps
- Placeholder steps
- Coverage gaps
- Missing scenarios

## Usage Example

```markdown
# In start.md, after writing scenario:

Call `/e2e-reverse _validate-gherkin` with:
  feature_file_path: "{output_dir}/search.feature"
  config: config
  state: session

If validation.valid is false:
  For each error in validation.errors:
    If error.auto_fixable:
      Apply auto-fix
    Else:
      Log error for Ralph to address
      Re-write scenario to fix issue

  Update scenario and re-validate
Else:
  Continue to next step
```

## Implementation

Now read the feature file, apply all validation rules, categorize issues by severity, identify auto-fixable issues, and return the validation result object.
