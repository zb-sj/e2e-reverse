---
name: e2e-reverse:_calculate-metrics
description: "Internal: Calculate quality and coverage metrics"
user-invocable: false
allowed-tools: Read
---

# Calculate Metrics

Internal utility for calculating quality scores and coverage metrics. Implements algorithms from references/FORMULAS.md.

## Purpose

Centralizes metric calculations to ensure consistency across status.md, export.md, and validate.md commands.

## Input

Takes:
- `visit_history` object from state file
- `config` object (for quality targets and expectations)

## Returns

Metrics object with:

```yaml
{
  # Overall counts
  pages_discovered: <number>,
  pages_documented: <number>,
  pages_pending: <number>,
  scenarios_total: <number>,

  # Quality metrics
  avg_quality_score: <number>,  # 0-1 scale

  # Quality distribution
  quality_distribution: {
    excellent: <number>,    # quality >= 0.85
    good: <number>,         # quality >= 0.70
    fair: <number>,         # quality >= 0.50
    needs_work: <number>    # quality < 0.50
  },

  # Coverage analysis
  coverage_gaps: [
    {
      page: "<path>",
      priority: "critical" | "high" | "medium" | "low",
      quality_score: <number>,
      coverage_gap_score: <number>,
      missing_states: ["<state>", ...],
      missing_devices: ["<device>", ...],
      missing_roles: ["<role>", ...],
      recommendation: "<string>"
    }
  ],

  # Pages needing attention (sorted by urgency)
  pages_to_revisit: [
    {
      page: "<path>",
      reason: "<string>",
      urgency_score: <number>,
      quality_score: <number>
    }
  ],

  # Scenario diversity
  scenario_diversity: {
    overall: <number>,     # 0-1 scale
    by_type: {
      "@smoke": <number>,
      "@regression": <number>,
      "@edge-case": <number>,
      "@happy-path": <number>,
      "@empty-state": <number>,
      "@error": <number>,
      "@loading": <number>
    }
  }
}
```

## Algorithms

### 1. Quality Score Calculation

Per references/FORMULAS.md (lines 7-34):

```javascript
function calculateQualityScore(page, template) {
  const stateCoverage = page.coverage.states_covered.length / template.expected_states.length
  const deviceCoverage = page.coverage.devices_covered.length / template.expected_devices.length
  const roleCoverage = page.coverage.roles_covered.length / template.expected_roles.length
  const scenarioDiversity = calculateScenarioDiversity(page.scenarios)

  const weights = config.quality_scoring.weights

  return (
    stateCoverage * weights.state_coverage +
    deviceCoverage * weights.device_coverage +
    roleCoverage * weights.role_coverage +
    scenarioDiversity * weights.scenario_diversity
  )
}
```

### 2. Coverage Gap Score

Per references/FORMULAS.md (lines 54-88):

```javascript
function calculateCoverageGap(page, template) {
  const statesMissing = template.expected_states.filter(
    s => !page.coverage.states_covered.includes(s)
  )
  const devicesMissing = template.expected_devices.filter(
    d => !page.coverage.devices_covered.includes(d)
  )
  const rolesMissing = template.expected_roles.filter(
    r => !page.coverage.roles_covered.includes(r)
  )

  let gap = 0
  statesMissing.forEach(state => {
    const priority = standard_states[state].priority
    if (priority === 'critical') gap += 0.3
    else if (priority === 'high') gap += 0.2
    else gap += 0.1
  })

  devicesMissing.forEach(device => {
    if (template.device_expectations[device] === 'required') gap += 0.2
    else gap += 0.05
  })

  rolesMissing.forEach(role => gap += 0.15)

  return Math.min(gap, 1.0)
}
```

### 3. Scenario Diversity

Per references/FORMULAS.md (lines 122-140):

```javascript
function calculateScenarioDiversity(scenarios) {
  const expectedTypes = [
    '@smoke', '@regression', '@edge-case',
    '@happy-path', '@empty-state', '@error', '@loading'
  ]

  const tagSet = new Set()
  scenarios.forEach(s => {
    s.tags.forEach(tag => {
      if (expectedTypes.includes(tag)) tagSet.add(tag)
    })
  })

  return tagSet.size / expectedTypes.length
}
```

### 4. Page Selection Score

Per references/FORMULAS.md (lines 150-180):

```javascript
function calculateSelectionScore(page, template) {
  const priorityScores = {
    critical: 1.0,
    high: 0.75,
    medium: 0.5,
    low: 0.25
  }

  const priority = priorityScores[page.priority] || 0.5
  const coverageGap = calculateCoverageGap(page, template)
  const staleness = calculateStaleness(page)
  const diversity = 1 - calculateScenarioDiversity(page.scenarios)

  const weightedScore = (
    priority * 0.3 +
    coverageGap * 0.3 +
    staleness * 0.2 +
    diversity * 0.2
  )

  return weightedScore
}
```

## Implementation

1. **Read state file** using `/e2e-reverse _check-session`
2. **Load config** using `/e2e-reverse _load-config`
3. **Calculate metrics** for each page in visit_history:
   - Quality score
   - Coverage gap
   - Scenario diversity
4. **Aggregate totals**:
   - Count pages by status
   - Count total scenarios
   - Calculate average quality
   - Generate quality distribution
5. **Identify coverage gaps**:
   - Find pages with low quality
   - List missing states/devices/roles
   - Sort by urgency
6. **Return metrics object**

## Usage Example

```markdown
Call `/e2e-reverse _calculate-metrics` to compute metrics.

Display summary:
- Pages documented: {metrics.pages_documented} / {metrics.pages_discovered}
- Average quality: {metrics.avg_quality_score.toFixed(2)}
- Scenarios total: {metrics.scenarios_total}

Show quality distribution:
- Excellent (≥0.85): {metrics.quality_distribution.excellent} pages
- Good (≥0.70): {metrics.quality_distribution.good} pages
- Fair (≥0.50): {metrics.quality_distribution.fair} pages
- Needs work (<0.50): {metrics.quality_distribution.needs_work} pages

List coverage gaps:
For each gap in metrics.coverage_gaps:
  - {gap.page}: quality {gap.quality_score}, missing {gap.missing_states.join(', ')}
```

## Implementation

Now calculate all metrics according to the algorithms from references/FORMULAS.md and return the normalized metrics object.
