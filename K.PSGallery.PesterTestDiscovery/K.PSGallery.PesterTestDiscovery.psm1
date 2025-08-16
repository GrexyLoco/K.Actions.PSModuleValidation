<#
.SYNOPSIS
    PowerShell module for intelligent test discovery using naming conventions.

.DESCRIPTION
    This module provides functions for automatically discovering Pester tests based on strict naming conventions.
    It follows enterprise-grade patterns for reliable test discovery in CI/CD pipelines and supports 
    configurable depth limits, pattern validation, and comprehensive error handling.

.NOTES
    Author:     GrexyLoco
    Version:    1.0.0
    Date:       2025-08-16
    License:    MIT
#>

#region Configuration Constants
$script:DefaultMaxDepth = 5
$script:ValidTestDirectoryNames = @('Test', 'Tests')
$script:ValidTestFilePatterns = @('*.Test.ps1', '*.Tests.ps1')
$script:DefaultExcludePaths = @('TestSetup', 'test-module', '.github', 'bin', 'obj', 'packages')
#endregion

#region Helper Functions
function Write-TestDiscoveryLog {
    <#
    .SYNOPSIS
        Writes formatted log messages for test discovery operations.
    
    .PARAMETER Message
        The message to write.
    
    .PARAMETER Level
        The log level (Info, Warning, Error, Success).
    
    .PARAMETER Context
        Optional context information.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Debug')]
        [string]$Level = 'Info',
        
        [Parameter(Mandatory = $false)]
        [string]$Context = ''
    )
    
    $emoji = switch ($Level) {
        'Info'    { '🔍' }
        'Warning' { '⚠️' }
        'Error'   { '❌' }
        'Success' { '✅' }
        'Debug'   { '🔹' }
    }
    
    $color = switch ($Level) {
        'Info'    { 'Cyan' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        'Success' { 'Green' }
        'Debug'   { 'Gray' }
    }
    
    Write-Host "$emoji $Message" -ForegroundColor $color
    if ($Context) {
        Write-Host "   $Context" -ForegroundColor DarkGray
    }
}

function Get-RelativeDepth {
    <#
    .SYNOPSIS
        Calculates the relative depth of a path from the base path.
    
    .PARAMETER BasePath
        The base path to calculate depth from.
    
    .PARAMETER TargetPath
        The target path to calculate depth for.
    
    .OUTPUTS
        [int] The relative depth.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )
    
    $baseSegments = $BasePath.Split([IO.Path]::DirectorySeparatorChar, [StringSplitOptions]::RemoveEmptyEntries)
    $targetSegments = $TargetPath.Split([IO.Path]::DirectorySeparatorChar, [StringSplitOptions]::RemoveEmptyEntries)
    
    return [Math]::Max(0, $targetSegments.Count - $baseSegments.Count)
}
#endregion

#region Core Functions
function Confirm-ValidTestDirectory {
    <#
    .SYNOPSIS
        Validates if a directory name matches the strict test directory naming convention.
    
    .DESCRIPTION
        Checks directory names against the fixed test directory naming conventions.
        Only directories named 'Test' or 'Tests' are considered valid.
    
    .PARAMETER DirectoryName
        The directory name to validate.
    
    .OUTPUTS
        [bool] True if the directory name matches valid patterns.
    
    .EXAMPLE
        Confirm-ValidTestDirectory -DirectoryName 'Tests'
        Returns $true
    
    .EXAMPLE
        Confirm-ValidTestDirectory -DirectoryName 'UnitTests'
        Returns $false (not in valid names)
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectoryName
    )
    
    return $DirectoryName -in $script:ValidTestDirectoryNames
}

function Confirm-ValidTestFile {
    <#
    .SYNOPSIS
        Validates if a file name matches the strict test file naming convention.
    
    .DESCRIPTION
        Checks file names against the fixed test file naming conventions.
        Only files ending with '.Test.ps1' or '.Tests.ps1' are considered valid.
    
    .PARAMETER FileName
        The file name to validate.
    
    .OUTPUTS
        [bool] True if the file name matches valid patterns.
    
    .EXAMPLE
        Confirm-ValidTestFile -FileName 'MyFeature.Tests.ps1'
        Returns $true
    
    .EXAMPLE
        Confirm-ValidTestFile -FileName 'MyFeature.ps1'
        Returns $false (doesn't match test patterns)
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )
    
    foreach ($pattern in $script:ValidTestFilePatterns) {
        if ($FileName -like $pattern) {
            return $true
        }
    }
    
    return $false
}

