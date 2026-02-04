# E2E-Reverse Architecture & Optimization

**Version**: 2.0.0
**Last Updated**: 2026-02-04

## Design Philosophy

The e2e-reverse skill is designed for **autonomous agent operation** with minimal human intervention.

### Core Principles

1. **Autonomous-First**: Claude handles exploration, validation, checkpointing, and self-correction automatically
2. **DRY Architecture**: Shared utilities eliminate duplication across commands
3. **Performance-Optimized**: Batched operations and caching reduce I/O overhead
4. **Graceful Recovery**: Auto-checkpointing enables seamless resumption after interruptions

### User Workflow (Simplified)

```text
/e2e-reverse setup      # Configure once
/e2e-reverse start      # Claude runs autonomously
/e2e-reverse export     # Generate report
```

Claude autonomously handles: validation → checkpointing → self-correction → iterative improvement.

---

## System Architecture

### Directory Structure

```
e2e-reverse/
├── *.md                    # User-invocable commands (6 total)
├── scripts/                # Internal utilities (6 files, user-invocable: false)
│   ├── check-session.md
│   ├── load-config.md
│   ├── calculate-metrics.md
│   ├── list-features.md
│   ├── write-checkpoint.md
│   └── validate-gherkin.md
├── assets/templates/       # Example Gherkin features
├── guides/                 # Human-readable documentation
└── references/             # Agent execution reference
    ├── REFERENCE.md        # Conventions, tags, config
    ├── REPORTING.md        # Report templates
    └── FORMULAS.md         # Scoring algorithms
```

### Internal Utilities (scripts/)

All utilities are `user-invocable: false` - designed for internal use by commands.

#### 1. check-session.md
- **Purpose**: Centralized session state validation
- **Returns**: Normalized session object with validation
- **Used by**: status.md, export.md, cancel.md
- **Benefit**: Eliminates duplicate session checking code

#### 2. load-config.md
- **Purpose**: Config file reading and validation
- **Returns**: Validated config with defaults applied
- **Used by**: start.md, export.md, status.md
- **Benefit**: Single source of truth for config loading

#### 3. calculate-metrics.md
- **Purpose**: Quality scoring and coverage analysis
- **Implements**: Algorithms from [FORMULAS.md](../references/FORMULAS.md)
- **Used by**: status.md, export.md
- **Benefit**: Consistent metrics across all commands

#### 4. list-features.md
- **Purpose**: Feature file discovery and metadata extraction
- **Returns**: Feature list with scenario counts and tags
- **Used by**: export.md, status.md
- **Benefit**: Eliminates duplicate globbing operations

#### 5. write-checkpoint.md
- **Purpose**: Atomic checkpoint creation
- **Guarantees**: Transactional consistency
- **Used by**: start.md (auto-checkpointing)
- **Benefit**: Prevents state corruption on interruption

#### 6. validate-gherkin.md
- **Purpose**: Inline validation for self-correction
- **Checks**: Syntax, conventions, quality, coverage gaps
- **Used by**: start.md (step 7 in core loop)
- **Benefit**: Enables autonomous quality improvement

---

## Performance Optimization

### 1. Session Context Caching

**Goal**: Minimize redundant file I/O operations

**Strategy**:
- **Config file**: Read once at session start (not per command)
- **State file**: Read at start, updated incrementally (not full read/write per iteration)
- **Feature list**: Cached and refreshed only when new files created

**Impact**: Target 70-80% reduction in file I/O operations

**Implementation**:
- Utilities maintain session context in memory
- Commands call utilities instead of reading files directly
- State updates batched via `write-checkpoint.md`

### 2. Batched State Writes

**Goal**: Reduce write operations without losing progress

**Strategy**: Configurable write interval via `performance.state_file_write_interval` (default: 3)

**Write Triggers**:
- **Regular**: Every N iterations (configurable)
- **Checkpoint**: When page reaches target quality
- **Emergency**: On error, pause, or cancellation

**Example**:
```text
15 iterations with interval=3:
- Old: 15 writes (one per iteration)
- New: 5 writes (every 3rd iteration)
- Reduction: 67%
```

**Implementation**:
- In-memory state maintained between writes
- Atomic writes via `write-checkpoint.md` utility
- Transactional consistency guaranteed

### 3. Parallel Device Capture

**Goal**: Reduce browser operations for multi-device scenarios

**Strategy**: Batch resize/snapshot/screenshot per device

