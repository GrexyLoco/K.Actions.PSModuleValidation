<#
.SYNOPSIS
    Runs PSScriptAnalyzer on action PowerShell scripts

.DESCRIPTION
    Performs static code analysis on all PowerShell scripts in the action
    Excludes external dependencies and focuses only on action-specific code

.PARAMETER Path
    Root path to scan for PowerShell scripts (defaults to current directory)

.PARAMETER ExcludePath
    Paths to exclude from analysis (e.g., external modules)

.NOTES
    Platform-agnostic PowerShell script for CI/CD pipelines
    Requires PSScriptAnalyzer module to be available
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Path = '.',
    
    [Parameter()]
    [string[]]$ExcludePath = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

function Install-PSScriptAnalyzer {
    [CmdletBinding()]
    param()
    
    Write-Information "📦 Checking PSScriptAnalyzer availability..."
    
    if (Get-Module -Name PSScriptAnalyzer -ListAvailable) {
        Write-Information "✅ PSScriptAnalyzer already installed"
        return
    }
    
    Write-Information "📥 Installing PSScriptAnalyzer..."
    
    try {
        # Try Install-PSResource first (modern)
        if (Get-Command Install-PSResource -ErrorAction SilentlyContinue) {
            Install-PSResource -Name PSScriptAnalyzer -Scope CurrentUser -TrustRepository -Quiet
        }
        # Fallback to Install-Module
        elseif (Get-Command Install-Module -ErrorAction SilentlyContinue) {
            Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -SkipPublisherCheck
        }
        else {
            throw "No package installation method available"
        }
        
        Write-Information "✅ PSScriptAnalyzer installed successfully"
    }
    catch {
        Write-Error "Failed to install PSScriptAnalyzer: $_"
        throw
    }
}

function Get-PowerShellScripts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RootPath,
        
        [Parameter()]
        [string[]]$ExcludePath = @()
    )
    
    Write-Information "📂 Scanning for PowerShell scripts..."
    Write-Information "   Root path: $RootPath"
    
    # Convention-based paths to check (in order of priority)
    $conventionPaths = @(
        '.github/scripts',  # GitHub Actions convention
        'scripts',          # Generic scripts folder
        'src',              # Source folder
        '.'                 # Current directory (fallback)
    )
    
    $scripts = @()
    
    # Try convention paths first
    foreach ($conventionPath in $conventionPaths) {
        $fullPath = Join-Path $RootPath $conventionPath
        
        if (Test-Path $fullPath) {
            $foundScripts = @(Get-ChildItem -Path $fullPath -Filter '*.ps1' -Recurse -File -ErrorAction SilentlyContinue)
            
            if ($foundScripts.Count -gt 0) {
                Write-Information "   ✅ Found $($foundScripts.Count) script(s) in: $conventionPath"
                $scripts += $foundScripts
                break  # Use first convention path that has scripts
            }
        }
    }
    
    # If no scripts found in convention paths, try recursive from root
    if ($scripts.Count -eq 0) {
        Write-Information "   🔍 No scripts in convention paths, searching recursively..."
        $scripts = @(Get-ChildItem -Path $RootPath -Filter '*.ps1' -Recurse -File -ErrorAction SilentlyContinue)
    }
    
    Write-Information "   📊 Total scripts found: $($scripts.Count)"
    
    if ($ExcludePath.Count -gt 0) {
        Write-Information "   🚫 Applying $($ExcludePath.Count) exclusion pattern(s)..."
    }

    # Filter out excluded paths
    if ($ExcludePath.Count -gt 0 -and $scripts.Count -gt 0) {
        $scripts = @($scripts | Where-Object {
            $scriptPath = $_.FullName
            $shouldInclude = $true
            
            foreach ($excludePattern in $ExcludePath) {
                if ($scriptPath -like "*$excludePattern*") {
                    $shouldInclude = $false
                    Write-Information "   🚫 Excluded: $($_.Name) (matches: $excludePattern)"
                    break
                }
            }
            
            $shouldInclude
        })
        
        Write-Information "   ✅ Scripts after exclusion: $($scripts.Count)"
    }
    
    return $scripts
}

