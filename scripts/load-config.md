---
name: e2e-reverse:_load-config
description: "Internal: Load and validate configuration"
user-invocable: false
allowed-tools: Read
---

# Load Configuration

Internal utility for loading and validating E2E reverse engineering configuration. Centralizes config reading across all commands.

## Purpose

Eliminates duplicate config loading logic in start.md, export.md, status.md, and other commands.

## Returns

Config object with:

```yaml
{
  # Target configuration
  base_url: "<string>",
  output_dir: "<string>",
  screenshot_dir: "<string>",
  max_iterations: <number>,
  language: "ko" | "en",
  ignore_paths: ["<pattern>", ...],

  # URL normalization
  url_normalization: {
    ignore_trailing_slash: <boolean>,
    ignore_query_params: <boolean>,
    ignore_fragments: <boolean>,
    case_sensitive: <boolean>,
    excluded_query_params: ["<param>", ...]
  },

  # Browser timeouts
  timeouts: {
    page_load: <number>,
    element_wait: <number>,
    snapshot: <number>,
    interaction: <number>,
    state_transition: <number>,
    network_idle: <number>
  },

  # Session management
  session_management: {
    reset_between_iterations: <boolean>,
    preserve_auth: <boolean>,
    reset_to_homepage: <boolean>,
    wait_for_idle_after_reset: <number>
  },

  # Performance caching
  cache: {
    enabled: <boolean>,
    reuse_snapshots_within_hours: <number>,
    reuse_screenshots: <boolean>,
    invalidate_on_url_change: <boolean>,
    cache_dir: "<string>"
  },

  # Performance optimization
  performance: {
    state_file_write_interval: <number>,
    checkpoint_on_page_complete: <boolean>
  },

  # Device configurations
  devices: [
    {
      name: "<string>",
      width: <number>,
      height: <number>,
      device: "<string>" | null,
      userAgent: "<string>" | null,
      isMobile: <boolean> | null
    }
  ],

  # Iteration strategy
  iteration: {
    new_discovery_ratio: <number>,
    stale_days: <number>
  },

  # Quality targets
  quality: {
    min_scenarios_per_feature: <number>,
    target_quality_score: <number>
  },

  # Quality scoring weights
  quality_scoring: {
    weights: {
      state_coverage: <number>,
      device_coverage: <number>,
      role_coverage: <number>,
      scenario_diversity: <number>
    }
  },

  # Project context
  project_context: {
    domain: "<string>",
    key_entities: ["<string>", ...],
    terminology: {<key>: "<definition>"},
    business_rules: ["<string>", ...]
  },

  # Validation result
  validation: {
    valid: <boolean>,
    message: "<string>",
    suggestion: "<string>" | null
  }
}
```

## Actions

1. **Read config file**
   - Read `.claude/e2e-reverse.config.md`
   - Handle missing file gracefully

2. **Parse YAML frontmatter**
   - Extract configuration fields
   - Parse nested structures (devices, timeouts, etc.)
   - Extract project context from markdown body

3. **Validate required fields**
   - Check base_url is present
   - Check output_dir is present
   - Check devices array has at least one device
   - Validate numeric ranges (iterations > 0, ratios 0-1, etc.)

4. **Apply defaults**
   - Fill in missing optional fields with sensible defaults
   - Ensure backward compatibility with older config versions

5. **Return normalized object**
   - Include validation status
   - Provide helpful error messages if invalid
   - Suggest remediation steps

## Error Handling

**Missing file**:
```yaml
{
  validation: {
    valid: false,
    message: "Configuration file not found.",
    suggestion: "Run `/e2e-reverse setup` to create configuration."
  }
}
```

**Missing required field**:
```yaml
{
  validation: {
    valid: false,
    message: "Required field 'base_url' is missing from configuration.",
    suggestion: "Edit `.claude/e2e-reverse.config.md` and add 'base_url: \"https://example.com\"' to the YAML frontmatter."
  }
}
```

**Invalid value**:
```yaml
{
  validation: {
    valid: false,
    message: "Invalid value for 'max_iterations': must be greater than 0.",
    suggestion: "Edit `.claude/e2e-reverse.config.md` and set 'max_iterations' to a positive number."
  }
}
```

## Default Values

If optional fields are missing, apply these defaults:

```yaml
max_iterations: 15
language: "ko"
ignore_paths: []

url_normalization:
  ignore_trailing_slash: true
  ignore_query_params: false
  ignore_fragments: true
  case_sensitive: false
  excluded_query_params: []

timeouts:
  page_load: 30000
  element_wait: 10000
  snapshot: 5000
  interaction: 3000
  state_transition: 5000
  network_idle: 2000

session_management:
  reset_between_iterations: true
  preserve_auth: true
  reset_to_homepage: false
  wait_for_idle_after_reset: 2000

cache:
  enabled: true
  reuse_snapshots_within_hours: 24
  reuse_screenshots: false
  invalidate_on_url_change: true
  cache_dir: ".claude/e2e-reverse-cache"

performance:
  state_file_write_interval: 3
  checkpoint_on_page_complete: true

devices:
  - name: "desktop"
    width: 1280
    height: 800
    userAgent: null
    isMobile: false
  - name: "mobile"
    width: 390
    height: 844
    device: "iPhone 14"
    userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    isMobile: true

iteration:
  new_discovery_ratio: 0.7
  stale_days: 7

quality:
  min_scenarios_per_feature: 3
  target_quality_score: 0.75

quality_scoring:
  weights:
    state_coverage: 0.4
    device_coverage: 0.25
    role_coverage: 0.15
    scenario_diversity: 0.20
```

## Usage Example

```markdown
Call `/e2e-reverse _load-config` to load configuration.

If config.validation.valid is false:
  Tell user: config.validation.message
  Tell user: config.validation.suggestion
  Stop execution

Otherwise:
  Continue with config data
  Use config.base_url, config.devices, etc.
```

## Implementation

Now read `.claude/e2e-reverse.config.md`, parse it, validate it, apply defaults, and return the normalized config object.
