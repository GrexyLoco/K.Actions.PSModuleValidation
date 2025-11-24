<#
.SYNOPSIS
    Determines final release version from manual override or auto-detection

.DESCRIPTION
    Processes version information and determines if a release should be created
    Handles manual version overrides and auto-detection results

.PARAMETER ManualVersion
    Manual version override from workflow input

.PARAMETER AutoBumpType
    Auto-detected bump type from K.Actions.NextActionVersion

.PARAMETER AutoNewVersion
    Auto-detected new version from K.Actions.NextActionVersion

.PARAMETER ForceRelease
    Force release even if no changes detected

.NOTES
    Platform-agnostic PowerShell script for CI/CD pipelines
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$ManualVersion = '',
    
    [Parameter()]
    [string]$AutoBumpType = '',
    
    [Parameter()]
    [string]$AutoNewVersion = '',
    
    [Parameter()]
    [string]$ForceRelease = 'false'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

try {
    Write-Information "🔍 Release Analysis:"
    
    # Determine final version
    if ($ManualVersion) {
        $finalVersion = $ManualVersion
        $bumpType = 'manual'
        Write-Information "  Version Source: Manual Override"
        Write-Information "  Version: $finalVersion"
    } else {
        $finalVersion = $AutoNewVersion
        $bumpType = $AutoBumpType
        Write-Information "  Version Source: Auto-Detection"
        Write-Information "  New Version: $finalVersion"
        Write-Information "  Bump Type: $bumpType"
    }
    
    Write-Information "  Force Release: $ForceRelease"
    
    # Determine if release should proceed
    $shouldRelease = $true
    if ($bumpType -eq 'none' -and $ForceRelease -ne 'true') {
        Write-Information "⏭️ No version changes detected - skipping release"
        $shouldRelease = $false
    } else {
        Write-Information "✅ Release will be created"
    }
    
    # Write outputs
    if ($env:GITHUB_OUTPUT) {
        "final-version=$finalVersion" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "bump-type=$bumpType" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "should-release=$shouldRelease" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    }
    
    exit 0
    
} catch {
    Write-Error "Version determination failed: $_"
    throw
}
