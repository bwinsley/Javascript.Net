@echo off
REM Build and Test Validation Script for JavaScript.Net .NET 8 Migration
REM This script validates that the project builds and tests run successfully
REM Requirements: Windows, Visual Studio 2022/2019, .NET 8 SDK

echo ========================================
echo JavaScript.Net .NET 8 Build Validation
echo ========================================
echo.

REM Check for .NET 8 SDK
echo [1/6] Checking .NET 8 SDK...
dotnet --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: .NET SDK not found. Please install .NET 8 SDK.
    exit /b 1
)
dotnet --version
echo.

REM Check for MSBuild
echo [2/6] Checking MSBuild...
where msbuild >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: MSBuild not found. Please run this from a Developer Command Prompt for Visual Studio.
    exit /b 1
)
echo MSBuild found
echo.

REM Restore NuGet packages
echo [3/6] Restoring NuGet packages...
nuget restore JavaScript.Net.sln
if %errorlevel% neq 0 (
    echo ERROR: NuGet restore failed
    exit /b 1
)
echo NuGet restore successful
echo.

REM Build C++/CLI project
echo [4/6] Building C++/CLI project (JavaScript.Net)...
msbuild Source\Noesis.Javascript\JavaScript.Net.vcxproj /p:Configuration=Release /p:Platform=x64 /v:minimal
if %errorlevel% neq 0 (
    echo ERROR: C++/CLI project build failed
    echo Check that you have "C++/CLI support for v143 build tools" installed in Visual Studio
    exit /b 1
)
echo C++/CLI build successful
echo.

REM Build C# projects
echo [5/6] Building C# projects...
dotnet build Fiddling\Fiddling.csproj -c Release --no-restore
if %errorlevel% neq 0 (
    echo ERROR: Fiddling project build failed
    exit /b 1
)

dotnet build Tests\Noesis.Javascript.Tests\Noesis.Javascript.Tests.csproj -c Release --no-restore
if %errorlevel% neq 0 (
    echo ERROR: Test project build failed
    exit /b 1
)
echo C# builds successful
echo.

REM Run tests
echo [6/6] Running tests...
dotnet test Tests\Noesis.Javascript.Tests\Noesis.Javascript.Tests.csproj -c Release --no-build --verbosity normal
if %errorlevel% neq 0 (
    echo WARNING: Some tests failed. Check output above.
) else (
    echo Tests completed successfully
)
echo.

REM Verify output files
echo ========================================
echo Verification Summary
echo ========================================
echo.

echo Checking C++/CLI output:
if exist "x64\Release\JavaScript.Net.dll" (
    echo   [OK] JavaScript.Net.dll found
) else (
    echo   [FAIL] JavaScript.Net.dll NOT found
)

echo.
echo Checking Fiddling output:
if exist "Fiddling\bin\Release\net8.0\Fiddling.exe" (
    echo   [OK] Fiddling.exe found
) else (
    echo   [FAIL] Fiddling.exe NOT found
)
if exist "Fiddling\bin\Release\net8.0\v8.dll" (
    echo   [OK] v8.dll copied to Fiddling output
) else (
    echo   [FAIL] v8.dll NOT copied (post-build event may have failed)
)

echo.
echo Checking Test output:
if exist "Tests\Noesis.Javascript.Tests\bin\Release\net8.0\Noesis.Javascript.Tests.dll" (
    echo   [OK] Test assembly found
) else (
    echo   [FAIL] Test assembly NOT found
)
if exist "Tests\Noesis.Javascript.Tests\bin\Release\net8.0\v8.dll" (
    echo   [OK] v8.dll copied to test output
) else (
    echo   [FAIL] v8.dll NOT copied (post-build event may have failed)
)

echo.
echo ========================================
echo Build validation complete!
echo ========================================
echo.
echo Next steps:
echo   1. Review any failures above
echo   2. Run Fiddling.exe to test: Fiddling\bin\Release\net8.0\Fiddling.exe
echo   3. Check test results above
echo.
echo For detailed documentation, see:
echo   - BUILD_GUIDE.md
echo   - TESTING_GUIDE.md
echo.
