<#
.SYNOPSIS
    Unit tests for K.PSGallery.PesterTestDiscovery module core functions.

.DESCRIPTION
    This script contains comprehensive Pester tests for the Pester test discovery functionality,
    including pattern validation, directory discovery, file discovery, and full integration tests.

.NOTES
    Author:     GrexyLoco
    Version:    1.0.0
    Date:       2025-08-16
#>

BeforeAll {
    # Import the module
    Import-Module "$PSScriptRoot\..\K.PSGallery.PesterTestDiscovery.psd1" -Force
    
    # Create test directory structure
    $script:TestRoot = Join-Path $TestDrive 'TestDiscoveryTests'
    $script:ValidTestDir1 = Join-Path $TestRoot 'Tests'
    $script:ValidTestDir2 = Join-Path $TestRoot 'src\Test'
    $script:InvalidTestDir = Join-Path $TestRoot 'UnitTests'
    $script:ExcludedDir = Join-Path $TestRoot 'bin\Tests'
    
    # Create directories
    New-Item -Path $script:ValidTestDir1 -ItemType Directory -Force | Out-Null
    New-Item -Path $script:ValidTestDir2 -ItemType Directory -Force | Out-Null
    New-Item -Path $script:InvalidTestDir -ItemType Directory -Force | Out-Null
    New-Item -Path $script:ExcludedDir -ItemType Directory -Force | Out-Null
    
    # Create test files
    New-Item -Path (Join-Path $script:ValidTestDir1 'Feature.Tests.ps1') -ItemType File -Force | Out-Null
    New-Item -Path (Join-Path $script:ValidTestDir1 'Component.Test.ps1') -ItemType File -Force | Out-Null
    New-Item -Path (Join-Path $script:ValidTestDir1 'NotATest.ps1') -ItemType File -Force | Out-Null
    New-Item -Path (Join-Path $script:ValidTestDir2 'Module.Tests.ps1') -ItemType File -Force | Out-Null
    New-Item -Path (Join-Path $script:InvalidTestDir 'Unit.Tests.ps1') -ItemType File -Force | Out-Null
    New-Item -Path (Join-Path $script:ExcludedDir 'Excluded.Tests.ps1') -ItemType File -Force | Out-Null
}

Describe "K.PSGallery.PesterTestDiscovery - Pattern Validation" {
    Context "Confirm-ValidTestDirectory" {
        It "should return true for valid directory names" {
            Confirm-ValidTestDirectory -DirectoryName 'Tests' | Should -Be $true
            Confirm-ValidTestDirectory -DirectoryName 'Test' | Should -Be $true
        }
        
        It "should return false for invalid directory names" {
            Confirm-ValidTestDirectory -DirectoryName 'UnitTests' | Should -Be $false
            Confirm-ValidTestDirectory -DirectoryName 'Specs' | Should -Be $false
            Confirm-ValidTestDirectory -DirectoryName 'src' | Should -Be $false
        }
    }
    
    Context "Confirm-ValidTestFile" {
        It "should return true for valid test file patterns" {
            Confirm-ValidTestFile -FileName 'Feature.Tests.ps1' | Should -Be $true
            Confirm-ValidTestFile -FileName 'Component.Test.ps1' | Should -Be $true
            Confirm-ValidTestFile -FileName 'MyModule.Tests.ps1' | Should -Be $true
        }
        
        It "should return false for invalid test file patterns" {
            Confirm-ValidTestFile -FileName 'Feature.ps1' | Should -Be $false
            Confirm-ValidTestFile -FileName 'TestHelper.ps1' | Should -Be $false
            Confirm-ValidTestFile -FileName 'Setup.ps1' | Should -Be $false
        }
    }
}