function Get-TestDirectories {
    <#
    .SYNOPSIS
        Discovers test directories based on naming conventions.
    
    .DESCRIPTION
        Recursively searches for directories that match the test directory naming conventions.
        Respects maximum depth limits and exclude patterns for optimal performance.
    
    .PARAMETER Path
        The root path to search from. Defaults to current directory.
    
    .PARAMETER MaxDepth
        Maximum search depth. Defaults to 5 levels.
    
    .PARAMETER ExcludePaths
        Array of path patterns to exclude from search.
    
    .OUTPUTS
        [System.IO.DirectoryInfo[]] Array of discovered test directories.
    
    .EXAMPLE
        Get-TestDirectories -Path 'C:\MyProject' -MaxDepth 3
        Searches for test directories up to 3 levels deep in C:\MyProject
    #>
    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location).Path,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = $script:DefaultMaxDepth,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludePaths = $script:DefaultExcludePaths
    )
    
    Write-TestDiscoveryLog "Searching for test directories in: $Path" -Level 'Info'
    Write-TestDiscoveryLog "Max depth: $MaxDepth, Valid names: $($script:ValidTestDirectoryNames -join ', ')" -Level 'Debug'
    
    # Early exit if path doesn't exist
    if (-not (Test-Path $Path)) {
        Write-TestDiscoveryLog "Path does not exist: $Path" -Level 'Warning'
        return @()
    }
    
    $discoveredDirectories = @()
    
    try {
        $allDirectories = Get-ChildItem -Path $Path -Directory -Recurse -ErrorAction SilentlyContinue
        
        foreach ($directory in $allDirectories) {
            # Check depth limit
            $depth = Get-RelativeDepth -BasePath $Path -TargetPath $directory.FullName
            if ($depth -gt $MaxDepth) {
                continue
            }
            
            # Check exclude patterns
            $shouldExclude = $false
            foreach ($excludePattern in $ExcludePaths) {
                if ($directory.FullName -like "*$excludePattern*") {
                    $shouldExclude = $true
                    break
                }
            }
            
            if ($shouldExclude) {
                continue
            }
            
            # Check if directory name matches pattern
            if (Confirm-ValidTestDirectory -DirectoryName $directory.Name) {
                $discoveredDirectories += $directory
                Write-TestDiscoveryLog "Found test directory: $($directory.FullName)" -Level 'Success'
            }
        }
    }
    catch {
        Write-TestDiscoveryLog "Error searching directories: $($_.Exception.Message)" -Level 'Error'
        throw
    }
    
    Write-TestDiscoveryLog "Discovered $($discoveredDirectories.Count) test directories" -Level 'Info'
    
    # Warning for multiple test directories - should only have one per project
    if ($discoveredDirectories.Count -gt 1) {
        Write-TestDiscoveryLog "Multiple test directories found - consider consolidating to a single test directory per project" -Level 'Warning'
        foreach ($dir in $discoveredDirectories) {
            Write-TestDiscoveryLog "   Found: $($dir.FullName)" -Level 'Warning'
        }
    }
    
    return $discoveredDirectories
}

