---
description: "Initialize E2E reverse engineering for a project"
allowed-tools: Read, Write, AskUserQuestion
---

# E2E Reverse Engineering Setup

**MANDATORY WORKFLOW - Follow these steps in order:**

## Step 1: Check for Existing Config (REQUIRED FIRST)

Before doing anything else, use the Read tool to check if `.claude/e2e-reverse.config.md` already exists.

- If it exists: Ask user if they want to reconfigure or keep existing config
- If it doesn't exist: Proceed to Step 2

## Step 2: Gather Configuration (BLOCKING REQUIREMENT)

**IMMEDIATE ACTION - Execute this tool call NOW before reading further:**

You MUST call the AskUserQuestion tool as your next action. Do not proceed to Step 3 until you receive user answers.

**EXECUTION GUARDRAIL**: The configuration file in Step 3 requires data from AskUserQuestion. Without calling this tool, you cannot complete setup. There is no alternative path.

Call AskUserQuestion with this exact structure:

```json
AskUserQuestion with questions:
[
  {
    question: "What is the base URL of the application you want to reverse-engineer?",
    header: "Base URL",
    multiSelect: false,
    options: [
      { label: "http://localhost:3000 (Recommended)", description: "Default local development server" },
      { label: "http://localhost:8080", description: "Alternative local port" },
      { label: "Custom URL", description: "I'll specify a different URL" }
    ]
  },
  {
    question: "Where should the Gherkin feature files be saved?",
    header: "Output Dir",
    multiSelect: false,
    options: [
      { label: "e2e/features (Recommended)", description: "Standard E2E test directory" },
      { label: "tests/features", description: "Alternative test directory" },
      { label: "Custom path", description: "I'll specify a different location" }
    ]
  },
  {
    question: "What language should be used for scenario descriptions?",
    header: "Language",
    multiSelect: false,
    options: [
      { label: "Korean (Recommended)", description: "한국어로 시나리오 작성" },
      { label: "English", description: "Write scenarios in English" }
    ]
  },
  {
    question: "Which device configurations should be captured?",
    header: "Devices",
    multiSelect: true,
    options: [
      { label: "Desktop (Recommended)", description: "1280x800 desktop viewport — reliable and fast" },
      { label: "Mobile", description: "iPhone 14 (390x844) — adds mobile capture with UA emulation, slower" },
      { label: "Tablet", description: "iPad Air (820x1180) — adds tablet capture with UA emulation, slower" }
    ]
  }
]
```

## Step 2.5: Follow-up Domain Context (OPTIONAL but RECOMMENDED)

After receiving answers from AskUserQuestion in Step 2, you may ask follow-up questions for domain context if the user selected "Custom URL" or if additional context would be helpful:

- "What does this application do? (Brief description of the domain/purpose)"
- "Are there any domain-specific terms or terminology I should know?"

If user provided standard answers, you can proceed directly to Step 3.

**Note**: Skip advanced options (URL normalization, timeouts) unless user explicitly requests them. Defaults work for 95% of cases.

## Step 3: Resolve Ralph Loop Skill (BLOCKING REQUIREMENT)

**CRITICAL**: Discover the correct Ralph Loop skill name in this environment before creating config.

**Why this matters**: The Ralph Loop skill name may vary across different user environments (e.g., `ralph-loop:ralph-loop`, `ralph-loop`, or other variants). We must resolve the correct name dynamically.

**Implementation Steps**:

1. **Check available skills**: Look in the most recent `<system-reminder>` tag in the conversation for the section titled "The following skills are available for use with the Skill tool"

2. **Search for Ralph Loop**: Find skills containing "ralph" or "loop" in their names

3. **Identify the correct skill**: Look for a skill with description containing "Start Ralph Loop" or "ralph loop" (case-insensitive)
   - The skill name format is typically `ralph-loop:ralph-loop` or similar
   - It may also be listed as just `ralph-loop` in some environments

4. **Store the resolved name**: Save the full skill name exactly as it appears in the list

**Example from system-reminder**:
```text
- ralph-loop:help: Explain Ralph Loop plugin and available commands
- ralph-loop:cancel-ralph: Cancel active Ralph Loop
- ralph-loop:ralph-loop: Start Ralph Loop in current session  ← THIS ONE
```

In this case, the skill name to store is: `ralph-loop:ralph-loop`

**If Ralph Loop skill is NOT found:**

Display this error to the user:

```
❌ PREREQUISITE FAILED: Ralph Loop plugin not available

REQUIRED ACTION:
Install the Ralph Loop plugin to enable autonomous exploration.

Installation: Follow Ralph Loop setup instructions for your environment.

Cannot proceed without Ralph Loop. Setup stopped.
```

Then STOP execution immediately.

**If Ralph Loop skill is found:**

Continue to Step 4 with the resolved skill name.

## Step 4: Create Config File (ONLY AFTER Receiving Answers AND Resolving Skill)

**PREREQUISITE CHECK**:
- Do you have user answers from AskUserQuestion in Step 2? → If NO: Go back to Step 2
- Do you have the Ralph Loop skill name from Step 3? → If NO: Go back to Step 3
- If YES to both: Proceed below

After gathering user input from AskUserQuestion and resolving the Ralph Loop skill name, use the Write tool to create `.claude/e2e-reverse.config.md` with the user's configuration.

**Mapping user answers to config:**

- Base URL answer → `base_url` field
- Output Dir answer → `output_dir` field
- Language answer (Korean/English) → `language` field ("ko" or "en")
- Devices answer (multiSelect) → `devices` array (include selected devices)
- Ralph Loop skill name from Step 3 → `ralph_loop_skill` field

## Config File Format

Create `.claude/e2e-reverse.config.md` with this structure:

```yaml
---
ralph_loop_skill: "ralph-loop:ralph-loop"
base_url: "https://example.com"
output_dir: "e2e/features"
screenshot_dir: "e2e/screenshots"
max_iterations: 15
language: "ko"
ignore_paths: ["/admin/*", "/debug/*"]

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

devices:
  - name: "desktop"
    width: 1280
    height: 800
  - name: "mobile"
    width: 390
    height: 844
    device: "iPhone 14"
  - name: "tablet"
    width: 820
    height: 1180
    device: "iPad Air"

iteration:
  new_discovery_ratio: 0.7
  stale_days: 7

quality:
  min_scenarios_per_feature: 3
  target_quality_score: 0.75
---

# Project Context

## Domain
[Description of what the app does]

## Terminology
- term1 = definition1
- term2 = definition2
```

## Step 5: Mobile Device Configuration (OPTIONAL)

**If user selected Mobile or Tablet devices**, you may optionally mention:

```
✅ Config saved successfully!

Note: Mobile emulation uses best-effort mode by default (70-80% effective).
This works for most responsive sites.

If you encounter mobile-specific issues, you can configure native device emulation:
- Edit Claude Desktop config: ~/Library/Application Support/Claude/claude_desktop_config.json
- Add Playwright MCP with --device flag (see setup.md for details)
- Restart Claude Code

Most users won't need this. Only configure if you see issues.
```

**If user only selected Desktop**, skip this message entirely.

## Step 6: Confirm Success

After completing all steps, inform the user with a success message that includes:

- Config file location: `.claude/e2e-reverse.config.md`
- Ralph Loop skill resolved: `{skill_name}`
- They can edit the config manually to fine-tune settings
- If mobile/tablet selected, they may optionally configure Playwright MCP server for native emulation (see Step 5)
- Next steps: Run `/e2e-reverse start` to begin exploration
