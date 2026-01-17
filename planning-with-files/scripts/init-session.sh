#!/bin/bash
# =============================================================================
# Session Initialization Script for planning-with-files
# Based on Anthropic's "Effective Harnesses for Long-Running Agents"
# =============================================================================
#
# WHAT: Initializes or resumes a planning session with verification
# WHY:  Ensures consistent startup state across sessions (Anthropic pattern)
# WHEN: Run at the start of EVERY session, not just the first one
#
# USAGE:
#   ./init-session.sh [project-name]
#   ./init-session.sh my-project
#
# EXAMPLE OUTPUT:
#   === SESSION INITIALIZATION ===
#   Project: my-project
#   Date: 2026-01-17
#   
#   === VERIFICATION CHECKLIST ===
#   ✅ task_plan.md exists
#   ✅ findings.md exists
#   ✅ progress.md exists
#   ✅ Git repository clean
#   
#   === CURRENT STATUS ===
#   Phase: 3 - Implementation
#   Status: in_progress
#   Last commit: abc1234 - feat: Add user authentication
# =============================================================================

set -e

# Configuration
PROJECT_NAME="${1:-project}"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M:%S)
PLANNING_FILES=("task_plan.md" "findings.md" "progress.md")

# Colors for output (if terminal supports it)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if colors are supported
if [ ! -t 1 ]; then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# =============================================================================
# VERIFICATION FUNCTIONS
# =============================================================================

verify_planning_files() {
    local all_exist=true
    local missing_files=()
    
    for file in "${PLANNING_FILES[@]}"; do
        if [ -f "$file" ]; then
            print_success "$file exists"
        else
            print_warning "$file missing (will be created)"
            missing_files+=("$file")
            all_exist=false
        fi
    done
    
    echo "$all_exist"
}

verify_git_status() {
    if [ -d ".git" ]; then
        local status=$(git status --porcelain 2>/dev/null)
        if [ -z "$status" ]; then
            print_success "Git repository clean"
            return 0
        else
            print_warning "Git has uncommitted changes"
            echo "   Uncommitted files:"
            git status --porcelain | head -5 | while read line; do
                echo "     $line"
            done
            local count=$(git status --porcelain | wc -l)
            if [ "$count" -gt 5 ]; then
                echo "     ... and $((count - 5)) more"
            fi
            return 1
        fi
    else
        print_info "Not a git repository"
        return 0
    fi
}

get_current_branch() {
    if [ -d ".git" ]; then
        git branch --show-current 2>/dev/null || echo "unknown"
    else
        echo "N/A"
    fi
}

get_last_commit() {
    if [ -d ".git" ]; then
        git log --oneline -1 2>/dev/null || echo "No commits yet"
    else
        echo "N/A"
    fi
}

get_current_phase() {
    if [ -f "task_plan.md" ]; then
        # Extract current phase from task_plan.md
        local phase=$(grep -E "^## Current Phase" -A 1 task_plan.md 2>/dev/null | tail -1 | tr -d '\r')
        if [ -n "$phase" ]; then
            echo "$phase"
        else
            echo "Phase 1"
        fi
    else
        echo "Not started"
    fi
}

get_phase_status() {
    if [ -f "task_plan.md" ]; then
        # Count phases by status
        local total=$(grep -c "### Phase" task_plan.md 2>/dev/null || echo "0")
        local complete=$(grep -cF "**Status:** complete" task_plan.md 2>/dev/null || echo "0")
        local in_progress=$(grep -cF "**Status:** in_progress" task_plan.md 2>/dev/null || echo "0")
        local pending=$(grep -cF "**Status:** pending" task_plan.md 2>/dev/null || echo "0")
        
        echo "Total: $total | Complete: $complete | In Progress: $in_progress | Pending: $pending"
    else
        echo "No task plan found"
    fi
}

# =============================================================================
# FILE CREATION FUNCTIONS
# =============================================================================