function Find-TestFiles {
    <#
    .SYNOPSIS
        Discovers test files in specified directories or paths.
    
    .DESCRIPTION
        Searches for test files that match the configured naming patterns within the specified
        directories. Supports both explicit directory paths and auto-discovery mode.
    
    .PARAMETER TestDirectories
        Array of test directories to search in.
    
    .PARAMETER Path
        Explicit path to search for test files (alternative to TestDirectories).
    
    .PARAMETER Recursive
        Whether to search recursively within test directories.
    
    .OUTPUTS
        [System.IO.FileInfo[]] Array of discovered test files.
    
    .EXAMPLE
        Find-TestFiles -Path 'C:\MyProject\Tests'
        Finds all test files in the specified directory
    
    .EXAMPLE
        $testDirs = Get-TestDirectories
        Find-TestFiles -TestDirectories $testDirs -Recursive
        Finds test files in discovered test directories recursively
    #>
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = 'Directories')]
        [System.IO.DirectoryInfo[]]$TestDirectories,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'Path')]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [switch]$Recursive
    )
    
    $discoveredFiles = @()
    $searchPaths = @()
    
    # Determine search paths
    if ($PSCmdlet.ParameterSetName -eq 'Path' -and $Path) {
        $searchPaths += $Path
    }
    elseif ($TestDirectories) {
        $searchPaths += $TestDirectories.FullName
    }
    else {
        Write-TestDiscoveryLog "No search paths specified" -Level 'Warning'
        return $discoveredFiles
    }
    
    foreach ($searchPath in $searchPaths) {
        Write-TestDiscoveryLog "Searching for test files in: $searchPath" -Level 'Debug'
        
        # Skip if path doesn't exist
        if (-not (Test-Path $searchPath)) {
            Write-TestDiscoveryLog "Path does not exist: $searchPath" -Level 'Warning'
            continue
        }
        
        try {
            foreach ($pattern in $script:ValidTestFilePatterns) {
                $files = Get-ChildItem -Path $searchPath -Filter $pattern -File -Recurse:$Recursive.IsPresent -ErrorAction SilentlyContinue
                
                foreach ($file in $files) {
                    # Double-check pattern (Get-ChildItem filter can be broad)
                    if (Confirm-ValidTestFile -FileName $file.Name) {
                        $discoveredFiles += $file
                        Write-TestDiscoveryLog "Found test file: $($file.FullName)" -Level 'Success'
                    }
                }
            }
        }
        catch {
            Write-TestDiscoveryLog "Error searching files in $searchPath : $($_.Exception.Message)" -Level 'Error'
        }
    }
    
    # Remove duplicates
    $uniqueFiles = $discoveredFiles | Sort-Object FullName | Get-Unique -AsString
    Write-TestDiscoveryLog "Discovered $($uniqueFiles.Count) unique test files" -Level 'Info'
    
    return $uniqueFiles
}

