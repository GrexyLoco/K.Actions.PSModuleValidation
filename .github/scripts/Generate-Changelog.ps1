<#
.SYNOPSIS
    Generates changelog for action release

.DESCRIPTION
    Creates formatted changelog based on git commit history
    Includes action capabilities and usage examples

.PARAMETER Version
    Version number for the release

.NOTES
    Platform-agnostic PowerShell script for CI/CD pipelines
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
    Write-Information "📝 Generating changelog for version $Version..."
    
    # Get latest tag
    $latestTag = git describe --tags --abbrev=0 2>$null
    
    # Get commits since last tag
    if ($latestTag) {
        $commits = git log --pretty=format:"- %s" "$latestTag..HEAD"
        Write-Information "  Commits since $latestTag`: $(@($commits).Count)"
    } else {
        $commits = git log --pretty=format:"- %s" | Select-Object -First 10
        Write-Information "  Initial release - showing first 10 commits"
    }
    
    # Build changelog
    $changelogLines = @()
    $changelogLines += "## What's Changed in $Version"
    $changelogLines += ""
    $changelogLines += "### 🚀 Features & Improvements"
    if ($commits) {
        $changelogLines += $commits
    } else {
        $changelogLines += "- Initial release"
    }
    $changelogLines += ""
    $changelogLines += "### 🛡️ Action Capabilities"
    $changelogLines += "- **Security Scanning**: GitLeaks"
    $changelogLines += "- **PowerShell Linting**: PSScriptAnalyzer"
    $changelogLines += "- **Structure Validation**: action.yml schema checks"
    $changelogLines += "- **Enterprise Ready**: Fully parametrized for reuse"
    $changelogLines += ""
    $changelogLines += "### 📋 Usage"
    $changelogLines += '```yaml'
    $changelogLines += "- name: Validate PowerShell Module"
    $changelogLines += "  uses: GrexyLoco/K.Actions.PSModuleValidation@$Version"
    $changelogLines += "  with:"
    $changelogLines += '    github-token: ${{ secrets.GITHUB_TOKEN }}'
    $changelogLines += "    module-name: 'YourModule'"
    $changelogLines += '```'
    
    if ($latestTag) {
        $changelogLines += ""
        $changelogLines += "**Full Changelog**: https://github.com/GrexyLoco/K.Actions.PSModuleValidation/compare/$latestTag...$Version"
    }
    
    $changelog = $changelogLines -join "`n"
    
    # Write to GITHUB_OUTPUT using heredoc syntax
    if ($env:GITHUB_OUTPUT) {
        "changelog<<EOF" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        $changelog | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "EOF" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    }
    
    Write-Information "✅ Changelog generated successfully"
    exit 0
    
} catch {
    Write-Error "Changelog generation failed: $_"
    throw
}
