param(
  [switch]$IncludeAndroid
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Invoke-Tool {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Executable,
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  Write-Host "`n> $Executable $($Arguments -join ' ')" -ForegroundColor Cyan
  & $Executable @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: $Executable"
  }
}

function Get-FreeDriveLetter {
  param([string[]]$Reserved)

  $used = @(Get-PSDrive -PSProvider FileSystem | ForEach-Object { $_.Name })
  foreach ($letter in [char[]](90..68)) {
    $candidate = [string]$letter
    if ($candidate -notin $used -and $candidate -notin $Reserved) {
      return $candidate
    }
  }
  throw 'No free drive letter is available for the ASCII path workaround.'
}

function Invoke-FormatCheck {
  param(
    [Parameter(Mandatory = $true)]
    [string]$DartExecutable
  )

  Write-Host "`n> $DartExecutable format --output=none --set-exit-if-changed lib test" -ForegroundColor Cyan
  & $DartExecutable format --output=none --set-exit-if-changed lib test
  if ($LASTEXITCODE -eq 0) {
    return
  }

  # Dart can report CRLF-to-LF normalization as a formatting change on Windows
  # even when Git's normalized content is unchanged. Only fail for a real diff.
  & git diff --quiet -- lib test
  if ($LASTEXITCODE -ne 0) {
    throw 'Dart formatting changed tracked source files. Review and rerun the gate.'
  }
  Write-Host 'Only normalized line endings changed; continuing.' -ForegroundColor DarkYellow
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if ($null -eq $flutterCommand) {
  $defaultFlutter = Join-Path $env:USERPROFILE 'source\flutter\bin\flutter.bat'
  if (-not (Test-Path $defaultFlutter)) {
    throw 'Flutter was not found on PATH or at %USERPROFILE%\source\flutter.'
  }
  $flutterCommand = Get-Command $defaultFlutter
}

$flutterRoot = Split-Path (Split-Path $flutterCommand.Source -Parent) -Parent
$flutterExecutable = $flutterCommand.Source
$dartExecutable = Join-Path $flutterRoot 'bin\dart.bat'
$workingDirectory = $repoRoot
$mappedDrives = @()
$originalTemp = $env:TEMP
$originalTmp = $env:TMP

try {
  $isWindowsHost = $env:OS -eq 'Windows_NT'
  if ($isWindowsHost -and ($repoRoot -match '[^\x00-\x7F]' -or $flutterRoot -match '[^\x00-\x7F]')) {
    $tempRoot = Join-Path $env:SystemDrive 'codex-tmp'
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    $env:TEMP = $tempRoot
    $env:TMP = $tempRoot

    $flutterDrive = Get-FreeDriveLetter -Reserved @()
    $repoDrive = Get-FreeDriveLetter -Reserved @($flutterDrive)

    & subst.exe "${flutterDrive}:" $flutterRoot
    if ($LASTEXITCODE -ne 0) { throw 'Failed to map the Flutter SDK path.' }
    $mappedDrives += $flutterDrive

    & subst.exe "${repoDrive}:" $repoRoot
    if ($LASTEXITCODE -ne 0) { throw 'Failed to map the repository path.' }
    $mappedDrives += $repoDrive

    $flutterExecutable = "${flutterDrive}:\bin\flutter.bat"
    $dartExecutable = "${flutterDrive}:\bin\dart.bat"
    $workingDirectory = "${repoDrive}:\"
  }

  Push-Location $workingDirectory
  try {
    Invoke-Tool $flutterExecutable @('pub', 'get')
    Invoke-FormatCheck $dartExecutable
    Invoke-Tool $dartExecutable @('analyze')
    Invoke-Tool $flutterExecutable @('test', '-r', 'compact')
    Invoke-Tool $flutterExecutable @('build', 'web')
    if ($IncludeAndroid) {
      Invoke-Tool $flutterExecutable @('build', 'apk', '--debug')
    }
  }
  finally {
    Pop-Location
  }

  Write-Host "`nRelease checks passed." -ForegroundColor Green
}
finally {
  foreach ($drive in $mappedDrives) {
    & subst.exe "${drive}:" /D 2>$null
  }
  $env:TEMP = $originalTemp
  $env:TMP = $originalTmp
}
