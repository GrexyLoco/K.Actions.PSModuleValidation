<#
.SYNOPSIS
    Creates and pushes Git release tag

.DESCRIPTION
    Creates annotated Git tag with release information and pushes to origin

.PARAMETER Version
    Version number for the tag

.PARAMETER ReleaseAuthor
    Git author name for the tag

.PARAMETER ReleaseEmail
    Git author email for the tag

.NOTES
    Platform-agnostic PowerShell script for CI/CD pipelines
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Version,
    
    [Parameter(Mandatory)]
    [string]$ReleaseAuthor,
    
    [Parameter(Mandatory)]
    [string]$ReleaseEmail
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

try {
    Write-Information "🏷️ Creating release tag: $Version"
    
    # Configure Git
    git config user.name $ReleaseAuthor
    git config user.email $ReleaseEmail
    
    # Create annotated tag
    $tagMessage = @"
🚀 Release $Version

Automated release of K.Actions.PSModuleValidation

Features:
- Comprehensive PowerShell module validation
- Security scanning with GitLeaks
- PSScriptAnalyzer linting
- Action structure validation
- Enterprise-ready parametrization
"@
    
    git tag -a $Version -m $tagMessage
    
    # Push tag
    git push origin $Version
    
    Write-Information "✅ Tag created and pushed: $Version"
    exit 0
    
} catch {
    Write-Error "Tag creation failed: $_"
    throw
}
