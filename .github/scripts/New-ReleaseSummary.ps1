<#
.SYNOPSIS
    Generates GitHub release summary

.DESCRIPTION
    Creates a formatted summary of the release with version details,
    features, usage instructions, and relevant links

.PARAMETER Version
    The version number of the release

.NOTES
    Platform-agnostic PowerShell script for CI/CD pipelines
    Outputs summary to GITHUB_STEP_SUMMARY
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

try {
    Write-Information "📋 Generating release summary for version: $Version"
    
    $summary = @"
## 🚀 Release Complete

### 📊 Release Details
| Detail | Value |
|--------|-------|
| **Version** | ``$Version`` |
| **Quality Gate** | ✅ PASSED |
| **Status** | ✅ RELEASED |

### 🎯 Action Features
* 🔐 Security Scanning (GitLeaks)
* 🎨 Code Quality (PSScriptAnalyzer)  
* 📋 Structure Validation (action.yml)
* ⚙️ Enterprise-ready parameters

### 📋 Usage
\`\`\`yaml
uses: GrexyLoco/K.Actions.PSModuleValidation@$Version
\`\`\`

### 🔗 Links
* [Repository](https://github.com/GrexyLoco/K.Actions.PSModuleValidation)
* [Release](https://github.com/GrexyLoco/K.Actions.PSModuleValidation/releases/tag/$Version)
* [Documentation](https://github.com/GrexyLoco/K.Actions.PSModuleValidation#readme)

---
**Action is ready for production use! 🎉**
"@
    
    # Write to GitHub Step Summary
    if ($env:GITHUB_STEP_SUMMARY) {
        Write-Output $summary >> $env:GITHUB_STEP_SUMMARY
        Write-Information "✅ Summary written to GitHub Step Summary"
    } else {
        Write-Information "⚠️ GITHUB_STEP_SUMMARY not set, outputting to console:"
        Write-Information $summary
    }
    
    Write-Information "✅ Release summary generated successfully"
    exit 0
    
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
    
    Write-Error "Failed to generate release summary: $_"
    exit 1
}
