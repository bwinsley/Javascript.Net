# Build and Test Validation Script for JavaScript.Net .NET 8 Migration
# This script validates that the project builds and tests run successfully
# Requirements: Windows, Visual Studio 2022/2019, .NET 8 SDK

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "JavaScript.Net .NET 8 Build Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"

# Check for .NET 8 SDK
Write-Host "[1/6] Checking .NET 8 SDK..." -ForegroundColor Yellow
try {
    $dotnetVersion = dotnet --version
    Write-Host "  .NET SDK version: $dotnetVersion" -ForegroundColor Green
    
    # Check if version is 8.x or higher
    $majorVersion = [int]($dotnetVersion.Split('.')[0])
    if ($majorVersion -lt 8) {
        Write-Host "  ERROR: .NET 8 SDK required, found version $dotnetVersion" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "  ERROR: .NET SDK not found. Please install .NET 8 SDK." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check for MSBuild
Write-Host "[2/6] Checking MSBuild..." -ForegroundColor Yellow
$msbuild = Get-Command msbuild -ErrorAction SilentlyContinue
if (-not $msbuild) {
    Write-Host "  ERROR: MSBuild not found." -ForegroundColor Red
    Write-Host "  Please run this from a Developer Command Prompt for Visual Studio." -ForegroundColor Red
    exit 1
}
Write-Host "  MSBuild found: $($msbuild.Source)" -ForegroundColor Green
Write-Host ""

# Restore NuGet packages
Write-Host "[3/6] Restoring NuGet packages..." -ForegroundColor Yellow
try {
    & nuget restore JavaScript.Net.sln
    if ($LASTEXITCODE -ne 0) {
        throw "NuGet restore failed"
    }
    Write-Host "  NuGet restore successful" -ForegroundColor Green
}
catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Build C++/CLI project
Write-Host "[4/6] Building C++/CLI project (JavaScript.Net)..." -ForegroundColor Yellow
try {
    & msbuild Source\Noesis.Javascript\JavaScript.Net.vcxproj /p:Configuration=Release /p:Platform=x64 /v:minimal /nologo
    if ($LASTEXITCODE -ne 0) {
        throw "C++/CLI build failed"
    }
    Write-Host "  C++/CLI build successful" -ForegroundColor Green
}
catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
    Write-Host "  Check that you have 'C++/CLI support for v143 build tools' installed in Visual Studio" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Build C# projects
Write-Host "[5/6] Building C# projects..." -ForegroundColor Yellow
try {
    & dotnet build Fiddling\Fiddling.csproj -c Release --no-restore -v:minimal
    if ($LASTEXITCODE -ne 0) {
        throw "Fiddling project build failed"
    }
    
    & dotnet build Tests\Noesis.Javascript.Tests\Noesis.Javascript.Tests.csproj -c Release --no-restore -v:minimal
    if ($LASTEXITCODE -ne 0) {
        throw "Test project build failed"
    }
    Write-Host "  C# builds successful" -ForegroundColor Green
}
catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Run tests
Write-Host "[6/6] Running tests..." -ForegroundColor Yellow
try {
    & dotnet test Tests\Noesis.Javascript.Tests\Noesis.Javascript.Tests.csproj -c Release --no-build --verbosity normal
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  WARNING: Some tests failed. Check output above." -ForegroundColor Yellow
    }
    else {
        Write-Host "  Tests completed successfully" -ForegroundColor Green
    }
}
catch {
    Write-Host "  WARNING: Test execution failed: $_" -ForegroundColor Yellow
}
Write-Host ""

# Verify output files
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verification Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Checking C++/CLI output:" -ForegroundColor Yellow
if (Test-Path "x64\Release\JavaScript.Net.dll") {
    Write-Host "  [OK] JavaScript.Net.dll found" -ForegroundColor Green
}
else {
    Write-Host "  [FAIL] JavaScript.Net.dll NOT found" -ForegroundColor Red
}

Write-Host ""
Write-Host "Checking Fiddling output:" -ForegroundColor Yellow
if (Test-Path "Fiddling\bin\Release\net8.0\Fiddling.exe") {
    Write-Host "  [OK] Fiddling.exe found" -ForegroundColor Green
}
else {
    Write-Host "  [FAIL] Fiddling.exe NOT found" -ForegroundColor Red
}
if (Test-Path "Fiddling\bin\Release\net8.0\v8.dll") {
    Write-Host "  [OK] v8.dll copied to Fiddling output" -ForegroundColor Green
}
else {
    Write-Host "  [FAIL] v8.dll NOT copied (post-build event may have failed)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Checking Test output:" -ForegroundColor Yellow
if (Test-Path "Tests\Noesis.Javascript.Tests\bin\Release\net8.0\Noesis.Javascript.Tests.dll") {
    Write-Host "  [OK] Test assembly found" -ForegroundColor Green
}
else {
    Write-Host "  [FAIL] Test assembly NOT found" -ForegroundColor Red
}
if (Test-Path "Tests\Noesis.Javascript.Tests\bin\Release\net8.0\v8.dll") {
    Write-Host "  [OK] v8.dll copied to test output" -ForegroundColor Green
}
else {
    Write-Host "  [FAIL] v8.dll NOT copied (post-build event may have failed)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Build validation complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review any failures above"
Write-Host "  2. Run Fiddling.exe to test: Fiddling\bin\Release\net8.0\Fiddling.exe"
Write-Host "  3. Check test results above"
Write-Host ""
Write-Host "For detailed documentation, see:" -ForegroundColor Yellow
Write-Host "  - BUILD_GUIDE.md"
Write-Host "  - TESTING_GUIDE.md"
Write-Host ""