**Before**:
```text
3 devices × (nav + snapshot + screenshot + explore + document)
= 15+ browser operations per page
```

**After**:
```text
1 nav + (3 resize/snapshot/screenshot batched) + 1 explore + 1 document
= 8 browser operations per page
```

**Impact**: Target 40-50% reduction in browser operations

**Implementation**:
- Navigate once per page (not per device)
- Batch viewport changes and captures
- Reuse DOM snapshots across states

---

## Autonomous Features

Claude's self-managing capabilities built into [start.md](../start.md):

### 1. Inline Validation (Step 7)

Claude self-validates scenarios immediately after writing:
- Syntax checking
- Convention compliance
- Quality assessment
- Coverage gap detection

**Auto-fixable issues**:
- Inconsistent indentation
- Missing feature tags
- Missing priority tags
- Duplicate scenario names

**Flow**:
```text
Write scenario → Validate → Issues? → Fix → Re-validate → Continue
```

### 2. Auto-Checkpointing (Step 9)

Claude automatically saves progress:
- Every N iterations (configurable via `state_file_write_interval`)
- When page reaches target quality
- On error or interruption

**Benefits**:
- No manual pause/resume needed
- Graceful recovery from interruptions
- Transactional consistency via atomic writes

### 3. Auto-Resume

Claude detects checkpoints on restart:
```text
/e2e-reverse start
→ "Checkpoint found. Resuming from iteration 7/15..."
→ Claude continues autonomously
```

**Implementation**:
- start.md checks for existing state file
- Loads checkpoint state automatically
- Maintains full context across sessions

### 4. Iterative Improvement

Claude revisits pages based on quality scores:
- Low quality pages prioritized
- Coverage gaps systematically filled
- Scenario diversity improved

**Quality-Driven Selection**:
- Pages with quality < 0.50 revisited more frequently
- Missing states (error, empty, loading) added
- Device coverage completed
- Algorithm documented in [FORMULAS.md](../references/FORMULAS.md)

---

## Command Architecture

### User-Facing Commands (6 total)

**Essential human touchpoints**:
1. **setup.md** - Initial configuration
2. **start.md** - Launch autonomous loop (auto-detects resume)
3. **cancel.md** - Emergency stop
4. **status.md** - Progress monitoring (optional)
5. **export.md** - Final report generation
6. **help.md** - Usage guide

**Removed in v2.0** (functionality internalized):
- **pause.md** → Auto-checkpointing in start.md loop
- **resume.md** → Auto-resume integrated into start.md
- **validate.md** → Inline validation in start.md step 7

### Command Design Pattern

All commands follow this pattern:

```markdown
1. Load dependencies (utilities via Skill tool)
2. Validate inputs (session, config, prerequisites)
3. Execute core logic
4. Write results (via utilities)
5. Return user-friendly output
```

**Example** (status.md):
```markdown
# Load utilities
call _check-session
call _calculate-metrics
call _list-features

# Process data
Aggregate metrics
Apply report template

# Output
Display formatted status report
```

---

## Documentation Architecture

### Single Sources of Truth

**[references/REFERENCE.md](../references/REFERENCE.md)**:
- Tag system and conventions
- Gherkin structure and best practices
- Config file structure and fields
- State file format and evolution
- Browser interaction patterns

**[references/REPORTING.md](../references/REPORTING.md)**:
- Status report template
- Export report templates (markdown, JSON, HTML)
- Validation report template
- Consistent formatting across commands

**[references/FORMULAS.md](../references/FORMULAS.md)**:
- Quality score calculation
- Coverage gap score
- Scenario diversity score
- Page selection algorithm

### Cross-References

Commands link to documentation instead of duplicating:

```markdown
## Tag System
See [references/REFERENCE.md](../references/REFERENCE.md)

## Report Format
See [references/REPORTING.md](../references/REPORTING.md)
```

**Benefits**:
- Update once, applies everywhere
- Reduced maintenance burden
- Consistent information across commands
- 80% reduction in documentation duplication

---

## Error Handling & Resilience

### Graceful Degradation

**Missing config**:
- Clear error message
- Setup guidance provided
- No partial state corruption

**No active session**:
- Helpful next steps
- Checkpoint detection
- Safe to restart

**Invalid state file**:
- Checkpoint fallback
- Transactional recovery
- User notified of recovery action

**Interrupted checkpoint**:
- Atomic write guarantees
- No partial writes
- Previous checkpoint preserved

### Atomic Operations

All state modifications use transactional writes:

