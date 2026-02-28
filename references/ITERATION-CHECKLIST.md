# Iteration Checklist

Print "✓ STEP N" after completing each step. Do NOT proceed to step N+1 without confirming step N.

## Every Iteration (new page OR revisit)

### STEP 1: NAVIGATE
- [ ] `browser_navigate` to target URL
- [ ] Store URL for later reset
- Print: `✓ STEP 1: Navigated to {url}`

### STEP 2: CAPTURE (all devices)
- [ ] Desktop: `browser_resize(1280,800)` → `browser_snapshot` → `browser_take_screenshot`
- [ ] Mobile: `browser_close()` → `browser_navigate` → UA injection → `browser_take_screenshot`
- [ ] Reset: `browser_close()` → `browser_navigate` → `browser_resize(1280,800)`
- Print: `✓ STEP 2: Captured {N} devices` (must equal config.devices count)

### STEP 3: EXPLORE (minimum 3 interactions)
- [ ] Click/interact with element 1 → screenshot
- [ ] Click/interact with element 2 → screenshot
- [ ] Click/interact with element 3 → screenshot
- Print: `✓ STEP 3: Explored {N} elements: {list}`
- **GATE: If N < 3, go back and interact with more elements**

### STEP 4: DOCUMENT
- [ ] Write/update .feature file
- [ ] Run validation (print each check result):
  1. Feature declaration with description?
  2. Every Scenario has Given/When/Then?
  3. No duplicate scenario names?
  4. Feature has @route() tag, scenarios have priority tags?
  5. Device coverage adequate?
  6. No vague steps?
  7. No When after Then within a scenario?
- [ ] Scan for Scenario Outline candidates (3+ scenarios with same structure)
- [ ] `grep -c "Scenario:" {file}` → store count
- Print: `✓ STEP 4: {file} validated, {N} scenarios, {M} outlines`

### STEP 5: UPDATE STATE
- [ ] Calculate quality_score:
  - states_score = {states_covered}/{expected_states(cap 3)}
  - devices_score = {devices_covered}/{config.devices.count}
  - scenarios_score = min({scenario_count}/{min_scenarios}, 1.0)
  - quality = (states×0.4) + (devices×0.35) + (scenarios×0.25) = {result}
- [ ] Write .claude/ralph-loop.local.md (full rewrite)
- [ ] Copy to {output_dir}/.ralph-state.md
- Print: `✓ STEP 5: State updated, quality={score}`

### STEP 6: SELECT NEXT
- [ ] Calculate scores for all candidates with random(0, 0.3) component
- [ ] Log score_breakdown in history[]
- [ ] DO NOT set status="completed" unless iteration == max_iterations
- Print: `✓ STEP 6: Next → {page} (score={final})`
- **Immediately start next iteration. No summaries. No pausing.**
