# K.PSGallery.PesterTestDiscovery

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)](https://docs.microsoft.com/en-us/powershell/)
[![Pester](https://img.shields.io/badge/Pester-5.0%2B-green?logo=powershell)](https://pester.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Intelligent PowerShell module for Pester test discovery using strict naming conventions for reliable CI/CD integration.

## 🚀 Features

- **🔍 Smart Auto-Discovery**: Automatically finds test files using strict naming conventions
- **📏 Fixed Conventions**: Enforces reliable patterns (`Test`/`Tests` directories, `.Test.ps1`/`.Tests.ps1` files)
- **⚙️ Configurable Search**: Customizable search depth and exclude patterns
- **🎯 Multiple Output Formats**: Object, JSON, and GitHub Actions output formats
- **🛡️ Robust Error Handling**: Graceful handling of non-existent paths and permission errors
- **📊 Detailed Reporting**: Comprehensive validation results and metadata
- **⚡ High Performance**: Early path validation prevents hanging on non-existent paths

## 📋 Naming Conventions

### Test Directories
- Must be named exactly `Test` or `Tests` (case-sensitive)
- **Exact matching only**: `UnitTests`, `IntegrationTests`, `MyTests` are **not** valid
- Searched recursively up to configurable depth (default: 5 levels)
- Supports exclude patterns for optimization

### Test Files  
- Must end with `.Test.ps1` or `.Tests.ps1`
- **Exact suffix matching**: `MyModule.UnitTest.ps1` is **not** valid
- Located within valid test directories
- Automatically validated against fixed patterns

### Example Structure
```
MyProject/
├── src/
│   └── MyModule.psm1
├── Tests/                    ✅ Valid directory name
│   ├── MyModule.Tests.ps1    ✅ Valid test file
│   ├── Feature.Test.ps1      ✅ Valid test file
│   └── Helper.ps1            ❌ Not a test file
└── UnitTests/                ❌ Invalid directory name
    └── Unit.Tests.ps1        ❌ Won't be discovered
```

## ⚠️ Important Considerations

### Single Test Directory Per Project
This module is designed with the expectation of **one test directory per project**. While it can discover multiple test directories, this is not recommended and will generate warnings.

**Recommended:**
```
MyProject/
├── src/
└── Tests/           ✅ Single test directory
    ├── Feature1.Tests.ps1
    └── Feature2.Tests.ps1
```

**Not Recommended:**
```
MyProject/
├── src/
├── Tests/           ⚠️ Multiple test directories
│   └── Unit.Tests.ps1
└── SomeOtherDir
    └── Test/  ⚠️ Will generate warning
        └── Integration.Tests.ps1
```

**Why Single Directory?**
- Simplifies test organization and discovery
- Reduces ambiguity in CI/CD pipelines  
- Follows PowerShell module conventions
- Prevents confusion about test execution scope

### Multiple Directory Detection
The module automatically warns when multiple test directories are found:
```powershell
# This will generate a warning
MyProject/
├── Tests/                   # ⚠️ First test directory
│   └── Unit.Tests.ps1
└── src/
    └── Test/               # ⚠️ Second test directory  
        └── Integration.Tests.ps1

# Output:
# ⚠️ Multiple test directories found - consider consolidating to a single test directory per project
# ⚠️    Found: C:\MyProject\Tests
# ⚠️    Found: C:\MyProject\src\Test
```

## 📦 Installation

### From Source
```powershell
# Clone or download the module
Import-Module .\K.PSGallery.PesterTestDiscovery\K.PSGallery.PesterTestDiscovery.psd1
```

### Manual Installation
```powershell
# Copy module to PowerShell modules path
$ModulePath = "$env:USERPROFILE\Documents\PowerShell\Modules\K.PSGallery.PesterTestDiscovery"
Copy-Item -Path ".\K.PSGallery.PesterTestDiscovery" -Destination $ModulePath -Recurse -Force
Import-Module K.PSGallery.PesterTestDiscovery
```

## 💡 Usage Examples

### Basic Auto-Discovery
```powershell
# Auto-discover tests in current directory
$result = Invoke-TestDiscovery
Write-Host "Found $($result.TestFilesCount) test files in $($result.TestDirectoriesCount) directories"
```

### Explicit Path Discovery
```powershell
# Search specific directory
$result = Invoke-TestDiscovery -TestPath './Tests'
$result.ValidationResults.ConventionsFollowed  # $true if conventions are met
```

### Advanced Configuration
```powershell
# Custom search with exclusions
$result = Invoke-TestDiscovery -MaxDepth 3 -ExcludePaths @('bin', 'obj', 'packages') -Detailed
```

### GitHub Actions Integration
```powershell
# Output format optimized for GitHub Actions
$result = Invoke-TestDiscovery -OutputFormat 'GitHubActions'
# Automatically sets GITHUB_OUTPUT variables
```

### Pattern Validation
```powershell
# Validate directory names (fixed patterns only)
Confirm-ValidTestDirectory -DirectoryName 'Tests'       # $true
Confirm-ValidTestDirectory -DirectoryName 'UnitTests'   # $false

# Validate file names (fixed patterns only)
Confirm-ValidTestFile -FileName 'MyModule.Tests.ps1'    # $true
Confirm-ValidTestFile -FileName 'MyModule.ps1'          # $false
```

### Component Usage
```powershell
# Get test directories
$testDirs = Get-TestDirectories -MaxDepth 5 -ExcludePaths @('bin')

# Find test files in directories
$testFiles = Find-TestFiles -TestDirectories $testDirs

# Or find test files in specific path
$testFiles = Find-TestFiles -Path './Tests' -Recursive
```

## 🔧 Functions

| Function | Description |
|----------|-------------|
| `Invoke-TestDiscovery` | Main discovery function with comprehensive options |
| `Get-TestDirectories` | Discovers test directories based on fixed naming conventions |
| `Find-TestFiles` | Finds test files in specified directories or paths |
| `Confirm-ValidTestDirectory` | Validates directory names against fixed conventions (`Test`/`Tests` only) |
| `Confirm-ValidTestFile` | Validates file names against fixed test patterns (`.Test.ps1`/`.Tests.ps1` only) |

### Key Changes from Generic Patterns
- **No custom pattern support**: Functions use fixed, non-configurable patterns
- **Exact matching only**: `IntegrationTests` does **not** match `Tests`
- **Enterprise-focused**: Consistent, predictable behavior across all environments

## 📤 Output Format

### Default Object Output
```powershell
@{
    DiscoveryMode = 'AutoDiscovery'          # or 'Explicit'
    TestDirectories = @(...)                 # DirectoryInfo objects
    TestFiles = @(...)                       # FileInfo objects  
    TestDirectoriesCount = 2
    TestFilesCount = 5
    DiscoveredPaths = @('Tests', 'src/Test')
    ValidationResults = @{
        HasValidDirectories = $true
        HasValidFiles = $true
        ConventionsFollowed = $true
    }
    Metadata = @{
        SearchDepth = 5
        ExcludedPaths = @('bin', 'obj')
        ValidDirectoryNames = @('Test', 'Tests')
        ValidFilePatterns = @('*.Test.ps1', '*.Tests.ps1')
        Timestamp = '2025-08-16 10:30:45'
    }
}
```

### GitHub Actions Output
When using `-OutputFormat 'GitHubActions'`, the following environment variables are set:
- `test-path-exists`: 'true' or 'false'
- `discovered-paths`: Semicolon-separated paths
- `test-files-count`: Number of discovered test files
- `test-directories-count`: Number of discovered test directories  
- `conventions-followed`: 'true' or 'false'

## 🧪 Testing

The module includes comprehensive Pester tests:

```powershell
# Run all tests
Invoke-Pester -Path './Tests/K.PSGallery.PesterTestDiscovery.Tests.ps1'

# Run with coverage
Invoke-Pester -Path './Tests/' -CodeCoverage './K.PSGallery.PesterTestDiscovery.psm1'
```

### Test Coverage
- ✅ Pattern validation functions
- ✅ Directory discovery with depth limits
- ✅ File discovery with pattern matching
- ✅ Integration scenarios
- ✅ Error handling and edge cases
- ✅ Output format validation

## ⚙️ Configuration

### Default Settings
```powershell
# Fixed test directory names (not configurable)
$ValidTestDirectoryNames = @('Test', 'Tests')

# Fixed test file patterns (not configurable)
$ValidTestFilePatterns = @('*.Test.ps1', '*.Tests.ps1')

# Default maximum search depth (configurable)
$DefaultMaxDepth = 5

# Default exclude patterns (configurable)
$DefaultExcludePaths = @('TestSetup', 'test-module', '.github', 'bin', 'obj', 'packages')
```

### Configuration Philosophy
- **Fixed Patterns**: Directory and file patterns are intentionally non-configurable for consistency
- **Configurable Behavior**: Search depth and exclude patterns remain flexible
- **Enterprise Focus**: Predictable behavior across all projects and environments

## 🔗 Integration with CI/CD

### GitHub Actions Example
```yaml
- name: Discover Tests
  shell: pwsh
  run: |
    Import-Module ./K.PSGallery.PesterTestDiscovery
    $result = Invoke-TestDiscovery -OutputFormat 'GitHubActions'
    
- name: Run Tests  
  if: env.test-files-count > 0
  shell: pwsh
  run: |
    Invoke-Pester -Path $env:discovered-paths
```

### Azure DevOps Example
```yaml
- task: PowerShell@2
  displayName: 'Discover Tests'
  inputs:
    targetType: 'inline'
    script: |
      Import-Module ./K.PSGallery.PesterTestDiscovery
      $result = Invoke-TestDiscovery -Detailed
      Write-Host "##vso[task.setvariable variable=TestFilesCount]$($result.TestFilesCount)"
```

## 🛡️ Error Handling

The module provides robust error handling with performance optimizations:

### Path Validation
- **Early Path Checks**: Non-existent paths are detected immediately without expensive operations
- **No Hanging**: Prevents infinite waits on problematic system paths (e.g., `C:\NonExistentPath`)
- **Fast Failure**: Returns empty results in ~20ms for invalid paths

### Error Recovery
- **Graceful Fallbacks**: Continues operation when directories are inaccessible
- **Detailed Logging**: Clear emoji-enhanced messages about discovery progress
- **Validation Results**: Explicit feedback about convention compliance
- **Exception Safety**: Proper error boundaries prevent cascading failures

### Performance Characteristics
- **Optimized Search**: Respects depth limits and exclude patterns
- **Path Existence Checks**: `Test-Path` validation before expensive recursive operations
- **Memory Efficient**: Streams results without loading entire directory trees
- **Fast Pattern Matching**: Efficient file pattern validation using `-like` operators

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Add tests for new functionality
4. Ensure all tests pass (`Invoke-Pester`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏷️ Versioning

This module follows [Semantic Versioning](https://semver.org/).

**Current Version: 1.0.0**
- Initial release with core discovery functionality
- Strict naming convention enforcement
- Multiple output format support
- Comprehensive test suite

## 🙏 Acknowledgments

- [Pester](https://pester.dev/) - PowerShell testing framework
- [PowerShell Community](https://github.com/PowerShell/PowerShell) - Language and ecosystem
- [GitHub Actions](https://github.com/features/actions) - CI/CD platform inspiration
