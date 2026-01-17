# =============================================================================
# Session Initialization Script for planning-with-files (PowerShell)
# Based on Anthropic's "Effective Harnesses for Long-Running Agents"
# =============================================================================
#
# WHAT: Initializes or resumes a planning session with verification
# WHY:  Ensures consistent startup state across sessions (Anthropic pattern)
# WHEN: Run at the start of EVERY session, not just the first one
#
# USAGE:
#   .\init-session.ps1 [project-name]
#   .\init-session.ps1 my-project
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

param(
    [string]$ProjectName = "project"
)

$ErrorActionPreference = "Stop"

# Configuration
$DATE = Get-Date -Format "yyyy-MM-dd"
$TIME = Get-Date -Format "HH:mm:ss"
$PLANNING_FILES = @("task_plan.md", "findings.md", "progress.md")

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "=== $Text ===" -ForegroundColor Blue
    Write-Host ""
}

function Write-Success {
    param([string]$Text)
    Write-Host "✅ $Text" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Text)
    Write-Host "⚠️  $Text" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Text)
    Write-Host "❌ $Text" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host "ℹ️  $Text" -ForegroundColor Cyan
}

# =============================================================================
# VERIFICATION FUNCTIONS
# =============================================================================

function Test-GitStatus {
    if (Test-Path ".git") {
        $status = git status --porcelain 2>$null
        if ([string]::IsNullOrEmpty($status)) {
            Write-Success "Git repository clean"
            return $true
        } else {
            Write-Warning "Git has uncommitted changes"
            Write-Host "   Uncommitted files:"
            $lines = $status -split "`n" | Select-Object -First 5
            foreach ($line in $lines) {
                Write-Host "     $line"
            }
            $count = ($status -split "`n").Count
            if ($count -gt 5) {
                Write-Host "     ... and $($count - 5) more"
            }
            return $false
        }
    } else {
        Write-Info "Not a git repository"
        return $true
    }
}

function Get-CurrentBranch {
    if (Test-Path ".git") {
        try {
            $branch = git branch --show-current 2>$null
            if ($branch) { return $branch } else { return "unknown" }
        } catch {
            return "unknown"
        }
    } else {
        return "N/A"
    }
}

function Get-LastCommit {
    if (Test-Path ".git") {
        try {
            $commit = git log --oneline -1 2>$null
            if ($commit) { return $commit } else { return "No commits yet" }
        } catch {
            return "No commits yet"
        }
    } else {
        return "N/A"
    }
}

function Get-CurrentPhase {
    if (Test-Path "task_plan.md") {
        $content = Get-Content "task_plan.md" -Raw
        if ($content -match "## Current Phase\s*\n(.+)") {
            return $Matches[1].Trim()
        }
    }
    return "Not started"
}

function Get-PhaseStatus {
    if (Test-Path "task_plan.md") {
        $content = Get-Content "task_plan.md" -Raw
        $total = ([regex]::Matches($content, "### Phase")).Count
        $complete = ([regex]::Matches($content, "\*\*Status:\*\* complete")).Count
        $inProgress = ([regex]::Matches($content, "\*\*Status:\*\* in_progress")).Count
        $pending = ([regex]::Matches($content, "\*\*Status:\*\* pending")).Count
        
        return "Total: $total | Complete: $complete | In Progress: $inProgress | Pending: $pending"
    }
    return "No task plan found"
}

# =============================================================================
# FILE CREATION FUNCTIONS
# =============================================================================

function New-TaskPlan {
    @"
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
"@ | Out-File -FilePath "task_plan.md" -Encoding UTF8
    Write-Success "Created task_plan.md"
}

function New-Findings {
    @"
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
"@ | Out-File -FilePath "findings.md" -Encoding UTF8
    Write-Success "Created findings.md"
}

function New-Progress {
    @"
# Progress Log

## Session: $DATE $TIME

### Current Status
- **Phase:** 1 - Requirements & Discovery
- **Started:** $DATE

### Session Verification
<!-- Updated by init-session.ps1 -->
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
"@ | Out-File -FilePath "progress.md" -Encoding UTF8
    Write-Success "Created progress.md"
}

