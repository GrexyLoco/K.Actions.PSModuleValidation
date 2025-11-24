<#
.SYNOPSIS
    Creates GitHub release using GitHub CLI

.DESCRIPTION
    Creates a GitHub release with generated changelog and metadata

.PARAMETER Version
    Version number for the release

.PARAMETER Changelog
    Changelog content for the release

.NOTES
    Platform-agnostic PowerShell script for CI/CD pipelines
    Requires GITHUB_TOKEN environment variable
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Version,
    
    [Parameter(Mandatory)]
    [string]$Changelog
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

try {
    Write-Information "📦 Creating GitHub release: $Version"
    
    if (-not $env:GITHUB_TOKEN) {
        throw "GITHUB_TOKEN environment variable not set"
    }
    
    # Create release using GitHub CLI
    gh release create $Version `
        --title "🚀 K.Actions.PSModuleValidation $Version" `
        --notes $Changelog
    
    # Write outputs
    if ($env:GITHUB_OUTPUT) {
        "release-created=true" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "release-tag=$Version" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    }
    
    Write-Information "✅ Release created: $Version"
    exit 0
    
} catch {
    Write-Error "GitHub release creation failed: $_"
    throw
}