create_task_plan() {
    cat > task_plan.md << 'EOF'
# Task Plan: [Brief Description]
<!-- 
  WHAT: This is your roadmap for the entire task. Think of it as your "working memory on disk."
  WHY: After 50+ tool calls, your original goals can get forgotten. This file keeps them fresh.
  WHEN: Create this FIRST, before starting any work. Update after each phase completes.
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

## Phases
<!-- 
  WHAT: Break your task into 3-7 logical phases. Each phase should be completable.
  WHY: Breaking work into phases prevents overwhelm and makes progress visible.
  WHEN: Update status after completing each phase: pending → in_progress → complete
  
  STATUS VALUES:
  - ⏸️ pending: Not started yet
  - 🔄 in_progress: Currently working on this  
  - ✅ complete: Finished and verified
  - ❌ failed: Attempted but blocked (document why)
  - ⏭️ skipped: Intentionally skipped (document why)
-->

### Phase 1: Requirements & Discovery
- [ ] Understand user intent
- [ ] Identify constraints and requirements
- [ ] Document findings in findings.md
- **Status:** in_progress
- **Test Results:** Not yet tested

### Phase 2: Planning & Structure
- [ ] Define technical approach
- [ ] Create project structure if needed
- [ ] Document decisions with rationale
- **Status:** pending
- **Test Results:** Not yet tested

### Phase 3: Implementation
- [ ] Execute the plan step by step
- [ ] Write code to files before executing
- [ ] Test incrementally
- **Status:** pending
- **Test Results:** Not yet tested

### Phase 4: Testing & Verification
- [ ] Verify all requirements met
- [ ] Document test results in progress.md
- [ ] Fix any issues found
- **Status:** pending
- **Test Results:** Not yet tested

### Phase 5: Delivery
- [ ] Review all output files
- [ ] Ensure deliverables are complete
- [ ] Deliver to user
- **Status:** pending
- **Test Results:** Not yet tested

## Key Questions
<!-- 
  WHAT: Important questions you need to answer during the task.
  WHY: These guide your research and decision-making. Answer them as you go.
-->
1. [Question to answer]
2. [Question to answer]

## Decisions Made
<!-- 
  WHAT: Technical and design decisions you've made, with the reasoning behind them.
  WHY: You'll forget why you made choices. This table helps you remember and justify decisions.
  WHEN: Update whenever you make a significant choice (technology, approach, structure).
-->
| Decision | Rationale |
|----------|-----------|
|          |           |

## Errors Encountered
<!-- 
  WHAT: Every error you encounter, what attempt number it was, and how you resolved it.
  WHY: Logging errors prevents repeating the same mistakes. This is critical for learning.
  WHEN: Add immediately when an error occurs, even if you fix it quickly.
-->
| Error | Attempt | Resolution |
|-------|---------|------------|
|       | 1       |            |

## Git Checkpoints
<!-- 
  WHAT: Record of git commits made at phase completion.
  WHY: Each commit is a rollback point. If something breaks, you can recover.
  WHEN: Update after each phase completion commit.
-->
| Phase | Commit Hash | Message | Date |
|-------|-------------|---------|------|
|       |             |         |      |

## Notes
- Update phase status as you progress: pending → in_progress → complete
- Re-read this plan before major decisions (attention manipulation)
- Log ALL errors - they help avoid repetition
- Commit after each completed phase for easy rollback
EOF
    print_success "Created task_plan.md"
}

create_findings() {
    cat > findings.md << 'EOF'
# Findings & Decisions

## Requirements
-

## Research Findings
-

## Technical Decisions
| Decision | Rationale |
|----------|-----------|

## Issues Encountered
| Issue | Resolution |
|-------|------------|

## Resources
-
EOF
    print_success "Created findings.md"
}

