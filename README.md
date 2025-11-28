# K.Actions.PSModuleValidation

<!-- AUTO-GENERATED BADGES - DO NOT EDIT MANUALLY -->
## 📊 Status

![Quality Gate](https://img.shields.io/badge/Quality_Gate-passing-brightgreen?logo=githubactions) ![Release](https://img.shields.io/badge/Release-v1.7.0-blue?logo=github) [![CI](https://github.com/GrexyLoco/K.Actions.PSModuleValidation/actions/workflows/release.yml/badge.svg)](https://github.com/GrexyLoco/K.Actions.PSModuleValidation/actions/workflows/release.yml)

> 🕐 **Last Updated:** 2025-11-28 00:31:26 UTC | **Action:** `K.Actions.PSModuleValidation`
<!-- END AUTO-GENERATED BADGES -->

[![GitHub](https://img.shields.io/badge/GitHub-Actions-blue?logo=github)](https://github.com/GrexyLoco/K.Actions.PSModuleValidation)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)](https://docs.microsoft.com/en-us/powershell/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

<!-- AUTO-GENERATED BADGES - DO NOT EDIT MANUALLY -->
## 📊 Status

![Quality Gate](https://img.shields.io/badge/Quality_Gate-pending-lightgrey?logo=githubactions) ![Release](https://img.shields.io/badge/Release-none-lightgrey?logo=github) [![CI](https://github.com/GrexyLoco/K.Actions.PSModuleValidation/actions/workflows/release.yml/badge.svg)](https://github.com/GrexyLoco/K.Actions.PSModuleValidation/actions/workflows/release.yml)

> 🕐 **Last Updated:** Pending first pipeline run | **Action:** `K.Actions.PSModuleValidation`
<!-- END AUTO-GENERATED BADGES -->

Comprehensive validation action for PowerShell modules featuring security scans, code quality analysis, and automated testing with enterprise-grade reporting.

## 🚀 Features

- **🛡️ Security Scanning**: GitLeaks for secret detection
- **📝 Code Quality**: Super-Linter with PSScriptAnalyzer, JSCPD, and more
- **🧪 Automated Testing**: Pester v5 with code coverage
- **📊 Rich Reporting**: Detailed GitHub summaries with metrics 
- **⚡ High Performance**: Optimized for CI/CD pipelines
- **🔧 Configurable**: Flexible inputs for various project needs

## 📋 Usage

### Basic Usage

```yaml
name: PowerShell Module Validation

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Validate PowerShell Module
        uses: GrexyLoco/K.Actions.PSModuleValidation@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          module-name: 'MyModule'
```

### Advanced Configuration

```yaml
      - name: Validate PowerShell Module
        uses: GrexyLoco/K.Actions.PSModuleValidation@v1
        with:
          test-path: './Tests'
          output-path: './TestResults.xml'
          validate-all-codebase: 'true'
          github-token: ${{ secrets.GITHUB_TOKEN }}
          module-name: 'MyAdvancedModule'
          pester-configuration: |
            {
              "Run": {
                "Path": "./Tests",
                "PassThru": true
              },
              "Output": {
                "Verbosity": "Detailed"
              },
              "TestResult": {
                "Enabled": true,
                "OutputPath": "./TestResults.xml",
                "OutputFormat": "NUnitXml"
              },
              "CodeCoverage": {
                "Enabled": true,
                "OutputFormat": "JaCoCo",
                "Path": ["*.ps1", "*.psm1"],
                "Threshold": 80
              }
            }
```

## 🔧 Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `test-path` | Path to the test directory containing Pester tests. If empty, auto-discovery will search for test files up to 5 levels deep. | No | `''` (auto-discovery) |
| `output-path` | Path for test results XML output | No | `./TestResults.xml` |
| `validate-all-codebase` | Whether to validate all codebase or only changed files | No | `false` |
| `github-token` | GitHub token for Super-Linter | **Yes** | - |
| `pester-configuration` | Custom Pester configuration (JSON format) | No | Default config |
| `module-name` | Name of the PowerShell module (for reporting) | No | `PowerShell Module` |

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `test-success` | Whether all tests passed successfully |
| `total-tests` | Total number of tests executed |
| `passed-tests` | Number of tests that passed |
| `failed-tests` | Number of tests that failed |
| `skipped-tests` | Number of tests that were skipped |
| `test-duration` | Total test execution duration (seconds) |
| `test-results-path` | Path to the test results XML file |
| `coverage-percentage` | Code coverage percentage |

## 🛡️ Security Features

### GitLeaks Integration
- **Secret Detection**: Scans for exposed API keys, credentials, and sensitive data
- **Pattern Matching**: 100+ built-in patterns for common secrets
- **Zero False Positives**: Tuned for PowerShell module development

### Security Patterns Detected
- 🔑 API Keys (AWS, Google, GitHub, Azure, etc.)
- 🔐 Private Keys (RSA, SSH, PGP)
- 📧 Email addresses in code
- 🌐 URLs with embedded credentials
- 💳 Credit card numbers
- 🗄️ Database connection strings

## 📊 Quality Gates

### Super-Linter Integration
- **PowerShell**: PSScriptAnalyzer with best practices
- **JSCPD**: Copy-paste detection and code duplication analysis
- **Markdown**: Documentation formatting validation
- **YAML/JSON**: Configuration file validation

### Code Quality Standards
- ✅ PowerShell best practices (PSScriptAnalyzer)
- ✅ Code formatting consistency
- ✅ Documentation standards
- ✅ Configuration file integrity
- ✅ Duplication detection (JSCPD)

## 🧪 Testing Framework

### Pester v5 Integration
- **Modern Testing**: Latest Pester framework with enhanced features
- **Code Coverage**: Built-in coverage analysis with configurable thresholds
- **Flexible Configuration**: JSON-based configuration support
- **Artifact Upload**: Test results automatically uploaded as artifacts

### 🔍 Smart Test Discovery
- **Auto-Discovery**: If no test path is specified, the action will recursively search up to 5 levels deep for folders named `Test` or `Tests`.
- **Strict File Pattern**: Only files ending with `.Test.ps1` or `.Tests.ps1` inside these folders are considered valid Pester tests.
- **Warning for Missing Tests**: If a test folder exists but no valid test files are found, a warning is issued (not an error).
- **Error Only When**: Tests exist but fail to pass.

#### Example Test Discovery Convention
```text
YourModule/
├── Tests/
│   ├── MyFeature.Tests.ps1
│   └── AnotherFeature.Test.ps1
└── ...
```

### Test Reporting
- 📊 Comprehensive test metrics
- 📈 Code coverage analysis
- ⚡ Performance monitoring
- 🎯 Quality gate validation
- ⚠️ Warning for missing tests (not error)

## 📋 Requirements

- **GitHub Actions Runner**: Ubuntu Latest (recommended)
- **PowerShell**: 5.1+ (automatically available on Ubuntu runners)
- **Pester**: v5.0+ (automatically installed if missing)
- **Test Structure**: Tests should be in a dedicated directory

## 🏗️ Project Structure

Your PowerShell module should follow this structure:

```text
YourModule/
├── YourModule.psd1          # Module manifest
├── YourModule.psm1          # Module file
├── Tests/                   # Test directory
│   ├── YourModule.Tests.ps1 # Pester tests
│   └── ...
├── .github/
│   └── workflows/
│       └── validate.yml     # This action
└── README.md
```

## 🔗 Integration Examples

### Using Outputs in Subsequent Steps

```yaml
      - name: Validate Module
        id: validate
        uses: GrexyLoco/K.Actions.PSModuleValidation@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          module-name: 'MyModule'

      - name: Check Results
        if: always()
        run: |
          echo "Tests passed: ${{ steps.validate.outputs.test-success }}"
          echo "Total tests: ${{ steps.validate.outputs.total-tests }}"
          echo "Coverage: ${{ steps.validate.outputs.coverage-percentage }}%"
          echo "Duration: ${{ steps.validate.outputs.test-duration }}s"
```

### Conditional Deployment

```yaml
      - name: Deploy to PowerShell Gallery
        if: steps.validate.outputs.test-success == 'true' && steps.validate.outputs.coverage-percentage >= '80'
        run: |
          # Deployment logic here
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏷️ Versioning

This action follows [Semantic Versioning](https://semver.org/) with **automated releases** using [K.Actions.NextActionVersion](https://github.com/GrexyLoco/K.Actions.NextActionVersion).

### Release Automation
- **Conventional Commits**: Use `feat:`, `fix:`, `BREAKING CHANGE:` for automatic version bumps
- **Git Tag-Based**: Versions are calculated from Git history, not manifest files  
- **Smart Detection**: Only creates releases when changes warrant a version bump
- **Branch Patterns**: `feature/` → minor, `bugfix/` → patch, `major/` → major

### Available Versions
See the [releases page](https://github.com/GrexyLoco/K.Actions.PSModuleValidation/releases) for all versions, or reference the [tags](https://github.com/GrexyLoco/K.Actions.PSModuleValidation/tags).

## 🐛 Issues & Support

- **Bug Reports**: [GitHub Issues](https://github.com/GrexyLoco/K.Actions.PSModuleValidation/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/GrexyLoco/K.Actions.PSModuleValidation/discussions)
- **Documentation**: This README and inline code comments

## 🙏 Acknowledgments

- [Pester](https://pester.dev/) - PowerShell testing framework
- [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) - PowerShell code analysis
- [GitLeaks](https://github.com/zricethezav/gitleaks) - Secret detection
- [Super-Linter](https://github.com/github/super-linter) - Multi-language linter
