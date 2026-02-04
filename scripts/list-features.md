---
name: e2e-reverse:_list-features
description: "Internal: List and analyze feature files"
user-invocable: false
allowed-tools: Read, Glob, Grep
---

# List Feature Files

Internal utility for discovering and analyzing generated feature files. Centralizes feature file operations across status, export, and validate commands.

## Purpose

Eliminates duplicate globbing and scenario counting logic across multiple commands.

## Returns

Array of feature file objects:

```yaml
[
  {
    path: "<absolute_path>",
    name: "<feature_name>",
    scenario_count: <number>,
    tags: ["@feature-tag", "@route(/path)", ...],
    quality_score: <number> | null,  # from state file if available
    last_updated: "<ISO8601>",
    file_size: <number>
  }
]
```

## Actions

1. **Load config** to get output_dir
   - Call `/e2e-reverse _load-config`
   - Extract output_dir path

2. **Glob feature files**
   - Pattern: `{output_dir}/**/*.feature`
   - Returns all `.feature` files recursively

3. **Analyze each file**:
   - **Read file** to get contents
   - **Count scenarios**: grep lines starting with "Scenario:"
   - **Extract tags**: grep lines starting with "@" at Feature level
   - **Extract feature name**: Parse "Feature: <name>" line
   - **Get file metadata**: last modified timestamp, size

4. **Correlate with state file** (optional):
   - Load visit_history from state file
   - Match feature file to page based on naming convention
   - Include quality_score if available

5. **Return sorted array**:
   - Sort by name alphabetically
   - Include all metadata

## Scenario Counting

Count all lines matching these patterns:

```
Scenario: <description>
Scenario Outline: <description>
```

Ignore commented scenarios:

```
# Scenario: <description>  <- skip this
```

## Tag Extraction

Extract feature-level tags from lines like:

```gherkin
@search @route(/search)
Feature: Search Functionality
```

Result: `tags: ["@search", "@route(/search)"]`

## Usage Example

```markdown
Call `/e2e-reverse _list-features` to get feature inventory.

Display feature list:
For each feature in features:
  - {feature.name}: {feature.scenario_count} scenarios
  - Tags: {feature.tags.join(', ')}
  - Quality: {feature.quality_score || 'N/A'}
  - Path: {feature.path}

Total features: {features.length}
Total scenarios: {sum of all scenario_counts}
```

## Error Handling

**No features found**:
```yaml
[]  # Return empty array, not an error
```

**Invalid feature file** (missing Feature: declaration):
```yaml
{
  path: "<path>",
  name: "INVALID",
  scenario_count: 0,
  tags: [],
  error: "Missing Feature declaration"
}
```

## Performance Optimization

- Cache results for 60 seconds to avoid redundant file reads
- Only re-scan if:
  - More than 60 seconds elapsed
  - Feature file write detected (if possible to hook)
- Use parallel file reads where possible

## Implementation

Now glob feature files, analyze each one, correlate with state, and return the feature inventory array.