function Invoke-TestDiscovery {
    <#
    .SYNOPSIS
        Performs comprehensive test discovery with configurable options.
    
    .DESCRIPTION
        Main function that orchestrates the complete test discovery process. It can operate
        in explicit path mode or auto-discovery mode, validates conventions, and provides
        detailed reporting of discovered tests.
    
    .PARAMETER TestPath
        Explicit test path to search. If empty, auto-discovery will be used.
    
    .PARAMETER MaxDepth
        Maximum search depth for auto-discovery.
    
    .PARAMETER ExcludePaths
        Array of path patterns to exclude from search.
    
    .PARAMETER OutputFormat
        Output format for results (Object, GitHubActions, JSON).
    
    .PARAMETER Detailed
        Include detailed information about discovery process.
    
    .OUTPUTS
        [PSCustomObject] Discovery results with paths, files, and metadata.
    
    .EXAMPLE
        Invoke-TestDiscovery
        Performs auto-discovery using default settings
    
    .EXAMPLE
        Invoke-TestDiscovery -TestPath 'Tests' -OutputFormat 'GitHubActions'
        Searches explicit path and formats output for GitHub Actions
    
    .EXAMPLE
        Invoke-TestDiscovery -MaxDepth 3 -ExcludePaths @('bin', 'obj') -Detailed
        Auto-discovery with custom depth and exclusions, detailed output
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TestPath = '',
        
        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = $script:DefaultMaxDepth,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludePaths = $script:DefaultExcludePaths,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Object', 'GitHubActions', 'JSON')]
        [string]$OutputFormat = 'Object',
        
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    
    Write-TestDiscoveryLog "Starting test discovery process" -Level 'Info'
    
    $result = [PSCustomObject]@{
        DiscoveryMode = ''
        TestDirectories = @()
        TestFiles = @()
        TestDirectoriesCount = 0
        TestFilesCount = 0
        DiscoveredPaths = @()
        ValidationResults = [PSCustomObject]@{
            HasValidDirectories = $false
            HasValidFiles = $false
            ConventionsFollowed = $false
        }
        Metadata = [PSCustomObject]@{
            SearchDepth = $MaxDepth
            ExcludedPaths = $ExcludePaths
            ValidDirectoryNames = $script:ValidTestDirectoryNames
            ValidFilePatterns = $script:ValidTestFilePatterns
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
    }
    
    try {
        if ($TestPath -and $TestPath.Trim() -ne '') {
            # Explicit path mode
            $result.DiscoveryMode = 'Explicit'
            Write-TestDiscoveryLog "Using explicit test path: $TestPath" -Level 'Info'
            
            if (Test-Path $TestPath) {
                $result.TestDirectories = @([System.IO.DirectoryInfo]$TestPath)
                $result.DiscoveredPaths = @($TestPath)
                $result.TestFiles = Find-TestFiles -Path $TestPath -Recursive
            }
            else {
                Write-TestDiscoveryLog "Specified test path does not exist: $TestPath" -Level 'Warning'
            }
        }
        else {
            # Auto-discovery mode
            $result.DiscoveryMode = 'AutoDiscovery'
            Write-TestDiscoveryLog "Using auto-discovery with naming conventions" -Level 'Info'
            
            $result.TestDirectories = Get-TestDirectories -MaxDepth $MaxDepth -ExcludePaths $ExcludePaths
            $result.DiscoveredPaths = $result.TestDirectories.FullName
            
            if ($result.TestDirectories.Count -gt 0) {
                $result.TestFiles = Find-TestFiles -TestDirectories $result.TestDirectories -Recursive
            }
        }
        
        # Update counts
        $result.TestDirectoriesCount = $result.TestDirectories.Count
        $result.TestFilesCount = $result.TestFiles.Count
        
        # Validation
        $result.ValidationResults.HasValidDirectories = $result.TestDirectoriesCount -gt 0
        $result.ValidationResults.HasValidFiles = $result.TestFilesCount -gt 0
        $result.ValidationResults.ConventionsFollowed = $result.ValidationResults.HasValidDirectories -and $result.ValidationResults.HasValidFiles
        
        # Detailed reporting
        if ($Detailed -or $result.TestFilesCount -eq 0) {
            Write-TestDiscoveryLog "Discovery complete - Summary:" -Level 'Success'
            Write-TestDiscoveryLog "Mode: $($result.DiscoveryMode)" -Level 'Info'
            Write-TestDiscoveryLog "Test directories: $($result.TestDirectoriesCount)" -Level 'Info'
            Write-TestDiscoveryLog "Test files: $($result.TestFilesCount)" -Level 'Info'
            
            if ($result.TestFilesCount -eq 0) {
                Write-TestDiscoveryLog "No test files found matching conventions" -Level 'Warning'
                Write-TestDiscoveryLog "Expected: Folders named 'Test'/'Tests' containing '*.Test.ps1'/'*.Tests.ps1' files" -Level 'Info'
            }
        }
        
        # Format output
        switch ($OutputFormat) {
            'GitHubActions' {
                return Format-GitHubActionsOutput -Result $result
            }
            'JSON' {
                return $result | ConvertTo-Json -Depth 5
            }
            default {
                return $result
            }
        }
    }
    catch {
        Write-TestDiscoveryLog "Error during test discovery: $($_.Exception.Message)" -Level 'Error'
        throw
    }
}
#endregion

#region Output Formatters
function Format-GitHubActionsOutput {
    <#
    .SYNOPSIS
        Formats discovery results for GitHub Actions output.
    
    .PARAMETER Result
        The discovery result object to format.
    
    .OUTPUTS
        [PSCustomObject] Formatted result for GitHub Actions consumption.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Result
    )
    
    $pathsString = $Result.DiscoveredPaths -join ';'
    $testPathExists = if ($Result.TestFilesCount -gt 0) { 'true' } else { 'false' }
    
    # Set GitHub Actions outputs
    if ($env:GITHUB_OUTPUT) {
        Write-Output "test-path-exists=$testPathExists" >> $env:GITHUB_OUTPUT
        Write-Output "discovered-paths=$pathsString" >> $env:GITHUB_OUTPUT
        Write-Output "test-files-count=$($Result.TestFilesCount)" >> $env:GITHUB_OUTPUT
        Write-Output "test-directories-count=$($Result.TestDirectoriesCount)" >> $env:GITHUB_OUTPUT
        Write-Output "conventions-followed=$($Result.ValidationResults.ConventionsFollowed.ToString().ToLower())" >> $env:GITHUB_OUTPUT
    }
    
    return [PSCustomObject]@{
        TestPathExists = $testPathExists
        DiscoveredPaths = $pathsString
        TestFilesCount = $Result.TestFilesCount
        TestDirectoriesCount = $Result.TestDirectoriesCount
        ConventionsFollowed = $Result.ValidationResults.ConventionsFollowed
    }
}
#endregion

# Export module members (functions are exported via module manifest)
Export-ModuleMember -Function 'Find-TestFiles', 'Get-TestDirectories', 'Confirm-ValidTestFile', 'Confirm-ValidTestDirectory', 'Invoke-TestDiscovery'
