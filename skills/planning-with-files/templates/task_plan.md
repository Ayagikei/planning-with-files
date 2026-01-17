# Task Plan: [Brief Description]
<!-- 
  WHAT: This is your roadmap for the entire task. Think of it as your "working memory on disk."
  WHY: After 50+ tool calls, your original goals can get forgotten. This file keeps them fresh.
  WHEN: Create this FIRST, before starting any work. Update after each phase completes.
  
  PATTERN: Based on Anthropic's "Effective Harnesses for Long-Running Agents"
  - Each phase has pass/fail status tracking
  - Git commits serve as checkpoints for rollback
  - Session-start verification ensures clean state
-->

## Goal
<!-- 
  WHAT: One clear sentence describing what you're trying to achieve.
  WHY: This is your north star. Re-reading this keeps you focused on the end state.
  EXAMPLE: "Create a Python CLI todo app with add, list, and delete functionality."
-->
[One sentence describing the end state]

## Current Phase
<!-- 
  WHAT: Which phase you're currently working on (e.g., "Phase 1", "Phase 3").
  WHY: Quick reference for where you are in the task. Update this as you progress.
-->
Phase 1

## Phase Summary
<!-- 
  WHAT: Quick overview of all phases and their status.
  WHY: At-a-glance progress tracking, modeled after Anthropic's feature list pattern.
  WHEN: Update after each phase status change.
-->
| Phase | Title | Status | Tested |
|-------|-------|--------|--------|
| 1 | Requirements & Discovery | 🔄 In Progress | ⏸️ Pending |
| 2 | Planning & Structure | ⏸️ Pending | ⏸️ Pending |
| 3 | Implementation | ⏸️ Pending | ⏸️ Pending |
| 4 | Testing & Verification | ⏸️ Pending | ⏸️ Pending |
| 5 | Delivery | ⏸️ Pending | ⏸️ Pending |

