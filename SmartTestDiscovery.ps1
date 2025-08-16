# SmartTestDiscovery.ps1
# Auto-discovers Pester tests using strict conventions
# - Testordner muss "Test" oder "Tests" heißen (beliebig tief, max 5 Level)
# - Testdateien müssen mit ".Tests.ps1" oder ".Test.ps1" enden
# Gibt Warnung aus, wenn Testordner existiert aber keine passenden Dateien gefunden werden

param(
    [string]$TestPath = '',
    [string]$OutputVarPrefix = ''
)

Write-Host "🔍 Smart test discovery using naming conventions..." -ForegroundColor Cyan
$discoveredPaths = @()
$testFiles = @()

if ($TestPath -and $TestPath.Trim() -ne '') {
    Write-Host "📂 Test path specified: $TestPath" -ForegroundColor Yellow
    if (Test-Path $TestPath) {
        $testFiles = Get-ChildItem -Path $TestPath -Filter "*.Tests.ps1" -Recurse -File
        $testFiles += Get-ChildItem -Path $TestPath -Filter "*.Test.ps1" -Recurse -File
        Write-Host "✅ Found $($testFiles.Count) test files in specified path" -ForegroundColor Green
        $discoveredPaths += $TestPath
    } else {
        Write-Host "⚠️ Specified test path does not exist: $TestPath" -ForegroundColor Yellow
    }
} else {
    Write-Host "🔍 Auto-discovering tests using naming conventions..." -ForegroundColor Yellow
    Write-Host "📋 Convention: Folders named 'Test' or 'Tests' containing '*.Test.ps1' or '*.Tests.ps1'" -ForegroundColor Cyan
    $testDirectories = Get-ChildItem -Path "." -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object {
        ($_.Name -eq "Test" -or $_.Name -eq "Tests") -and
        (($_.FullName.Split([IO.Path]::DirectorySeparatorChar).Count - (Get-Location).Path.Split([IO.Path]::DirectorySeparatorChar).Count) -le 5)
    }
    Write-Host "🔍 Found $($testDirectories.Count) test directories matching convention" -ForegroundColor Cyan
    if ($testDirectories.Count -gt 0) {
        foreach ($testDir in $testDirectories) {
            Write-Host "📁 Scanning: $($testDir.FullName)" -ForegroundColor Gray
            $dirTestFiles = @()
            $dirTestFiles += Get-ChildItem -Path $testDir.FullName -Filter "*.Tests.ps1" -Recurse -File -ErrorAction SilentlyContinue
            $dirTestFiles += Get-ChildItem -Path $testDir.FullName -Filter "*.Test.ps1" -Recurse -File -ErrorAction SilentlyContinue
            if ($dirTestFiles.Count -gt 0) {
                Write-Host "   ✅ Found $($dirTestFiles.Count) test files" -ForegroundColor Green
                $discoveredPaths += $testDir.FullName
                $testFiles += $dirTestFiles
            } else {
                Write-Host "   ⚠️ Test directory found but no test files matching convention" -ForegroundColor Yellow
                Write-Host "   💡 Expected: *.Test.ps1 or *.Tests.ps1 files" -ForegroundColor Yellow
                Write-Host "   📖 See documentation for Pester test naming conventions" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "📂 No test directories found matching naming convention" -ForegroundColor Yellow
        Write-Host "💡 Create a 'Tests' or 'Test' directory with '*.Tests.ps1' files" -ForegroundColor Cyan
    }
}

# Outputs for GitHub Actions
$pathsString = $discoveredPaths -join ';'
$testPathExists = if ($testFiles.Count -gt 0) { 'true' } else { 'false' }
$testFilesCount = $testFiles.Count

Write-Host "🔍 Auto-discovery complete:" -ForegroundColor Green
Write-Host "   📁 Test directories: $($discoveredPaths.Count)" -ForegroundColor Green
Write-Host "   📄 Test files found: $testFilesCount" -ForegroundColor Green

# Set outputs for composite action
Write-Output "test-path-exists=$testPathExists" >> $env:GITHUB_OUTPUT
Write-Output "discovered-paths=$pathsString" >> $env:GITHUB_OUTPUT
Write-Output "test-files-count=$testFilesCount" >> $env:GITHUB_OUTPUT

# List found test files
if ($testFilesCount -gt 0) {
    Write-Host "📋 Discovered test files:" -ForegroundColor Green
    foreach ($file in $testFiles) {
        Write-Host "   ✅ $($file.FullName)" -ForegroundColor Gray
    }
} else {
    Write-Host "⚠️ No test files found matching conventions" -ForegroundColor Yellow
    Write-Host "📖 Convention: 'Test'/'Tests' directories containing '*.Test.ps1'/'*.Tests.ps1'" -ForegroundColor Cyan
}
