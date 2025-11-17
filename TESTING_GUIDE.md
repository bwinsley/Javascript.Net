# Testing JavaScript.Net with .NET 8

This guide explains how to run and verify the test suite for JavaScript.Net after the .NET 8 migration.

## Test Project Overview

**Project:** `Tests/Noesis.Javascript.Tests/Noesis.Javascript.Tests.csproj`
- **Framework:** .NET 8
- **Test Framework:** MSTest 3.1.1
- **Assertion Library:** FluentAssertions 6.12.0
- **Total Test Classes:** 13
- **Total Tests:** ~50+

## Test Categories

### 1. Type Conversion Tests
- `ConvertFromJavascriptTests.cs` - JavaScript → .NET conversions
- `ConvertToJavascriptTests.cs` - .NET → JavaScript conversions
- Tests cover: primitives, arrays, objects, dates, decimals, enums, nullable types

### 2. Interop Tests
- `AccessorInterceptorTests.cs` - Property and indexer access
- `JavascriptFunctionTests.cs` - Calling .NET from JavaScript and vice versa
- `IsolationTests.cs` - Context isolation

### 3. Exception Handling
- `ExceptionTests.cs` - JavaScript and .NET exception handling
- `FatalErrorHandlerTests.cs` - V8 fatal error callbacks
- `AccessToStackTraceTest.cs` - Stack trace access

### 4. Feature Tests
- `DateTest.cs` - DateTime conversions
- `FlagsTest.cs` - Enum flags handling
- `InstanceOfTest.cs` - Type checking
- `InternationalizationTests.cs` - Unicode and i18n
- `MemoryLeakTests.cs` - Memory management
- `VersionStringTests.cs` - V8 version info

### 5. .NET Framework Compatibility
- `MultipleAppDomainsTest.cs` - **Note:** Returns `Inconclusive` on .NET 8 (AppDomain.CreateDomain not supported)

## Running Tests

### Method 1: Visual Studio Test Explorer (Recommended)

1. **Open Test Explorer**
   - Menu: Test → Test Explorer
   - Or press: Ctrl+E, T

2. **Build the Solution**
   - Press F6 to build
   - Ensure all projects build successfully

3. **Run All Tests**
   - In Test Explorer, click "Run All Tests"
   - Or press: Ctrl+R, A

4. **View Results**
   - Green ✓ = Passed
   - Yellow ! = Inconclusive (expected for MultipleAppDomainsTest)
   - Red ✗ = Failed

### Method 2: dotnet test (Command Line)

```cmd
# From repository root
cd Tests\Noesis.Javascript.Tests

# Run all tests
dotnet test

# Run with detailed output
dotnet test --verbosity normal

# Run specific configuration
dotnet test -c Release

# Run and collect code coverage
dotnet test --collect:"XPlat Code Coverage"
```

### Method 3: vstest.console.exe

```cmd
# From repository root
vstest.console.exe Tests\Noesis.Javascript.Tests\bin\Release\net8.0\Noesis.Javascript.Tests.dll

# With detailed logging
vstest.console.exe Tests\Noesis.Javascript.Tests\bin\Release\net8.0\Noesis.Javascript.Tests.dll /logger:trx

# Run specific tests
vstest.console.exe Tests\Noesis.Javascript.Tests\bin\Release\net8.0\Noesis.Javascript.Tests.dll /Tests:ConvertFromJavascriptTests
```

## Expected Test Results

### .NET 8 Expected Behavior

```
Total tests: ~50
  Passed: ~49
  Inconclusive: 1 (MultipleAppDomainsTest)
  Failed: 0
  Skipped: 0
```

**Note:** One test is expected to be **Inconclusive**:
- `MultipleAppDomainsTest.ConstructionContextInTwoDifferentAppDomainTests`
- Reason: `AppDomain.CreateDomain()` is not supported in .NET Core/.NET 8
- The test uses conditional compilation and returns `Assert.Inconclusive()`

### Sample Test Output

```
Starting test execution, please wait...
A total of 50 test files matched the specified pattern.

Passed!  - Failed:     0, Passed:    49, Skipped:     0, Total:    50, Duration: 2.3s
```

## Test Requirements

### Runtime Requirements
- ✅ .NET 8 Runtime
- ✅ V8 native libraries (v8.dll, v8_libbase.dll, v8_libplatform.dll)
- ✅ V8 ICU libraries (icudt.dll, icuuc.dll)
- ✅ zlib.dll

### Build-Time Dependencies
All automatically restored via NuGet:
- Microsoft.NET.Test.Sdk 17.8.0
- MSTest.TestFramework 3.1.1
- MSTest.TestAdapter 3.1.1
- FluentAssertions 6.12.0

## Troubleshooting Tests

### All Tests Fail on Initialization

**Symptom:**
```
Test method threw exception:
System.IO.FileNotFoundException: Could not load file or assembly 'v8.dll'
```

**Solution:**
1. Rebuild the solution to trigger post-build events
2. Verify V8 DLLs exist in test output directory:
   ```
   Tests\Noesis.Javascript.Tests\bin\[Configuration]\net8.0\
     ├── v8.dll
     ├── v8_libbase.dll
     ├── v8_libplatform.dll
     ├── zlib.dll
     ├── icudt.dll
     └── icuuc.dll
   ```
