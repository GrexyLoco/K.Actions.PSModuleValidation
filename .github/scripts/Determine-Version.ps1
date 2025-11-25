<#
.SYNOPSIS
    Determines the final release version from manual input or auto-detection.

.DESCRIPTION
    Evaluates if a manual version override is provided, otherwise uses the
    auto-detected version from K.Actions.NextActionVersion. Sets appropriate outputs
    for subsequent workflow steps.

.PARAMETER ManualVersion
    Optional manual version override from workflow input.

.PARAMETER AutoBumpType
    Auto-detected bump type from K.Actions.NextActionVersion (major/minor/patch/none).

.PARAMETER AutoNewVersion
    Auto-detected new version from K.Actions.NextActionVersion.

.PARAMETER ForceRelease
    Force release even if no changes detected ('true'/'false' string).

.OUTPUTS
    Sets GITHUB_OUTPUT variables: final-version, should-release, bump-type
    Writes workflow summary to GITHUB_STEP_SUMMARY.

.EXAMPLE
    ./Determine-Version.ps1 -ManualVersion "1.2.3"
    ./Determine-Version.ps1 -AutoBumpType "patch" -AutoNewVersion "0.1.5"
    ./Determine-Version.ps1 -AutoBumpType "none" -ForceRelease "true"

.NOTES
    Platform-independent script for GitHub Actions workflows.
    Handles both manual version override and automatic version detection.
    Based on: .github/templates/scripts/Determine-Version.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ManualVersion = '',
    
    [Parameter(Mandatory = $false)]
    [string]$AutoBumpType = '',
    
    [Parameter(Mandatory = $false)]
    [string]$AutoNewVersion = '',
    
    [Parameter(Mandatory = $false)]
    [string]$ForceRelease = 'false'
)

if ($ManualVersion) {
    # Manual version override
    $version = $ManualVersion -replace '^v', ''
    Write-Output "🎯 Manual version override: $version"
    "final-version=$version" >> $env:GITHUB_OUTPUT
    "should-release=true" >> $env:GITHUB_OUTPUT
    "bump-type=manual" >> $env:GITHUB_OUTPUT
    
    "## 📌 Manual Version Override" >> $env:GITHUB_STEP_SUMMARY
    "**Override Version:** ``$version``" >> $env:GITHUB_STEP_SUMMARY
} else {
    # Auto-detected version
    $version = $AutoNewVersion -replace '^v', ''
    Write-Output "🔍 Auto-detected bump type: $AutoBumpType"
    Write-Output "🔍 Auto-detected version: $version"
    
    "final-version=$version" >> $env:GITHUB_OUTPUT
    "bump-type=$AutoBumpType" >> $env:GITHUB_OUTPUT
    
    if ($AutoBumpType -eq 'none' -and $ForceRelease -ne 'true') {
        "should-release=false" >> $env:GITHUB_OUTPUT
        
        "## 🔁 No Release Required" >> $env:GITHUB_STEP_SUMMARY
        "No version changes detected. Workflow will exit gracefully." >> $env:GITHUB_STEP_SUMMARY
    } elseif ($AutoBumpType -eq 'none' -and $ForceRelease -eq 'true') {
        "should-release=true" >> $env:GITHUB_OUTPUT
        "bump-type=patch" >> $env:GITHUB_OUTPUT
        
        "## 🔄 Forced Release" >> $env:GITHUB_STEP_SUMMARY
        "**Force Release:** enabled (defaulting to patch)" >> $env:GITHUB_STEP_SUMMARY
        "**New Version:** ``$version``" >> $env:GITHUB_STEP_SUMMARY
    } else {
        "should-release=true" >> $env:GITHUB_OUTPUT
        
        "## ⬆️ Version Bump Detected" >> $env:GITHUB_STEP_SUMMARY
        "**Bump Type:** ``$AutoBumpType``" >> $env:GITHUB_STEP_SUMMARY
        "**New Version:** ``$version``" >> $env:GITHUB_STEP_SUMMARY
    }
}
