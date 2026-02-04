# E2E Reverse Engineering - Formula Reference

All quality and scoring calculations in one place for consistency.

## Quality Score Calculation

**IMPORTANT: Score Normalization (2026 Best Practice)**

Quality scores MUST be bounded to [0, 1] range to ensure consistency and prevent invalid values.

```javascript
function calculateQualityScore(page, template) {
  // Get expected coverage from template
  const expectedStates = template.expected_states.length;
  const expectedDevices = template.expected_devices.length;
  const expectedRoles = template.expected_roles.length;

  // Count actual coverage
  const statesCovered = page.coverage.states_covered.length;
  const devicesCovered = page.coverage.devices_covered.length;
  const rolesCovered = page.coverage.roles_covered.length;

  // Calculate component scores (0-1 range)
  const stateCoverage = safeDiv(statesCovered, expectedStates);
  const deviceCoverage = safeDiv(devicesCovered, expectedDevices);
  const roleCoverage = safeDiv(rolesCovered, expectedRoles);
  const scenarioDiversity = calculateScenarioDiversity(page.scenarios); // Already 0-1

  // Apply weights from config
  const weights = config.quality_scoring.weights;

  // Calculate weighted score
  const rawScore = (
    stateCoverage * weights.state_coverage +
    deviceCoverage * weights.device_coverage +
    roleCoverage * weights.role_coverage +
    scenarioDiversity * weights.scenario_diversity
  );

  // CRITICAL: Normalize to [0, 1] range
  return clamp(rawScore, 0, 1);
}

// Helper: Safe division (handles division by zero)
function safeDiv(numerator, denominator) {
  if (denominator === 0) return 0;  // No expected coverage = 0 score
  return Math.min(numerator / denominator, 1.0);  // Cap at 1.0
}

// Helper: Clamp value to range
function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}
```

**Example**:

```javascript
// Given page with:
// - states_covered: ["happy-path", "empty-state", "loading"]  (3 of 4 expected)
// - devices_covered: ["desktop", "mobile"]  (2 of 3 expected)
// - roles_covered: ["anonymous"]  (1 of 1 expected)
// - scenario_diversity: 0.6  (6 of 10 expected tag types)

quality_score = (
  (3/4 × 0.4) +    // 0.3  (state coverage)
  (2/3 × 0.25) +   // 0.167 (device coverage)
  (1/1 × 0.15) +   // 0.15  (role coverage)
  (0.6 × 0.20)     // 0.12  (scenario diversity)
) = 0.737
```

## Coverage Gap Score

```javascript
function calculateCoverageGap(page, template) {
  const statesMissing = template.expected_states.filter(
    s => !page.coverage.states_covered.includes(s)
  );

  const devicesMissing = template.expected_devices.filter(
    d => !page.coverage.devices_covered.includes(d)
  );

  const rolesMissing = template.expected_roles.filter(
    r => !page.coverage.roles_covered.includes(r)
  );

  // Weight by priority
  let gap = 0;
  statesMissing.forEach(state => {
    const def = standard_states[state];
    if (def.priority === 'critical') gap += 0.3;
    else if (def.priority === 'high') gap += 0.2;
    else gap += 0.1;
  });

  devicesMissing.forEach(device => {
    if (template.device_expectations[device] === 'required') gap += 0.2;
    else gap += 0.05;
  });

  rolesMissing.forEach(role => gap += 0.15);

  return Math.min(gap, 1.0); // Cap at 1.0
}
```

**Example**:

```javascript
// Missing:
// - error_network (critical state) = +0.3
// - tablet (optional device) = +0.05
// Total gap = 0.35
```

## Staleness Score

```javascript
function calculateStaleness(page) {
  const daysSinceVisit = (Date.now() - page.last_visited) / (1000 * 60 * 60 * 24);
  const stale_days = config.iteration.stale_days;

  // Decay function: older + lower quality = more stale
  const timeFactor = Math.min(daysSinceVisit / stale_days, 1.0);
  const qualityFactor = 1 - page.quality_score;

  return timeFactor * qualityFactor;
}
```

**Example**:

```javascript
// Page visited 5 days ago, stale_days = 7, quality_score = 0.6
staleness = (5/7) × (1 - 0.6) = 0.714 × 0.4 = 0.286
```

## Scenario Diversity Score

```javascript
function calculateScenarioDiversity(scenarios) {
  const expectedTypes = [
    '@smoke', '@regression', '@edge-case',
    '@happy-path', '@empty-state', '@error', '@loading'
  ];

  // Count unique scenario types present
  const tagSet = new Set();
  scenarios.forEach(s => {
    s.tags.forEach(tag => {
      if (expectedTypes.includes(tag)) tagSet.add(tag);
    });
  });

  return tagSet.size / expectedTypes.length;
}
```

**Example**:

```javascript
// Scenarios with tags: ["@smoke", "@happy-path"], ["@regression", "@empty-state"]
// Unique types found: @smoke, @happy-path, @regression, @empty-state = 4
diversity = 4 / 7 = 0.571
```

## Page Selection Score

```javascript
function calculateSelectionScore(page, template) {
  // Priority mapping
  const priorityScores = {
    critical: 1.0,
    high: 0.75,
    medium: 0.5,
    low: 0.25
  };

  const priority = priorityScores[page.priority] || 0.5;
  const coverageGap = calculateCoverageGap(page, template);
  const staleness = calculateStaleness(page);
  const diversity = 1 - calculateScenarioDiversity(page.scenarios);

  // Weighted combination (70% deterministic)
  const weightedScore = (
    priority * 0.3 +
    coverageGap * 0.3 +
    staleness * 0.2 +
    diversity * 0.2
  );

  // Add randomness (30% random)
  const randomFactor = Math.random() * 0.3;

  return weightedScore + randomFactor;
}
```

**Example**:

```javascript
// Page: priority = critical (1.0), coverage_gap = 0.35, staleness = 0.286, diversity = 0.429
weighted = (1.0 × 0.3) + (0.35 × 0.3) + (0.286 × 0.2) + (0.429 × 0.2)
         = 0.3 + 0.105 + 0.057 + 0.086
         = 0.548

// Add random factor (e.g., 0.15)
final_score = 0.548 + 0.15 = 0.698
```

## Summary Table

| Metric | Range | Higher is Better? | Meaning |
|--------|-------|-------------------|---------|
| quality_score | 0-1 | Yes | Overall page quality/completeness |
| coverage_gap | 0-1 | No | How much coverage is missing |
| staleness | 0-1 | No | Age + low quality = needs revisit |
| diversity | 0-1 | Yes | Variety of scenario types |
| selection_score | 0-1.3 | Yes | Priority for next iteration |

## Configuration Reference

Default values from `.claude/e2e-reverse.config.md`:

```yaml
quality_scoring:
  weights:
    state_coverage: 0.4
    device_coverage: 0.25
    role_coverage: 0.15
    scenario_diversity: 0.20

iteration:
  new_discovery_ratio: 0.7
  stale_days: 7

quality:
  min_scenarios_per_feature: 3
  target_quality_score: 0.75
```

## Usage Guidelines

1. **quality_score** - Guides when to stop documenting a page (target: 0.75-0.85)
2. **coverage_gap** - Identifies what's missing (prioritize gaps > 0.5)
3. **staleness** - Determines revisit priority (revisit when > 0.4)
4. **selection_score** - Chooses next page to document (pick highest)

## Validation

To verify calculations are working correctly:

```javascript
// Test case 1: Perfect coverage
{
  states_covered: all_expected,
  devices_covered: all_expected,
  roles_covered: all_expected,
  scenario_diversity: 1.0
}
// Expected: quality_score = 1.0, coverage_gap = 0.0

// Test case 2: No coverage
{
  states_covered: [],
  devices_covered: [],
  roles_covered: [],
  scenario_diversity: 0.0
}
// Expected: quality_score = 0.0, coverage_gap = 1.0 (or close)

// Test case 3: Partial coverage
{
  states_covered: ["happy-path"],
  devices_covered: ["desktop"],
  roles_covered: ["anonymous"],
  scenario_diversity: 0.3
}
// Expected: quality_score ~0.3-0.4, coverage_gap ~0.6-0.7
```
