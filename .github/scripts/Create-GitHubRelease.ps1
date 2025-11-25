<#
.SYNOPSIS
    Creates a GitHub release (draft) with auto-generated release notes.

.DESCRIPTION
    Creates a draft GitHub release using the gh CLI. Generates release notes with
    usage instructions and metadata. Handles existing releases by deleting
    and recreating them. Automatically detects prerelease versions.

.PARAMETER Version
    Semantic version without 'v' prefix (e.g., "1.2.3").

.PARAMETER BumpType
    Type of version bump (major/minor/patch/manual).

.PARAMETER ActionName
    Name of the GitHub Action (default: K.Actions.PSModuleValidation).

.PARAMETER Repository
    GitHub repository in format "owner/repo".

.OUTPUTS
    Sets GITHUB_OUTPUT variables: release-created, release-tag, release-url
    Writes summary to GITHUB_STEP_SUMMARY.

.EXAMPLE
    ./Create-GitHubRelease.ps1 -Version "1.2.3" -BumpType "patch" -ActionName "K.Actions.PSModuleValidation" -Repository "owner/repo"

.NOTES
    Platform-independent PowerShell script for GitHub Actions workflows.
    Requires gh CLI to be installed and authenticated.
    Based on: .github/templates/scripts/Create-GitHubRelease.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    
    [Parameter(Mandatory = $true)]
    [string]$BumpType,
    
    [Parameter(Mandatory = $false)]
    [string]$ActionName = 'K.Actions.PSModuleValidation',
    
    [Parameter(Mandatory = $false)]
    [string]$Repository = ''
)

# Auto-detect repository if not provided
if (-not $Repository -and $env:GITHUB_REPOSITORY) {
    $Repository = $env:GITHUB_REPOSITORY
}

$releaseTag = "v$Version"
$timestamp = (Get-Date).ToUniversalTime().ToString('MMMM dd, yyyy \a\t HH:mm UTC')

Write-Output "## 📦 GitHub Release Creation" >> $env:GITHUB_STEP_SUMMARY
Write-Output "**Version:** ``$releaseTag``" >> $env:GITHUB_STEP_SUMMARY
Write-Output "**Bump Type:** ``$BumpType``" >> $env:GITHUB_STEP_SUMMARY
Write-Output "" >> $env:GITHUB_STEP_SUMMARY

# Generate release notes for GitHub Action
$releaseNotes = @"
## 🎉 Release $releaseTag

> **$BumpType** release • Released on $timestamp

### 📦 Quick Access
- 📁 [Source Code](https://github.com/$Repository)
- 🏷️ [This Release](https://github.com/$Repository/releases/tag/$releaseTag)
- 📋 [All Releases](https://github.com/$Repository/releases)

### 🚀 Usage
``````yaml
- name: Validate PowerShell Module
  uses: $Repository@$releaseTag
  with:
    github-token: `${{ secrets.GITHUB_TOKEN }}
    module-name: 'YourModule'
``````

### 🎯 Features
- 🔐 Security Scanning (GitLeaks)
- 🎨 PowerShell Linting (PSScriptAnalyzer)
- 📋 Structure Validation (action.yml schema)
- ⚙️ Enterprise-ready parameters

---
*Auto-generated release*
"@

Set-Content -Path 'release_notes.md' -Value $releaseNotes -Encoding UTF8

# Delete existing release if exists
try {
    $null = gh release view $releaseTag 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Output "⚠️ Release exists - deleting and recreating"
        gh release delete $releaseTag --yes 2>$null
        git tag -d $releaseTag 2>$null
        git push origin --delete $releaseTag 2>$null
        Start-Sleep -Seconds 2
    }
} catch {
    # Release doesn't exist, continue
}

# Determine if prerelease
$isPrerelease = $Version -match '(alpha|beta|rc|preview|pre)'
$title = if ($isPrerelease) { "🧪 Prerelease $releaseTag" } else { "🚀 $ActionName $releaseTag" }

# Create draft release
$ghArgs = @(
    'release', 'create', $releaseTag,
    '--title', $title,
    '--notes-file', 'release_notes.md',
    '--generate-notes',
    '--draft'
)

if ($isPrerelease) {
    $ghArgs += '--prerelease'
}

& gh @ghArgs

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create GitHub release"
    exit 1
}

# Build release URL
$releaseUrl = "https://github.com/$Repository/releases/tag/$releaseTag"

# Set outputs
"release-created=true" >> $env:GITHUB_OUTPUT
"release-tag=$releaseTag" >> $env:GITHUB_OUTPUT
"release-url=$releaseUrl" >> $env:GITHUB_OUTPUT
Write-Output "✅ **Draft release created:** ``$releaseTag``" >> $env:GITHUB_STEP_SUMMARY
