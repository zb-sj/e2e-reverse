# Ralph Core Loop

**RULE ZERO: Execute ALL iterations 1 through max_iterations. There is NO early exit. Not when "all pages are documented." Not when "coverage is good." Not for "diminishing returns." The ONLY stop condition is `iteration >= max_iterations`.**

Read this file at the start of each iteration. Mission: reverse-engineer the app into Gherkin so detailed another AI could recreate it.

## 1. NAVIGATE

`browser_navigate` to the target page URL. Clear cookies/storage if configured.

## 2. CAPTURE — All devices + interactions (MANDATORY)

```bash
mkdir -p {screenshot_dir}/{feature}/
```

**Phase A — Desktop** (width >= 768): For each desktop device: `browser_resize` → `browser_snapshot` → `browser_take_screenshot`

**Phase B — Mobile/tablet** (width < 768): For each: `browser_resize` → `browser_run_code` with UA injection from [BROWSER-EXAMPLES.md](BROWSER-EXAMPLES.md) "Mobile View - Option B" → `browser_snapshot` + `browser_take_screenshot`

**Phase C — Reset**: `browser_close()` → `browser_navigate(target_url)` → `browser_resize(1280, 800)`. `addInitScript()` stacks permanently — `browser_close()` is the ONLY reset.

**Phase D — Interact with 3+ elements**: Click tabs, filters, buttons, inputs. Screenshot each result → `{feature}/{interaction-name}.desktop.png`. Note what changed. Target: active/expanded, loading, empty-state, error, partial states. On revisits: 3+ NEW elements not in existing scenarios.

Store: `interactions_captured: ["clicked X", "opened Y", "typed Z"]`

**⚠️ Capture ALL devices on new pages AND revisits. Never defer mobile.**

## 3. DOCUMENT — Write Gherkin

- One feature per file (kebab-case). Check if file exists → READ first → ADD new scenarios
- Background for repeated Given steps. Device tags where behavior differs
- Scan for 3+ similar scenarios → convert to Scenario Outline with Examples table
- Check for `When` after `Then` within same scenario → fix immediately

**After writing, run grep:**

```bash
grep -c "Scenario:" {output_dir}/{feature-name}.feature
grep -c "Scenario Outline:" {output_dir}/{feature-name}.feature
```

Use exact grep output for counts. Do not count manually.

## 4. UPDATE — Write state file (EVERY iteration)

Write full state to `.claude/ralph-loop.local.md` (Write tool, full rewrite) + backup to `{output_dir}/.ralph-state.md`.

**Fill from actual data:**

```yaml
scenario_count: 8        # ← from: grep -c "Scenario:" {file}
outline_count: 1         # ← from: grep -c "Scenario Outline:" {file}
devices_captured: [desktop, mobile]  # ← actual devices from Phase A+B
interactions_captured: ["clicked X", "opened Y", "typed Z"]  # ← from Phase D
quality_score: 0.80      # ← (has_mobile + has_interactions + has_scenarios + has_outline + has_valid_gherkin) / 5
```

| Boolean | Condition |
|---------|-----------|
| has_mobile | "mobile" in devices_captured |
| has_interactions | interactions_captured.length >= 3 |
| has_scenarios | scenario_count >= 5 |
| has_outline | outline_count >= 1 |
| has_valid_gherkin | no When-after-Then found |

Only valid scores: 0.0, 0.2, 0.4, 0.6, 0.8, 1.0

Update: `iteration`, `status: running`, `visit_history`, `coverage.scenarios_total`, `coverage.avg_quality_score`

## 5. SELECT — Pick next page

Score each candidate: `final = (priority × 0.3) + (coverage_gap × 0.3) + (staleness × 0.2) + (diversity × 0.2) + random(0, 0.3)`. Log score_breakdown in history[].

Separate undocumented vs documented pools. Use new_discovery_ratio to pick pool, then highest score.

**When no undocumented pages remain**: MUST revisit lowest quality_score page. There is NO early exit.

**Immediately start the next iteration.**

## Revisit Protocol

Same 5 steps, no shortcuts. Recapture all devices + 3 NEW interactions. Add NEW scenarios. A revisit adding zero scenarios is wasted — try invalid inputs, loading states, edge cases.

## Continuous Execution

```pseudocode
while (current_iteration <= max_iterations) {
  navigate → capture_and_interact → document_gherkin → update_state → select_next
  current_iteration++
}
output("<promise>E2E_COMPLETE</promise>")
```

NEVER pause, summarize, wait for input, or set status="completed" before max_iterations.

`<promise>E2E_COMPLETE</promise>` outputs ONLY when `iteration >= max_iterations`.