try {
    Write-Information "🎨 PowerShell Script Analysis - Action Scripts Only"
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Ensure PSScriptAnalyzer is available
    Install-PSScriptAnalyzer
    Import-Module PSScriptAnalyzer -Force
    
    # Get scripts to analyze
    $scripts = Get-PowerShellScripts -RootPath $Path -Exclude $ExcludePath
    
    # Ensure we have an array (even if empty)
    if ($null -eq $scripts) {
        $scripts = @()
    }
    
    if ($scripts.Count -eq 0) {
        Write-Information "⚠️ No PowerShell scripts found to analyze"
        
        # Write outputs even when no scripts found
        if ($env:GITHUB_OUTPUT) {
            "scripts-analyzed=0" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
            "total-errors=0" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
            "total-warnings=0" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
            "total-info=0" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
            "analysis-success=True" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        }
        
        exit 0
    }
    
    Write-Information "📂 Found $($scripts.Count) PowerShell script(s) to analyze"
    $scripts | ForEach-Object { Write-Information "   - $($_.Name)" }
    Write-Information ""
    
    # Run analysis
    $allResults = @()
    $totalErrors = 0
    $totalWarnings = 0
    $totalInfo = 0
    
    foreach ($script in $scripts) {
        Write-Information "🔍 Analyzing: $($script.Name)"
        
        $results = @(Invoke-ScriptAnalyzer -Path $script.FullName -Recurse)
        
        if ($results.Count -gt 0) {
            $allResults += $results
            
            $errors = @($results | Where-Object { $_.Severity -eq 'Error' }).Count
            $warnings = @($results | Where-Object { $_.Severity -eq 'Warning' }).Count
            $info = @($results | Where-Object { $_.Severity -eq 'Information' }).Count
            
            $totalErrors += $errors
            $totalWarnings += $warnings
            $totalInfo += $info
            
            Write-Information "   ❌ Errors: $errors"
            Write-Information "   ⚠️ Warnings: $warnings"
            Write-Information "   ℹ️ Info: $info"
            
            # Display errors and warnings
            @($results | Where-Object { $_.Severity -in @('Error', 'Warning') }) | ForEach-Object {
                $icon = if ($_.Severity -eq 'Error') { '❌' } else { '⚠️' }
                Write-Information "   $icon Line $($_.Line): $($_.RuleName) - $($_.Message)"
            }
        } else {
            Write-Information "   ✅ No issues found"
        }
        
        Write-Information ""
    }
    
    # Summary
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Information "📊 Analysis Summary:"
    Write-Information "   📂 Scripts analyzed: $($scripts.Count)"
    Write-Information "   ❌ Total Errors: $totalErrors"
    Write-Information "   ⚠️ Total Warnings: $totalWarnings"
    Write-Information "   ℹ️ Total Info: $totalInfo"
    
    # Write outputs for GitHub Actions
    if ($env:GITHUB_OUTPUT) {
        "scripts-analyzed=$($scripts.Count)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "total-errors=$totalErrors" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "total-warnings=$totalWarnings" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "total-info=$totalInfo" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "analysis-success=$($totalErrors -eq 0)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    }
    
    # Exit with error if critical issues found
    if ($totalErrors -gt 0) {
        Write-Information ""
        Write-Information "❌ PSScriptAnalyzer found $totalErrors error(s)"
        exit 1
    }
    
    Write-Information ""
    Write-Information "✅ PSScriptAnalyzer passed - no critical issues found"
    
    if ($totalWarnings -gt 0) {
        Write-Information "⚠️ Note: $totalWarnings warning(s) detected (non-blocking)"
    }
    
    exit 0
    
} catch {
    # Log detailed error information first (before Write-Error stops execution)
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Information "❌ ERROR DETAILS:"
    Write-Information "Message: $_"
    Write-Information "Exception: $($_.Exception.Message)"
    Write-Information "Type: $($_.Exception.GetType().FullName)"
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Information "📍 STACK TRACE:"
    Write-Information $_.ScriptStackTrace
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Now throw the error
    Write-Error "Script analysis failed: $_"
    exit 1
}