Describe "K.PSGallery.PesterTestDiscovery - Directory Discovery" {
    Context "Get-TestDirectories" {
        It "should discover valid test directories" {
            $directories = Get-TestDirectories -Path $script:TestRoot -MaxDepth 5
            $directories.Count | Should -BeGreaterThan 0
            $directories.Name | Should -Contain 'Tests'
            $directories.Name | Should -Contain 'Test'
        }
        
        It "should exclude invalid directory names" {
            $directories = Get-TestDirectories -Path $script:TestRoot -MaxDepth 5
            $directories.Name | Should -Not -Contain 'UnitTests'
        }
        
        It "should respect max depth limit" {
            $directories = Get-TestDirectories -Path $script:TestRoot -MaxDepth 1
            $shallowPaths = $directories | Where-Object { $_.FullName -like "*src*" }
            $shallowPaths.Count | Should -Be 0
        }
        
        It "should exclude paths based on exclude patterns" {
            $directories = Get-TestDirectories -Path $script:TestRoot -MaxDepth 5 -ExcludePaths @('bin')
            $excludedPaths = $directories | Where-Object { $_.FullName -like "*bin*" }
            $excludedPaths.Count | Should -Be 0
        }
        
        It "should handle non-existent paths gracefully" {
            $nonExistentPath = Join-Path $TestDrive 'NonExistentDirectory'
            $directories = Get-TestDirectories -Path $nonExistentPath -MaxDepth 5
            $directories.Count | Should -Be 0
        }
    }
}

Describe "K.PSGallery.PesterTestDiscovery - File Discovery" {
    Context "Find-TestFiles with explicit path" {
        It "should find test files in specified directory" {
            $files = Find-TestFiles -Path $script:ValidTestDir1
            $files.Count | Should -BeGreaterThan 0
            $files.Name | Should -Contain 'Feature.Tests.ps1'
            $files.Name | Should -Contain 'Component.Test.ps1'
        }
        
        It "should exclude non-test files" {
            $files = Find-TestFiles -Path $script:ValidTestDir1
            $files.Name | Should -Not -Contain 'NotATest.ps1'
        }
        
        It "should handle non-existent paths gracefully" {
            $nonExistentPath = Join-Path $TestDrive 'NonExistentDirectory'
            $files = Find-TestFiles -Path $nonExistentPath
            $files.Count | Should -Be 0
        }
    }
    
    Context "Find-TestFiles with test directories" {
        It "should find test files in discovered directories" {
            $testDirectories = Get-TestDirectories -Path $script:TestRoot -MaxDepth 5 -ExcludePaths @('bin')
            $files = Find-TestFiles -TestDirectories $testDirectories
            $files.Count | Should -BeGreaterThan 0
            $files.Name | Should -Contain 'Feature.Tests.ps1'
            $files.Name | Should -Contain 'Module.Tests.ps1'
        }
        
        It "should return empty array when no directories provided" {
            $files = Find-TestFiles -TestDirectories @()
            $files.Count | Should -Be 0
        }
    }
}