## Phases
<!-- 
  WHAT: Break your task into 3-7 logical phases. Each phase should be completable.
  WHY: Breaking work into phases prevents overwhelm and makes progress visible.
  WHEN: Update status after completing each phase.
  
  STATUS VALUES (modeled after Anthropic's "passes" field):
  - ⏸️ Pending: Not started yet
  - 🔄 In Progress: Currently working on this  
  - ✅ Pass: Finished and verified working
  - ❌ Fail: Attempted but failed (document why in Test Results)
  - ⏭️ Skipped: Intentionally skipped (document why)
  
  IMPORTANT: Only mark as ✅ Pass after proper testing!
  "It is unacceptable to mark features as done without verification."
  - Anthropic Engineering
-->

### Phase 1: Requirements & Discovery
<!-- 
  WHAT: Understand what needs to be done and gather initial information.
  WHY: Starting without understanding leads to wasted effort. This phase prevents that.
-->
- [ ] Understand user intent
- [ ] Identify constraints and requirements
- [ ] Document findings in findings.md

**Status:** 🔄 In Progress

**Test Results:**
<!-- 
  WHAT: Verification that this phase is truly complete.
  WHY: Prevents marking phases done prematurely (common agent failure mode).
  WHEN: Fill in before changing status to ✅ Pass.
-->
| Test | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| Requirements documented | findings.md has requirements section filled | | ⏸️ |
| Constraints identified | At least 1 constraint documented | | ⏸️ |
| User intent clear | Goal statement is specific and actionable | | ⏸️ |

**Git Checkpoint:** `[commit hash after completion]`

---

### Phase 2: Planning & Structure
<!-- 
  WHAT: Decide how you'll approach the problem and what structure you'll use.
  WHY: Good planning prevents rework. Document decisions so you remember why you chose them.
-->
- [ ] Define technical approach
- [ ] Create project structure if needed
- [ ] Document decisions with rationale

**Status:** ⏸️ Pending

**Test Results:**
| Test | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| Approach documented | Decisions table has entries | | ⏸️ |
| Structure created | Required files/folders exist | | ⏸️ |
| Rationale recorded | Each decision has a "why" | | ⏸️ |

**Git Checkpoint:** `[commit hash after completion]`

---

### Phase 3: Implementation
<!-- 
  WHAT: Actually build/create/write the solution.
  WHY: This is where the work happens. Break into smaller sub-tasks if needed.
-->
- [ ] Execute the plan step by step
- [ ] Write code to files before executing
- [ ] Test incrementally

**Status:** ⏸️ Pending

**Test Results:**
| Test | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| Core functionality works | [describe expected behavior] | | ⏸️ |
| No runtime errors | Code executes without exceptions | | ⏸️ |
| Incremental tests pass | Each sub-task verified before next | | ⏸️ |

**Git Checkpoint:** `[commit hash after completion]`

---

### Phase 4: Testing & Verification
<!-- 
  WHAT: Verify everything works and meets requirements.
  WHY: Catching issues early saves time. Document test results in progress.md.
-->
- [ ] Verify all requirements met
- [ ] Document test results in progress.md
- [ ] Fix any issues found

**Status:** ⏸️ Pending

**Test Results:**
| Test | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| All requirements met | Each requirement from Phase 1 verified | | ⏸️ |
| End-to-end test | Full workflow completes successfully | | ⏸️ |
| Edge cases handled | Error handling works correctly | | ⏸️ |

**Git Checkpoint:** `[commit hash after completion]`

---

### Phase 5: Delivery
<!-- 
  WHAT: Final review and handoff to user.
  WHY: Ensures nothing is forgotten and deliverables are complete.
-->
- [ ] Review all output files
- [ ] Ensure deliverables are complete
- [ ] Deliver to user

**Status:** ⏸️ Pending

**Test Results:**
| Test | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| All files present | Deliverables list complete | | ⏸️ |
| Documentation complete | README/docs updated | | ⏸️ |
| User acceptance | User confirms requirements met | | ⏸️ |

**Git Checkpoint:** `[commit hash after completion]`

---

## Key Questions
<!-- 
  WHAT: Important questions you need to answer during the task.
  WHY: These guide your research and decision-making. Answer them as you go.
  EXAMPLE: 
    1. Should tasks persist between sessions? → Yes, need file storage
    2. What format for storing tasks? → JSON file
-->
1. [Question to answer] → [Answer when found]
2. [Question to answer] → [Answer when found]

## Decisions Made
<!-- 
  WHAT: Technical and design decisions you've made, with the reasoning behind them.
  WHY: You'll forget why you made choices. This table helps you remember and justify decisions.
  WHEN: Update whenever you make a significant choice (technology, approach, structure).
  EXAMPLE:
    | Use JSON for storage | Simple, human-readable, built-in Python support |
-->
| Decision | Rationale |
|----------|-----------|
|          |           |

## Errors Encountered
<!-- 
  WHAT: Every error you encounter, what attempt number it was, and how you resolved it.
  WHY: Logging errors prevents repeating the same mistakes. This is critical for learning.
  WHEN: Add immediately when an error occurs, even if you fix it quickly.
  EXAMPLE:
    | FileNotFoundError | 1 | Check if file exists, create empty list if not |
    | JSONDecodeError | 2 | Handle empty file case explicitly |
-->
| Error | Attempt | Resolution |
|-------|---------|------------|
|       | 1       |            |

## Git Checkpoints
<!-- 
  WHAT: Record of git commits made at phase completion.
  WHY: Each commit is a rollback point. If something breaks, you can recover.
  WHEN: Update after each phase completion commit.
  
  PATTERN: From Anthropic's article:
  "We found that the best way to elicit this behavior was to ask the model 
  to commit its progress to git with descriptive commit messages."
-->
| Phase | Commit Hash | Message | Date |
|-------|-------------|---------|------|
| 1     |             |         |      |
| 2     |             |         |      |
| 3     |             |         |      |
| 4     |             |         |      |
| 5     |             |         |      |

## Session History
<!-- 
  WHAT: Log of session starts and context switches.
  WHY: Tracks when context was refreshed, helps understand project timeline.
  WHEN: Updated automatically by init-session.sh or manually at session start.
-->
| Session | Date | Starting Phase | Notes |
|---------|------|----------------|-------|
| 1       |      | Phase 1        | Initial session |

## Notes
<!-- 
  REMINDERS based on Anthropic's patterns:
  - Update phase status as you progress: Pending → In Progress → Pass/Fail
  - Re-read this plan before major decisions (attention manipulation)
  - Log ALL errors - they help avoid repetition
  - Never repeat a failed action - mutate your approach instead
  - Commit after each completed phase for easy rollback
  - Only mark ✅ Pass after proper testing - no premature completion!
-->
- Update phase status as you progress: ⏸️ → 🔄 → ✅/❌
- Re-read this plan before major decisions (attention manipulation)
- Log ALL errors - they help avoid repetition
- Commit after each completed phase for easy rollback
- **Only mark ✅ Pass after proper testing!**