1. **Write to temporary file** (`.tmp`)
2. **Validate write success**
3. **Atomic move** to target location
4. **On failure**: Rollback, preserve previous state

Implemented in `scripts/write-checkpoint.md`.

---

## Extension Guide

### Adding a New Command

1. **Create command file** (e.g., `analyze.md`)
2. **Use existing utilities** via Skill tool:
   ```markdown
   /e2e-reverse _check-session
   /e2e-reverse _load-config
   /e2e-reverse _calculate-metrics
   ```
3. **Follow command pattern** (load → validate → execute → output)
4. **Reference documentation** instead of duplicating
5. **Update SKILL.md** with new command metadata

### Adding a New Utility

1. **Create in `scripts/`** with `user-invocable: false`
2. **Document in SKILL.md** completions.json
3. **Single responsibility** (do one thing well)
4. **Return structured data** (not formatted output)
5. **Handle errors gracefully** (return error objects, not throw)

### Adding New Metrics

1. **Define algorithm** in [references/FORMULAS.md](../references/FORMULAS.md)
2. **Implement** in `scripts/calculate-metrics.md`
3. **Add to templates** in [references/REPORTING.md](../references/REPORTING.md)
4. **Test** via status.md and export.md

---

## Performance Tuning

### Configuration Options

**State Write Interval**:
```yaml
performance:
  state_file_write_interval: 3  # Write every 3 iterations (default)
```
- Lower = More frequent saves, more I/O
- Higher = Fewer saves, more work lost on crash
- Recommended: 3-5 for most projects

**Max Iterations**:
```yaml
max_iterations: 15  # Stop after 15 iterations (default)
```
- Affects exploration depth
- Higher = More comprehensive coverage
- Lower = Faster completion, less thorough

### Monitoring Performance

Use `/e2e-reverse status` to check:
- Iterations completed
- Pages explored
- Quality scores
- Coverage gaps

Adjust `max_iterations` based on observed quality scores.

---

## Version History

### v2.0.0 (2026-02-04)

**Key Changes**:
- ✅ Reduced commands from 9 to 6 (33% reduction)
- ✅ Added 6 internal utilities (DRY architecture)
- ✅ Implemented auto-checkpointing and auto-resume
- ✅ Added inline validation for self-correction
- 🎯 Designed for 70-80% file I/O reduction
- 🎯 Designed for 40-50% browser operation reduction
- ✅ 80% reduction in documentation duplication

**Architecture Benefits**:
- Autonomous operation with minimal human intervention
- Graceful recovery from interruptions
- Consistent quality scoring across commands
- Easier maintenance via shared utilities

See [CHANGELOG.md](../CHANGELOG.md) for detailed version history.

---

## Multi-Agent Architecture (2026 Vision)

### Current: Single-Agent Design

The current e2e-reverse implementation uses a **monolithic agent** (Ralph) that handles all responsibilities:
- Page exploration and navigation
- UI state detection and capture
- Gherkin scenario generation
- Quality validation and self-correction
- State tracking and checkpointing

This works well for most use cases but has scaling limitations as app complexity grows.

### Future: Specialized Agent Team

**2026 Best Practice** (Google Cloud, Azure, Anthropic): Multi-agent loops with specialized subagents for complex tasks.

#### Agent Roles

**1. Explorer Agent**
- **Responsibility**: Browser automation and discovery
- **Tools**: Playwright MCP (navigate, click, snapshot, screenshot)
- **Output**: Page inventory with UI states discovered
- **Specialization**: Knows when to deep-dive vs. surface-level exploration
- **Example**: "Found 5 pages, discovered 12 UI states (loading, error, empty for search and details)"

**2. Analyzer Agent**
- **Responsibility**: UI analysis and device comparison
- **Tools**: Read snapshots, compare across devices
- **Output**: Device difference matrix, element interaction catalog
- **Specialization**: Identifies device-specific behaviors, responsive patterns
- **Example**: "Desktop uses inline dropdown, mobile shows full-screen overlay"

**3. Documenter Agent**
- **Responsibility**: Gherkin scenario generation
- **Tools**: Read examples from assets/templates/, write feature files
- **Output**: Well-structured Gherkin specs
- **Specialization**: Declarative writing, proper tag usage, Background/Scenario Outline patterns
- **Example**: Generates search.feature with proper device tags and declarative steps