# =============================================================================
# PROGRESS LOG UPDATE
# =============================================================================

function Add-SessionLog {
    if (Test-Path "progress.md") {
        $branch = Get-CurrentBranch
        $lastCommit = Get-LastCommit
        $phase = Get-CurrentPhase
        $gitClean = "✅"
        
        if (Test-Path ".git") {
            $status = git status --porcelain 2>$null
            if (-not [string]::IsNullOrEmpty($status)) {
                $gitClean = "⚠️ Uncommitted changes"
            }
        }
        
        $lastModified = (Get-Item "progress.md").LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        
        $sessionEntry = @"

## Session: $DATE $TIME

### Session Verification
| Check | Status | Notes |
|-------|--------|-------|
| Planning files exist | ✅ | All 3 files present |
| Git status | $gitClean | |
| Current branch | $branch | |
| Last commit | $lastCommit | |

### Resuming From
- **Phase:** $phase
- **Previous session ended:** $lastModified

### Actions Taken
-

### Test Results
| Test | Expected | Actual | Status |
|------|----------|--------|--------|

### Errors
| Error | Resolution |
|-------|------------|

---
"@
        
        $content = Get-Content "progress.md" -Raw
        $header = ($content -split "`n")[0]
        $rest = ($content -split "`n" | Select-Object -Skip 1) -join "`n"
        
        "$header`n$sessionEntry`n$rest" | Out-File -FilePath "progress.md" -Encoding UTF8
        
        Write-Success "Logged session start to progress.md"
    }
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

function Main {
    Write-Header "SESSION INITIALIZATION"
    Write-Host "Project: $ProjectName"
    Write-Host "Date: $DATE"
    Write-Host "Time: $TIME"
    Write-Host "Directory: $(Get-Location)"
    
    Write-Header "VERIFICATION CHECKLIST"
    
    # Check planning files
    $filesExist = $true
    foreach ($file in $PLANNING_FILES) {
        if (-not (Test-Path $file)) {
            $filesExist = $false
            break
        }
    }
    
    # Verify or create planning files
    if ($filesExist) {
        foreach ($file in $PLANNING_FILES) {
            Write-Success "$file exists"
        }
    } else {
        Write-Info "Creating missing planning files..."
        if (-not (Test-Path "task_plan.md")) { New-TaskPlan }
        if (-not (Test-Path "findings.md")) { New-Findings }
        if (-not (Test-Path "progress.md")) { New-Progress }
    }
    
    # Verify git status
    Test-GitStatus | Out-Null
    
    Write-Header "CURRENT STATUS"
    
    Write-Host "Current Phase: $(Get-CurrentPhase)"
    Write-Host "Phase Summary: $(Get-PhaseStatus)"
    Write-Host "Branch: $(Get-CurrentBranch)"
    Write-Host "Last Commit: $(Get-LastCommit)"
    
    # Log session start if files already existed
    if ($filesExist) {
        Write-Header "LOGGING SESSION"
        Add-SessionLog
    }
    
    Write-Header "RECOMMENDED NEXT STEPS"
    
    if (-not $filesExist) {
        Write-Host "1. Edit task_plan.md to define your goal and phases"
        Write-Host "2. Run: git add task_plan.md findings.md progress.md"
        Write-Host "3. Run: git commit -m 'chore: Initialize planning files'"
    } else {
        Write-Host "1. Read task_plan.md to understand current state"
        Write-Host "2. Check git log for recent changes: git log --oneline -5"
        Write-Host "3. Continue from current phase"
        Write-Host ""
        Write-Host "Quick commands:"
        Write-Host "  Get-Content task_plan.md | Select-Object -First 50   # View plan summary"
        Write-Host "  git diff --stat                                       # See uncommitted changes"
        Write-Host "  git log --oneline -10                                 # Recent commits"
    }
    
    Write-Host ""
    Write-Success "Session initialization complete!"
}

# Run main function
Main