3. If missing, manually copy from `x64\[Configuration]\` directory

### JavaScript.Net.dll Not Found

**Symptom:**
```
Could not load file or assembly 'JavaScript.Net, Version=...'
```

**Solution:**
1. Build the C++/CLI project first: `msbuild Source/Noesis.Javascript/JavaScript.Net.vcxproj`
2. Ensure project reference is correct in test .csproj
3. Rebuild the test project

### Tests Pass but One is Inconclusive

**Symptom:**
```
Test Name: ConstructionContextInTwoDifferentAppDomainTests
Result: Inconclusive
Message: AppDomain.CreateDomain is not supported in .NET Core/.NET 8
```

**Solution:** This is **expected behavior** on .NET 8. No action needed.

### Specific Test Fails

1. **Run the test individually:**
   ```cmd
   dotnet test --filter "FullyQualifiedName~TestName"
   ```

2. **Check test output for details:**
   - Visual Studio: Double-click failed test in Test Explorer
   - Command line: Add `--logger "console;verbosity=detailed"`

3. **Common issues:**
   - JavaScript syntax errors → Check test script
   - Type conversion issues → Verify V8 version compatibility
   - Memory leaks → Run test in isolation

## Verifying Test Coverage

### Run All Test Classes

```cmd
# Test type conversions
dotnet test --filter "ClassName~ConvertFromJavascriptTests"
dotnet test --filter "ClassName~ConvertToJavascriptTests"

# Test interop
dotnet test --filter "ClassName~AccessorInterceptorTests"
dotnet test --filter "ClassName~JavascriptFunctionTests"

# Test exception handling
dotnet test --filter "ClassName~ExceptionTests"
dotnet test --filter "ClassName~FatalErrorHandlerTests"

# Test features
dotnet test --filter "ClassName~DateTest"
dotnet test --filter "ClassName~InternationalizationTests"
dotnet test --filter "ClassName~MemoryLeakTests"
```

## Adding New Tests

When adding tests for .NET 8 compatibility:

1. **Use .NET 8 compatible APIs only**
   - Avoid .NET Framework-specific types (AppDomain, Remoting)
   - Use modern .NET patterns

2. **Follow existing test structure:**
   ```csharp
   [TestClass]
   public class MyNewTests
   {
       private JavascriptContext _context;

       [TestInitialize]
       public void SetUp()
       {
           _context = new JavascriptContext();
       }

       [TestCleanup]
       public void TearDown()
       {
           _context?.Dispose();
       }

       [TestMethod]
       public void MyTest()
       {
           // Arrange
           _context.SetParameter("value", 42);

           // Act
           var result = _context.Run("value * 2");

           // Assert
           result.Should().Be(84);
       }
   }
   ```

3. **Use FluentAssertions for readability:**
   ```csharp
   result.Should().Be(expected);
   result.Should().BeOfType<int>();
   action.Should().Throw<JavascriptException>();
   ```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup .NET 8
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: '8.0.x'
    
    - name: Setup MSBuild
      uses: microsoft/setup-msbuild@v1
    
    - name: Restore NuGet packages
      run: nuget restore JavaScript.Net.sln
    
    - name: Build
      run: msbuild JavaScript.Net.sln /p:Configuration=Release /p:Platform=x64
    
    - name: Test
      run: dotnet test Tests/Noesis.Javascript.Tests/Noesis.Javascript.Tests.csproj -c Release --no-build --verbosity normal
```

### Azure DevOps Pipeline Example

```yaml
trigger:
- master

pool:
  vmImage: 'windows-latest'

steps:
- task: UseDotNet@2
  inputs:
    version: '8.0.x'

- task: NuGetCommand@2
  inputs:
    command: 'restore'
    restoreSolution: 'JavaScript.Net.sln'

- task: MSBuild@1
  inputs:
    solution: 'JavaScript.Net.sln'
    platform: 'x64'
    configuration: 'Release'

- task: DotNetCoreCLI@2
  inputs:
    command: 'test'
    projects: 'Tests/Noesis.Javascript.Tests/Noesis.Javascript.Tests.csproj'
    arguments: '--configuration Release --no-build'
```

## Test Maintenance Notes

### Post-.NET 8 Migration Changes

1. **MultipleAppDomainsTest:**
   - Added conditional compilation (`#if NETFRAMEWORK`)
   - Returns `Inconclusive` on .NET 8
   - Keep for potential .NET Framework multi-targeting

2. **Package References:**
   - Updated to .NET 8 compatible versions
   - Using PackageReference (modern format)
   - Auto-restored by .NET SDK

3. **Test SDK:**
   - Using Microsoft.NET.Test.Sdk 17.8.0
   - Enables `dotnet test` support
   - Compatible with Visual Studio Test Explorer

## Success Criteria

Tests are passing if:
- ✅ 49+ tests pass
- ✅ 1 test is inconclusive (MultipleAppDomainsTest)
- ✅ 0 tests fail
- ✅ No initialization errors
- ✅ All test categories covered
- ✅ JavaScript execution works
- ✅ Type conversions work
- ✅ Exception handling works
- ✅ Memory management works