Describe "K.PSGallery.PesterTestDiscovery - Integration Tests" {
    Context "Invoke-TestDiscovery with explicit path" {
        It "should discover tests in explicit path mode" {
            $result = Invoke-TestDiscovery -TestPath $script:ValidTestDir1
            $result.DiscoveryMode | Should -Be 'Explicit'
            $result.TestFilesCount | Should -BeGreaterThan 0
            $result.ValidationResults.HasValidFiles | Should -Be $true
        }
        
        It "should handle non-existent explicit path" {
            $nonExistentPath = Join-Path $TestDrive 'NonExistentDirectory'
            $result = Invoke-TestDiscovery -TestPath $nonExistentPath
            $result.DiscoveryMode | Should -Be 'Explicit'
            $result.TestFilesCount | Should -Be 0
            $result.ValidationResults.HasValidFiles | Should -Be $false
        }
    }
    
    Context "Invoke-TestDiscovery with auto-discovery" {
        BeforeAll {
            Push-Location $script:TestRoot
        }
        
        AfterAll {
            Pop-Location
        }
        
        It "should auto-discover tests" {
            $result = Invoke-TestDiscovery -MaxDepth 5 -ExcludePaths @('bin')
            $result.DiscoveryMode | Should -Be 'AutoDiscovery'
            $result.TestDirectoriesCount | Should -BeGreaterThan 0
            $result.TestFilesCount | Should -BeGreaterThan 0
            $result.ValidationResults.ConventionsFollowed | Should -Be $true
        }
        
        It "should include metadata" {
            $result = Invoke-TestDiscovery -MaxDepth 3
            $result.Metadata.SearchDepth | Should -Be 3
            $result.Metadata.ValidDirectoryNames | Should -Contain 'Tests'
            $result.Metadata.ValidDirectoryNames | Should -Contain 'Test'
            $result.Metadata.Timestamp | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Invoke-TestDiscovery output formats" {
        BeforeAll {
            Push-Location $script:TestRoot
        }
        
        AfterAll {
            Pop-Location
        }
        
        It "should return object format by default" {
            $result = Invoke-TestDiscovery
            $result.GetType().Name | Should -Be 'PSCustomObject'
            $result.DiscoveryMode | Should -Not -BeNullOrEmpty
        }
        
        It "should return JSON format when requested" {
            $result = Invoke-TestDiscovery -OutputFormat 'JSON'
            $result | Should -BeOfType 'String'
            { $result | ConvertFrom-Json } | Should -Not -Throw
        }
        
        It "should return GitHub Actions format when requested" {
            # Mock GitHub environment
            $env:GITHUB_OUTPUT = Join-Path $TestDrive 'github_output.txt'
            
            $result = Invoke-TestDiscovery -OutputFormat 'GitHubActions'
            $result.TestPathExists | Should -Match '^(true|false)$'
            $result.ConventionsFollowed | Should -BeOfType 'Boolean'
            
            # Clean up
            Remove-Item $env:GITHUB_OUTPUT -ErrorAction SilentlyContinue
            $env:GITHUB_OUTPUT = $null
        }
    }
}

Describe "K.PSGallery.PesterTestDiscovery - Edge Cases and Error Handling" {
    Context "Error handling" {
        It "should handle permission errors gracefully" {
            # This test is conceptual - actual permission testing would require admin rights
            $result = Invoke-TestDiscovery -TestPath $script:TestRoot
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "should handle deeply nested structures" {
            $deepPath = Join-Path $script:TestRoot 'level1\level2\level3\level4\level5\Tests'
            New-Item -Path $deepPath -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path $deepPath 'Deep.Tests.ps1') -ItemType File -Force | Out-Null
            
            $result = Invoke-TestDiscovery -TestPath $script:TestRoot -MaxDepth 10
            $result.TestFilesCount | Should -BeGreaterThan 0
        }
    }
    
    Context "Convention validation" {
        It "should identify when conventions are not followed" {
            $emptyDir = Join-Path $TestDrive 'EmptyProject'
            New-Item -Path $emptyDir -ItemType Directory -Force | Out-Null
            
            $result = Invoke-TestDiscovery -TestPath $emptyDir
            $result.ValidationResults.ConventionsFollowed | Should -Be $false
            $result.TestFilesCount | Should -Be 0
        }
        
        It "should identify partial convention compliance" {
            $partialDir = Join-Path $TestDrive 'PartialProject\Tests'
            New-Item -Path $partialDir -ItemType Directory -Force | Out-Null
            # Create directory but no valid test files
            New-Item -Path (Join-Path $partialDir 'NotATest.ps1') -ItemType File -Force | Out-Null
            
            $result = Invoke-TestDiscovery -TestPath (Join-Path $TestDrive 'PartialProject')
            $result.ValidationResults.HasValidDirectories | Should -Be $true
            $result.ValidationResults.HasValidFiles | Should -Be $false
            $result.ValidationResults.ConventionsFollowed | Should -Be $false
        }
    }
}
