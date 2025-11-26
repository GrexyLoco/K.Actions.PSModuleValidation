<#
.SYNOPSIS
    Runs PSScriptAnalyzer on PowerShell scripts in the repository.

.DESCRIPTION
    Scans all .ps1 files in the repository using PSScriptAnalyzer.
    Reports errors and warnings, sets GitHub Action outputs.

.OUTPUTS
    Sets GITHUB_OUTPUT variables: analysis-success, scripts-analyzed, total-errors, total-warnings

.EXAMPLE
    ./Invoke-ScriptAnalyzer.ps1

.NOTES
    Platform-independent PowerShell script for GitHub Actions workflows.
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Information "Running PSScriptAnalyzer on repository"

# Find all PowerShell scripts
$scripts = Get-ChildItem -Path . -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }

$scriptsAnalyzed = $scripts.Count
$totalErrors = 0
$totalWarnings = 0
$analysisSuccess = $true

if ($scriptsAnalyzed -eq 0) {
    Write-Information "No PowerShell scripts found to analyze"
} else {
    Write-Information "Found $scriptsAnalyzed scripts to analyze"
    
    # Check if PSScriptAnalyzer is available
    $psaAvailable = $null -ne (Get-Module -ListAvailable -Name PSScriptAnalyzer)
    
    if (-not $psaAvailable) {
        Write-Information "Installing PSScriptAnalyzer..."
        Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser -SkipPublisherCheck
    }
    
    Import-Module PSScriptAnalyzer -Force
    
    foreach ($script in $scripts) {
        Write-Information "Analyzing: $($script.Name)"
        
        $results = Invoke-ScriptAnalyzer -Path $script.FullName -Severity Error, Warning
        
        $errors = @($results | Where-Object { $_.Severity -eq 'Error' })
        $warnings = @($results | Where-Object { $_.Severity -eq 'Warning' })
        
        $totalErrors += $errors.Count
        $totalWarnings += $warnings.Count
        
        if ($errors.Count -gt 0) {
            $analysisSuccess = $false
            foreach ($err in $errors) {
                Write-Warning "ERROR [$($script.Name):$($err.Line)]: $($err.Message)"
            }
        }
        
        foreach ($warn in $warnings) {
            Write-Warning "WARNING [$($script.Name):$($warn.Line)]: $($warn.Message)"
        }
    }
}

Write-Information "Analysis complete: $totalErrors errors, $totalWarnings warnings"

# Set outputs
"analysis-success=$($analysisSuccess.ToString().ToLower())" >> $env:GITHUB_OUTPUT
"scripts-analyzed=$scriptsAnalyzed" >> $env:GITHUB_OUTPUT
"total-errors=$totalErrors" >> $env:GITHUB_OUTPUT
"total-warnings=$totalWarnings" >> $env:GITHUB_OUTPUT

if ($analysisSuccess) {
    Write-Information "✅ Script analysis passed"
} else {
    Write-Warning "❌ Script analysis found errors"
}