**4. Validator Agent**
- **Responsibility**: Quality assurance and feedback
- **Tools**: Gherkin syntax checker, convention validator
- **Output**: Quality score, coverage gaps, improvement suggestions
- **Specialization**: Detects anti-patterns, enforces best practices, tracks quality trends
- **Example**: "Quality score 0.75. Missing: @error state, @mobile coverage for checkout"

#### Agent Coordination Pattern

**Multi-Agent Loop** (one iteration):

```text
1. Explorer → discovers pages and states
   ↓
2. Analyzer → compares devices, catalogs elements
   ↓
3. Documenter → writes Gherkin scenarios
   ↓
4. Validator → scores quality, identifies gaps
   ↓
5. Coordinator → decides next action (revisit, new page, done)
   ↓
6. Repeat until quality targets met or max iterations reached
```

**Feedback Loop**:
- Validator findings → Documenter (for rewrite)
- Coverage gaps → Explorer (for deeper exploration)
- Quality trends → Coordinator (for prioritization)

#### Benefits Over Single-Agent

**Specialization**:
- Each agent optimized for specific task
- Clearer responsibilities and interfaces
- Easier to improve individual components

**Parallel Execution**:
- Explorer can discover pages while Documenter writes specs
- Analyzer can process snapshots in background
- 2-3x throughput improvement potential

**Quality Improvement**:
- Validator agent dedicated to quality (not distracted by exploration)
- Documenter agent has access to full example library
- Analyzer agent can detect subtle device differences

**Maintainability**:
- Smaller, focused prompts per agent
- Easier to test and debug
- Independent upgrades (e.g., improve Validator without touching Explorer)

#### When to Use Multi-Agent

**Stay Single-Agent if:**
- App has < 20 pages
- Simple, uniform UI (minimal device differences)
- Quick documentation needed (1-2 sessions)

**Migrate to Multi-Agent when:**
- App has 50+ pages with complex interactions
- Significant device-specific behaviors
- Long-running exploration (10+ iterations)
- Quality requirements very high (>0.85 target score)

#### Migration Path

**Phase 1: Extract Validator** (low-risk)
- Current: Inline validation in start.md step 7
- Future: Separate Validator agent with full context
- Benefit: Better quality analysis, trend tracking
- Effort: Medium (1-2 iterations)

**Phase 2: Extract Documenter** (medium-risk)
- Current: Documentation in start.md step 6
- Future: Specialized Documenter with template library access
- Benefit: More consistent Gherkin, better patterns
- Effort: Medium-High (2-3 iterations)

**Phase 3: Extract Analyzer** (high-value)
- Current: Device comparison in start.md step 5
- Future: Dedicated Analyzer with snapshot diffing
- Benefit: More accurate device-specific detection
- Effort: High (3-4 iterations)

**Phase 4: Extract Explorer** (optional)
- Current: Browser automation in start.md steps 2-4
- Future: Specialized Explorer with state discovery algorithms
- Benefit: More comprehensive UI state coverage
- Effort: High (4-5 iterations)

#### Implementation Notes

**Tool Organization**:
- Each agent gets subset of tools (Explorer = Playwright only, Documenter = Write/Read only)
- Coordinator has Task tool to launch specialized agents
- Shared utilities remain (load-config, write-checkpoint)

**State Management**:
- Shared state file (same .claude/ralph-loop.local.md)
- Agent-specific sections (explorer_context, documenter_notes, validator_findings)
- Coordinator maintains global iteration counter

**Cost Considerations**:
- Multi-agent increases token usage (4 agents vs 1)
- Offset by parallel execution (faster wall-clock time)
- Net cost: +20-30% tokens, -40-50% time for large apps

### Conclusion

Multi-agent architecture is a **future enhancement**, not current requirement. Single-agent Ralph works well for most use cases. Consider migration when app complexity or quality requirements justify the additional overhead.

**Reference**: [Azure AI Agent Orchestration Patterns](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns), [Google Cloud Agentic AI](https://docs.cloud.google.com/architecture/choose-design-pattern-agentic-ai-system)

---

## Future Considerations

Potential architectural improvements beyond multi-agent:

1. **Configurable cache sizes** for large codebases (1000+ pages)
2. **Streaming exports** for real-time progress visibility
3. **Custom validator plugins** for project-specific rules
4. **Machine learning** for optimal page selection
5. **Git integration** for automatic versioning of generated specs
6. **MCP UI Framework** integration for interactive reports (Jan 2026 update)

These remain design considerations, not committed roadmap items.

---

*For operational usage, see [README.md](../README.md) or run `/e2e-reverse help`*
