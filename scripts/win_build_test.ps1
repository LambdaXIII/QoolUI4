<#
.SYNOPSIS
    QoolUI one-shot Windows (MSVC): configure + build + run tests.

.DESCRIPTION
    WINDOWS/MSVC ONLY - do not use on other platforms.
    Other platforms: use CMakePresets directly (cmake --preset dev) or the
    native flow described in QoolUITests/README.md (platform notes section).

    Steps:
      1. Locate Visual Studio via vswhere
      2. Load the MSVC environment from vcvars64.bat into this process
      3. Configure via Qt's qt-cmake wrapper with the "dev" preset
      4. Build via the "dev" preset
      5. Run all tests via the aggregated "run-tests" target

    Requirements:
      - Visual Studio (Community/Professional/BuildTools)
      - Ninja on PATH
      - Qt msvc kit: default C:\Qt\6.11.1\msvc2022_64, override via QT_DIR

.EXAMPLE
    pwsh -File scripts/win_build_test.ps1
    pwsh -File scripts/win_build_test.ps1 -TestOnly
#>
param(
    [switch]$TestOnly
)

$ErrorActionPreference = 'Stop'

# ---- locate Visual Studio via vswhere ----
$vswhere = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path $vswhere)) {
    throw "vswhere not found: $vswhere"
}
$vsDir = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vsDir) {
    throw 'Visual Studio with C++ tools not found'
}

# ---- load MSVC environment from vcvars64.bat into this process ----
# Standard pattern: let cmd print "VAR=value" lines, then import them.
$vcvars = Join-Path $vsDir 'VC\Auxiliary\Build\vcvars64.bat'
if (-not (Test-Path $vcvars)) {
    throw "vcvars64.bat not found: $vcvars"
}
$envLines = cmd /c "`"$vcvars`" && set"
foreach ($line in $envLines) {
    $eq = $line.IndexOf('=')
    if ($eq -gt 0) {
        $name = $line.Substring(0, $eq)
        $value = $line.Substring($eq + 1).TrimEnd("`r")
        Set-Item -Path "Env:$name" -Value $value
    }
}

# ---- Qt msvc kit (override via QT_DIR) ----
$qtDir = if ($env:QT_DIR) { $env:QT_DIR } else { 'C:\Qt\6.11.1\msvc2022_64' }
if (-not (Test-Path "$qtDir\bin\qt-cmake.bat")) {
    throw "Qt msvc kit not found at: $qtDir"
}

if (-not $TestOnly) {
    Write-Host '=== [1/3] configure ==='
    & "$qtDir\bin\qt-cmake.bat" --preset dev
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Host '=== [2/3] build ==='
    cmake --build --preset dev
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host '=== [3/3] test ==='
cmake --build --preset dev --target run-tests
exit $LASTEXITCODE
