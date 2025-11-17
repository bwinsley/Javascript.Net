# Building JavaScript.Net with .NET 8

This guide provides step-by-step instructions for building JavaScript.Net after the .NET 8 migration.

## Prerequisites

### Required Software
- **Windows 10/11** (C++/CLI requires Windows)
- **Visual Studio 2022** (17.0 or later) or **Visual Studio 2019** (16.4 or later)
  - Workload: "Desktop development with C++"
  - Component: "C++/CLI support for v143 build tools (Latest)"
- **.NET 8 SDK** - [Download](https://dotnet.microsoft.com/download/dotnet/8.0)
- **Windows SDK 10.0** or later

### Visual Studio Installation

If you don't have the required components:

1. Open **Visual Studio Installer**
2. Click **Modify** on your Visual Studio installation
3. Under **Workloads**, select:
   - ✅ Desktop development with C++
4. Under **Individual components**, search and select:
   - ✅ C++/CLI support for v143 build tools (Latest)
   - ✅ Windows 10 SDK or Windows 11 SDK
5. Click **Modify** to install

## Build Steps

### Option 1: Build with Visual Studio (Recommended)

1. **Open the Solution**
   ```
   Double-click JavaScript.Net.sln
   ```

2. **Configure Build Settings**
   - Open **Configuration Manager** (Build menu → Configuration Manager)
   - Select **x64** from the "Active solution platform" dropdown
   - Select **Debug** or **Release** configuration
   - Ensure all projects are set to build

3. **Restore NuGet Packages**
   - Right-click the solution in Solution Explorer
   - Select "Restore NuGet Packages"
   - Wait for packages to restore (V8 native packages are large, ~100MB)

4. **Build the Solution**
   - Press **F6** or select **Build → Build Solution**
   - Build order:
     1. `JavaScript.Net` (C++/CLI project) - builds first
     2. `Fiddling` (C# console app) - references JavaScript.Net
     3. `Noesis.Javascript.Tests` (MSTest project) - references JavaScript.Net

5. **Verify Build Success**
   - Check the Output window for "Build succeeded"
   - Expected warnings (safe to ignore):
     - `warning LNK4248: unresolved typeref token for 'v8.internal.Object'`
     - `warning MSB3270: processor architecture mismatch` (expected for mixed-mode)

### Option 2: Build with MSBuild (Command Line)

1. **Open Developer Command Prompt for VS 2022**
   - Start Menu → Visual Studio 2022 → Developer Command Prompt

2. **Navigate to Repository**
   ```cmd
   cd path\to\Javascript.Net
   ```

3. **Restore NuGet Packages**
   ```cmd
   nuget restore JavaScript.Net.sln
   ```
   
   Or use dotnet CLI for C# projects:
   ```cmd
   dotnet restore Fiddling/Fiddling.csproj
   dotnet restore Tests/Noesis.Javascript.Tests/Noesis.Javascript.Tests.csproj
   ```

4. **Build the Solution**
   ```cmd
   msbuild JavaScript.Net.sln /p:Configuration=Release /p:Platform=x64 /t:Rebuild /v:minimal
   ```

   Or build individually:
   ```cmd
   REM Build C++/CLI wrapper
   msbuild Source/Noesis.Javascript/JavaScript.Net.vcxproj /p:Configuration=Release /p:Platform=x64

   REM Build Fiddling app
   dotnet build Fiddling/Fiddling.csproj -c Release

   REM Build tests
   dotnet build Tests/Noesis.Javascript.Tests/Noesis.Javascript.Tests.csproj -c Release
   ```

### Option 3: Build C# Projects Only (Cross-Platform)

If you only need to build the C# projects (e.g., for testing project configuration):

```bash
# On Linux/Mac/Windows
dotnet restore Fiddling/Fiddling.csproj
dotnet build Fiddling/Fiddling.csproj --no-restore

dotnet restore Tests/Noesis.Javascript.Tests/Noesis.Javascript.Tests.csproj
dotnet build Tests/Noesis.Javascript.Tests/Noesis.Javascript.Tests.csproj --no-restore
```

**Note:** These will fail during the final build stage because they reference the C++/CLI project which can only be built on Windows.

## Output Locations

After a successful build:

```
x64/
  Debug/  or  Release/
    ├── JavaScript.Net.dll        (C++/CLI wrapper)
    ├── v8.dll                    (V8 engine)
    ├── v8_libbase.dll
    ├── v8_libplatform.dll
    ├── zlib.dll
    └── icudt.dll, icuuc.dll      (Internationalization)

Fiddling/
  bin/Debug/net8.0/  or  bin/Release/net8.0/
    ├── Fiddling.exe
    ├── JavaScript.Net.dll
    └── v8*.dll, icu*.dll         (copied by post-build event)

Tests/Noesis.Javascript.Tests/
  bin/Debug/net8.0/  or  bin/Release/net8.0/
    ├── Noesis.Javascript.Tests.dll
    ├── JavaScript.Net.dll
    └── v8*.dll, icu*.dll         (copied by post-build event)
```

## Running Tests

### Option 1: Visual Studio Test Explorer

1. Open **Test Explorer** (Test menu → Test Explorer)
2. Click **Run All Tests** (or press Ctrl+R, A)
3. Tests should run and show results
4. Note: `MultipleAppDomainsTest` will be marked as **Inconclusive** (AppDomain not supported in .NET 8)

### Option 2: Command Line with dotnet test

```cmd
cd Tests\Noesis.Javascript.Tests
dotnet test -c Release --no-build
```

### Option 3: Command Line with vstest.console

```cmd
vstest.console.exe Tests\Noesis.Javascript.Tests\bin\Release\net8.0\Noesis.Javascript.Tests.dll
```

## Running the Demo Application

```cmd
cd Fiddling\bin\Release\net8.0
Fiddling.exe
```

Or from Visual Studio:
1. Right-click **Fiddling** project → Set as Startup Project
2. Press **F5** to run with debugging or **Ctrl+F5** to run without debugging

## Troubleshooting

### C++/CLI Build Errors

**Error: CLRSupport not recognized**
- Solution: Ensure you have "C++/CLI support for v143 build tools" installed in Visual Studio

**Error: Cannot find v8.dll.lib**
- Solution: Restore NuGet packages. The V8 native libraries come from NuGet packages:
  - `v8-v143-x64` version 9.8.177.4
  - `v8.redist-v143-x64` version 9.8.177.4

**Error: Target framework 'net8.0' not found**
- Solution: Install .NET 8 SDK from https://dotnet.microsoft.com/download/dotnet/8.0

### Runtime Errors

**FileNotFoundException: Could not load file or assembly 'v8.dll'**
- Solution: V8 DLLs should be copied by post-build events. Verify post-build events ran successfully.
- Manual fix: Copy DLLs from `x64/[Configuration]/` to the output directory

**FileNotFoundException: Could not load file or assembly 'JavaScript.Net.dll'**
- Solution: Ensure the C++/CLI project built successfully first
- Check that the project reference is correct

### Test Errors

**Test "ConstructionContextInTwoDifferentAppDomainTests" is Inconclusive**
- This is **expected** - `AppDomain.CreateDomain()` is not supported in .NET Core/.NET 8
- The test uses conditional compilation to return `Inconclusive` on .NET 8

**All tests fail with initialization errors**
- Solution: Ensure V8 DLLs are in the test output directory
- Rebuild the solution to trigger post-build events

## Build Verification Checklist

After building, verify:

- [ ] C++/CLI project builds without errors
- [ ] `JavaScript.Net.dll` is created in `x64/[Configuration]/`
- [ ] Fiddling project builds and references JavaScript.Net.dll
- [ ] Test project builds and references JavaScript.Net.dll
- [ ] V8 DLLs are copied to Fiddling output directory
- [ ] V8 DLLs are copied to test output directory
- [ ] Running tests shows results (MultipleAppDomainsTest = Inconclusive is OK)
- [ ] Fiddling.exe runs without errors

## Expected Build Output

A successful build should show:

```
Build started...
1>------ Build started: Project: JavaScript.Net, Configuration: Release x64 ------
1>JavaScript.Net.vcxproj -> x64\Release\JavaScript.Net.dll
2>------ Build started: Project: Fiddling, Configuration: Release Any CPU ------
2>Fiddling -> Fiddling\bin\Release\net8.0\Fiddling.dll
3>------ Build started: Project: Noesis.Javascript.Tests, Configuration: Release Any CPU ------
3>Noesis.Javascript.Tests -> Tests\Noesis.Javascript.Tests\bin\Release\net8.0\Noesis.Javascript.Tests.dll
========== Build: 3 succeeded, 0 failed, 0 up-to-date, 0 skipped ==========
```

## CI/CD Considerations

For automated builds:
- Use Windows-based build agents (Azure DevOps Windows agents, GitHub Windows runners)
- Ensure Visual Studio Build Tools 2022 with C++/CLI support installed
- Restore NuGet packages before building
- Use x64 platform configuration
- Set environment variable to suppress warnings: `set WarningLevel=3`

## Additional Resources

- [C++/CLI .NET Core Support](https://learn.microsoft.com/en-us/cpp/dotnet/dotnet-programming-with-cpp-cli-visual-cpp)
- [MSBuild Command-Line Reference](https://learn.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference)
- [.NET 8 SDK Downloads](https://dotnet.microsoft.com/download/dotnet/8.0)