create_progress() {
    cat > progress.md << EOF
# Progress Log

## Session: $DATE $TIME

### Current Status
- **Phase:** 1 - Requirements & Discovery
- **Started:** $DATE

### Session Verification
<!-- Updated by init-session.sh -->
| Check | Status | Notes |
|-------|--------|-------|
| Planning files exist | ✅ | All 3 files present |
| Git status | ✅ | Clean working tree |
| Current branch | main | |
| Last commit | N/A | |

### Actions Taken
-

### Test Results
| Test | Expected | Actual | Status |
|------|----------|--------|--------|

### Errors
| Error | Resolution |
|-------|------------|

---
<!-- Add new sessions above this line -->
EOF
    print_success "Created progress.md"
}

# =============================================================================
# PROGRESS LOG UPDATE
# =============================================================================

log_session_start() {
    if [ -f "progress.md" ]; then
        local branch=$(get_current_branch)
        local last_commit=$(get_last_commit)
        local phase=$(get_current_phase)
        local git_clean="✅"
        
        if [ -d ".git" ]; then
            local status=$(git status --porcelain 2>/dev/null)
            if [ -n "$status" ]; then
                git_clean="⚠️ Uncommitted changes"
            fi
        fi
        
        # Create session entry
        local session_entry="
## Session: $DATE $TIME

### Session Verification
| Check | Status | Notes |
|-------|--------|-------|
| Planning files exist | ✅ | All 3 files present |
| Git status | $git_clean | |
| Current branch | $branch | |
| Last commit | $last_commit | |

### Resuming From
- **Phase:** $phase
- **Previous session ended:** $(stat -c %y progress.md 2>/dev/null | cut -d'.' -f1 || echo "Unknown")

### Actions Taken
-

### Test Results
| Test | Expected | Actual | Status |
|------|----------|--------|--------|

### Errors
| Error | Resolution |
|-------|------------|

---
"
        # Prepend to progress.md after the header
        local header=$(head -1 progress.md)
        local rest=$(tail -n +2 progress.md)
        echo "$header" > progress.md
        echo "$session_entry" >> progress.md
        echo "$rest" >> progress.md
        
        print_success "Logged session start to progress.md"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "SESSION INITIALIZATION"
    echo "Project: $PROJECT_NAME"
    echo "Date: $DATE"
    echo "Time: $TIME"
    echo "Directory: $(pwd)"
    
    print_header "VERIFICATION CHECKLIST"
    
    # Check planning files
    local files_exist=true
    for file in "${PLANNING_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            files_exist=false
            break
        fi
    done
    
    # Verify or create planning files
    if [ "$files_exist" = true ]; then
        for file in "${PLANNING_FILES[@]}"; do
            print_success "$file exists"
        done
    else
        print_info "Creating missing planning files..."
        [ ! -f "task_plan.md" ] && create_task_plan
        [ ! -f "findings.md" ] && create_findings
        [ ! -f "progress.md" ] && create_progress
    fi
    
    # Verify git status
    verify_git_status
    
    print_header "CURRENT STATUS"
    
    echo "Current Phase: $(get_current_phase)"
    echo "Phase Summary: $(get_phase_status)"
    echo "Branch: $(get_current_branch)"
    echo "Last Commit: $(get_last_commit)"
    
    # Log session start if files already existed
    if [ "$files_exist" = true ]; then
        print_header "LOGGING SESSION"
        log_session_start
    fi
    
    print_header "RECOMMENDED NEXT STEPS"
    
    if [ "$files_exist" = false ]; then
        echo "1. Edit task_plan.md to define your goal and phases"
        echo "2. Run: git add task_plan.md findings.md progress.md"
        echo "3. Run: git commit -m 'chore: Initialize planning files'"
    else
        echo "1. Read task_plan.md to understand current state"
        echo "2. Check git log for recent changes: git log --oneline -5"
        echo "3. Continue from current phase"
        echo ""
        echo "Quick commands:"
        echo "  cat task_plan.md | head -50   # View plan summary"
        echo "  git diff --stat               # See uncommitted changes"
        echo "  git log --oneline -10         # Recent commits"
    fi
    
    echo ""
    print_success "Session initialization complete!"
}

# Run main function
main
