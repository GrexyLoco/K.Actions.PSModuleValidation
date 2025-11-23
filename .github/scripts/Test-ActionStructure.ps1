<#
.SYNOPSIS
    Validates GitHub Action structure and schema

.DESCRIPTION
    Performs comprehensive validation of action.yml including:
    - Required sections (name, description, inputs, outputs, runs)
    - Action type detection (composite, JavaScript, Docker)
    - YAML syntax validation
    - Input/Output schema validation

.NOTES
    Platform-agnostic PowerShell script for CI/CD pipelines
    Outputs results to GITHUB_OUTPUT for workflow consumption
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

function Test-ActionYamlStructure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ActionYamlPath
    )

    Write-Information "🔍 Validating GitHub Action structure..."
    
    if (-not (Test-Path $ActionYamlPath)) {
        throw "action.yml not found at: $ActionYamlPath"
    }

    $actionContent = Get-Content $ActionYamlPath -Raw
    
    # Extract action name
    $actionName = if ($actionContent -match 'name:\s*[''"]?([^''"]+)[''"]?') {
        $matches[1].Trim()
    } else {
        'Unknown'
    }
    
    Write-Information "📦 Detected Action: $actionName"
    
    # Validate required sections
    $requiredSections = @('name:', 'description:', 'inputs:', 'outputs:', 'runs:')
    $sectionsFound = 0
    $issues = @()
    
    foreach ($section in $requiredSections) {
        if ($actionContent -match $section) {
            Write-Information "✅ Found section: $section"
            $sectionsFound++
        } else {
            Write-Information "❌ Missing section: $section"
            $issues += "Missing required section: $section"
        }
    }
    
    # Detect action type
    $actionType = 'Unknown'
    if ($actionContent -match 'using:\s*[''"]?composite[''"]?') {
        $actionType = 'Composite'
    } elseif ($actionContent -match 'using:\s*[''"]?node\d+[''"]?') {
        $actionType = 'JavaScript'
    } elseif ($actionContent -match 'using:\s*[''"]?docker[''"]?') {
        $actionType = 'Docker'
    }
    
    Write-Information "🎯 Action Type: $actionType"
    
    $structureSuccess = $sectionsFound -eq $requiredSections.Count -and $issues.Count -eq 0
    
    return @{
        Success = $structureSuccess
        ActionName = $actionName
        ActionType = $actionType
        SectionsFound = $sectionsFound
        IssuesCount = $issues.Count
        Issues = $issues
    }
}

function Test-ActionSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ActionYamlPath
    )

    Write-Information "📋 Validating Input/Output Schema..."
    
    $actionContent = Get-Content $ActionYamlPath -Raw
    $schemaIssues = @()
    
    # Validate inputs
    $inputSection = ($actionContent -split 'inputs:')[1] -split 'outputs:' | Select-Object -First 1
    $inputsValid = 0
    $inputsTotal = 0
    
    if ($inputSection) {
        $inputMatches = [regex]::Matches($inputSection, '^\s+([a-zA-Z0-9-]+):\s*$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
        $inputsTotal = $inputMatches.Count
        
        foreach ($match in $inputMatches) {
            $inputName = $match.Groups[1].Value
            $inputBlock = ($inputSection -split "${inputName}:")[1] -split '^\s+[a-zA-Z0-9-]+:\s*$' | Select-Object -First 1
            
            $hasDescription = $inputBlock -match 'description:'
            $hasRequired = $inputBlock -match 'required:'
            
            if ($hasDescription -and $hasRequired) {
                Write-Information "✅ Input '$inputName': Valid schema"
                $inputsValid++
            } else {
                Write-Information "❌ Input '$inputName': Missing description or required field"
                $schemaIssues += "Input '$inputName' missing required schema fields"
            }
        }
    }
    
    # Validate outputs
    $outputSection = ($actionContent -split 'outputs:')[1] -split 'runs:' | Select-Object -First 1
    $outputsValid = 0
    $outputsTotal = 0
    
    if ($outputSection) {
        $outputMatches = [regex]::Matches($outputSection, '^\s+([a-zA-Z0-9-]+):\s*$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
        $outputsTotal = $outputMatches.Count
        
        foreach ($match in $outputMatches) {
            $outputName = $match.Groups[1].Value
            $outputBlock = ($outputSection -split "${outputName}:")[1] -split '^\s+[a-zA-Z0-9-]+:\s*$' | Select-Object -First 1
            
            $hasDescription = $outputBlock -match 'description:'
            $hasValue = $outputBlock -match 'value:'
            
            if ($hasDescription -and $hasValue) {
                Write-Information "✅ Output '$outputName': Valid schema"
                $outputsValid++
            } else {
                Write-Information "❌ Output '$outputName': Missing description or value"
                $schemaIssues += "Output '$outputName' missing required schema fields"
            }
        }
    }
    
    $schemaSuccess = $schemaIssues.Count -eq 0 -and $inputsTotal -gt 0 -and $outputsTotal -gt 0
    
    Write-Information "📊 Schema validation results:"
    Write-Information "   📥 Inputs: $inputsValid/$inputsTotal valid"
    Write-Information "   📤 Outputs: $outputsValid/$outputsTotal valid"
    Write-Information "   ❌ Issues: $($schemaIssues.Count)"
    
    return @{
        Success = $schemaSuccess
        InputsValid = $inputsValid
        InputsTotal = $inputsTotal
        OutputsValid = $outputsValid
        OutputsTotal = $outputsTotal
        IssuesCount = $schemaIssues.Count
        Issues = $schemaIssues
    }
}

try {
    # Run validations
    $structureResult = Test-ActionYamlStructure -ActionYamlPath './action.yml'
    $schemaResult = Test-ActionSchema -ActionYamlPath './action.yml'
    
    # Write outputs for GitHub Actions
    if ($env:GITHUB_OUTPUT) {
        "structure-success=$($structureResult.Success)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "action-name=$($structureResult.ActionName)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "action-type=$($structureResult.ActionType)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "sections-found=$($structureResult.SectionsFound)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "structure-issues=$($structureResult.IssuesCount)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        
        "schema-success=$($schemaResult.Success)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "inputs-valid=$($schemaResult.InputsValid)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "inputs-total=$($schemaResult.InputsTotal)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "outputs-valid=$($schemaResult.OutputsValid)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "outputs-total=$($schemaResult.OutputsTotal)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        "schema-issues=$($schemaResult.IssuesCount)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    }
    
    # Exit with appropriate code
    if (-not $structureResult.Success -or -not $schemaResult.Success) {
        Write-Information ""
        Write-Information "❌ Action validation failed!"
        
        if ($structureResult.Issues) {
            Write-Information "Structure issues:"
            $structureResult.Issues | ForEach-Object { Write-Information "  - $_" }
        }
        if ($schemaResult.Issues) {
            Write-Information "Schema issues:"
            $schemaResult.Issues | ForEach-Object { Write-Information "  - $_" }
        }
        
        exit 1
    }
    
    Write-Information ""
    Write-Information "✅ Action validation passed!"
    exit 0
    
} catch {
    Write-Error "Action validation failed: $_"
    throw
}
