@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'K.PSGallery.PesterTestDiscovery.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-7890-1234-567890abcdef'

    # Author of this module
    Author = 'GrexyLoco'

    # Company or vendor of this module
    CompanyName = 'GrexyLoco'

    # Copyright statement for this module
    Copyright = '(c) 2025 GrexyLoco. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'PowerShell module for intelligent Pester test discovery using strict naming conventions. Supports auto-discovery with fixed folder and file patterns for reliable CI/CD integration.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Find-TestFiles',
        'Get-TestDirectories',
        'Confirm-ValidTestFile',
        'Confirm-ValidTestDirectory',
        'Invoke-TestDiscovery'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Testing', 'Pester', 'Discovery', 'CI/CD', 'DevOps', 'Automation', 'PowerShell', 'GitHub Actions')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/GrexyLoco/K.Actions.PSModuleValidation/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/GrexyLoco/K.Actions.PSModuleValidation'

            # ReleaseNotes of this module
            ReleaseNotes = @'
## Version 1.0.0
- Initial release of intelligent test discovery module
- Supports strict naming conventions for Pester tests
- Auto-discovery with configurable depth limits
- Optimized for CI/CD and GitHub Actions integration
- Comprehensive error handling and validation
'@

            # External dependent modules of this module
            ExternalModuleDependencies = @()
        }
    }

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}
