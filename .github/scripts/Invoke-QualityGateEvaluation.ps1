<#
.SYNOPSIS
    Evaluates quality gate results and generates summary

.DESCRIPTION
    Collects results from all quality checks (GitLeaks, structure validation, linting)
    and evaluates whether the quality gate passes. Creates a detailed GitHub summary.

.PARAMETER GitLeaksOutcome
    Outcome of the GitLeaks security scan step

.PARAMETER StructureSuccess
    Whether action structure validation succeeded

.PARAMETER SchemaSuccess
    Whether action schema validation succeeded

.PARAMETER LintSuccess
    Whether PSScriptAnalyzer linting succeeded

.PARAMETER ActionName
    Name of the action being validated

.PARAMETER ActionType
    Type of the action (composite, docker, javascript)

.PARAMETER ScriptsAnalyzed
    Number of PowerShell scripts analyzed

.PARAMETER TotalErrors
    Total number of linting errors found

.PARAMETER TotalWarnings
    Total number of linting warnings found

.NOTES
    Platform-agnostic PowerShell script for CI/CD pipelines
    Exits with code 1 if quality gate fails
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$GitLeaksOutcome,
    
    [Parameter(Mandatory)]
    [string]$StructureSuccess,
    
    [Parameter(Mandatory)]
    [string]$SchemaSuccess,
    
    [Parameter(Mandatory)]
    [string]$LintSuccess,
    
    [Parameter()]
    [string]$ActionName = '',
    
    [Parameter()]
    [string]$ActionType = '',
    
    [Parameter()]
    [string]$ScriptsAnalyzed = '0',
    
    [Parameter()]
    [string]$TotalErrors = '0',
    
    [Parameter()]
    [string]$TotalWarnings = '0'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

try {
    Write-Information "🔍 Evaluating Quality Gate Results..."
    Write-Information "  🔐 GitLeaks: $GitLeaksOutcome"
    Write-Information "  📋 Structure: $StructureSuccess"
    Write-Information "  📋 Schema: $SchemaSuccess"
    Write-Information "  🎨 Linting: $LintSuccess"
    
    # Create GitHub Summary
    $summary = @"
## 🔐 Quality Gate Results

### 📊 Security & Structure
| Check | Status | Details |
|-------|--------|---------|
| 🔐 **GitLeaks** | $(if ($GitLeaksOutcome -ne 'failure') { '✅ PASSED' } else { '❌ FAILED' }) | No secrets detected |
| 📋 **Action Structure** | $(if ($StructureSuccess -eq 'True') { '✅ PASSED' } else { '❌ FAILED' }) | Valid action.yml |
| 🔗 **Schema Validation** | $(if ($SchemaSuccess -eq 'True') { '✅ PASSED' } else { '❌ FAILED' }) | Inputs/Outputs valid |

### 🎨 Code Quality (PSScriptAnalyzer)
| Metric | Value |
|--------|-------|
| **Scripts Analyzed** | $ScriptsAnalyzed |
| **Errors** | $(if ($TotalErrors -eq '0') { '✅ 0' } else { "❌ $TotalErrors" }) |
| **Warnings** | $(if ($TotalWarnings -eq '0') { '✅ 0' } else { "⚠️ $TotalWarnings" }) |
| **Overall** | $(if ($LintSuccess -eq 'True') { '✅ PASSED' } else { '❌ FAILED' }) |

### 📦 Action Details
$(if ($ActionName) { "**Name:** ``$ActionName``" } else { '' })
$(if ($ActionType) { "**Type:** ``$ActionType``" } else { '' })

---

"@
    
    # Evaluate overall success
    $success = ($GitLeaksOutcome -ne 'failure') -and 
               ($StructureSuccess -eq 'True') -and 
               ($SchemaSuccess -eq 'True') -and 
               ($LintSuccess -eq 'True')
    
    if ($success) {
        $summary += @"
### ✅ Quality Gate: **PASSED**

All quality checks passed successfully! Ready for release.
"@
        Write-Information ""
        Write-Information "✅ Quality Gate PASSED - All checks successful!"
    } else {
        $summary += @"
### ❌ Quality Gate: **FAILED**

One or more quality checks failed. Please review and fix the issues above.
"@
        Write-Information ""
        Write-Information "❌ Quality Gate FAILED - Review issues above"
    }
    
    # Write to GitHub Step Summary
    if ($env:GITHUB_STEP_SUMMARY) {
        Write-Output $summary >> $env:GITHUB_STEP_SUMMARY
    }
    
    # Write output for GitHub Actions
    if ($env:GITHUB_OUTPUT) {
        "quality-success=$success" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    }
    
    # Exit with appropriate code
    if ($success) {
        exit 0
    } else {
        exit 1
    }
    
} catch {
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Information "❌ ERROR DETAILS:"
    Write-Information "Message: $_"
    Write-Information "Exception: $($_.Exception.Message)"
    Write-Information "Type: $($_.Exception.GetType().FullName)"
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Information "📍 STACK TRACE:"
    Write-Information $_.ScriptStackTrace
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    Write-Error "Quality gate evaluation failed: $_"
    exit 1
}
