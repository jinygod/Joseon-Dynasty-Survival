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
$originalPubCache = $env:PUB_CACHE
$originalAndroidHome = $env:ANDROID_HOME
$originalAndroidSdkRoot = $env:ANDROID_SDK_ROOT
$localPropertiesPath = Join-Path $repoRoot 'android\local.properties'
$originalLocalProperties = $null
$mappedAndroidSdkProperty = $null

try {
  $isWindowsHost = $env:OS -eq 'Windows_NT'
  if ($isWindowsHost -and ($repoRoot -match '[^\x00-\x7F]' -or $flutterRoot -match '[^\x00-\x7F]')) {
    $tempRoot = Join-Path $env:SystemDrive 'codex-tmp'
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    $env:TEMP = $tempRoot
    $env:TMP = $tempRoot
    $pubCacheRoot = Join-Path $env:SystemDrive 'codex-pub-cache'
    New-Item -ItemType Directory -Force -Path $pubCacheRoot | Out-Null
    $env:PUB_CACHE = $pubCacheRoot

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

    if ($IncludeAndroid) {
      $androidSdkRoot = $env:ANDROID_HOME
      if ([string]::IsNullOrWhiteSpace($androidSdkRoot)) {
        $androidSdkRoot = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
      }
      if ((Test-Path $androidSdkRoot) -and $androidSdkRoot -match '[^\x00-\x7F]') {
        $androidDrive = Get-FreeDriveLetter -Reserved @($flutterDrive, $repoDrive)
        & subst.exe "${androidDrive}:" $androidSdkRoot
        if ($LASTEXITCODE -ne 0) { throw 'Failed to map the Android SDK path.' }
        $mappedDrives += $androidDrive
        $mappedAndroidSdk = "${androidDrive}:\"
        $env:ANDROID_HOME = $mappedAndroidSdk
        $env:ANDROID_SDK_ROOT = $mappedAndroidSdk
        $mappedAndroidSdkProperty = "sdk.dir=${androidDrive}:\\"

        if (Test-Path $localPropertiesPath) {
          $originalLocalProperties = [IO.File]::ReadAllBytes($localPropertiesPath)
          $localPropertiesText = [IO.File]::ReadAllText($localPropertiesPath)
          if ($localPropertiesText -match '(?m)^sdk\.dir=.*$') {
            $localPropertiesText = $localPropertiesText -replace '(?m)^sdk\.dir=.*$', $mappedAndroidSdkProperty
          }
          else {
            $localPropertiesText = "$mappedAndroidSdkProperty`r`n$localPropertiesText"
          }
          [IO.File]::WriteAllText(
            $localPropertiesPath,
            $localPropertiesText,
            [Text.UTF8Encoding]::new($false)
          )
        }
      }
    }
  }

  Push-Location $workingDirectory
  try {
    Invoke-Tool $flutterExecutable @('pub', 'get')
    Invoke-FormatCheck $dartExecutable
    Invoke-Tool $dartExecutable @('analyze')
    Invoke-Tool $flutterExecutable @('test', '-r', 'compact')
    Invoke-Tool $flutterExecutable @('build', 'web')
    if ($IncludeAndroid) {
      if ($null -ne $mappedAndroidSdkProperty) {
        $localPropertiesText = [IO.File]::ReadAllText($localPropertiesPath)
        $localPropertiesText = $localPropertiesText -replace '(?m)^sdk\.dir=.*$', $mappedAndroidSdkProperty
        [IO.File]::WriteAllText(
          $localPropertiesPath,
          $localPropertiesText,
          [Text.UTF8Encoding]::new($false)
        )

        $pubHostRoot = Join-Path $env:PUB_CACHE 'hosted\pub.dev'
        if (Test-Path $pubHostRoot) {
          Get-ChildItem -Path $pubHostRoot -Directory -Filter '.cxx' -Recurse |
            Where-Object { $_.FullName.StartsWith($pubHostRoot) } |
            Remove-Item -Recurse -Force
        }
      }
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
  $env:PUB_CACHE = $originalPubCache
  $env:ANDROID_HOME = $originalAndroidHome
  $env:ANDROID_SDK_ROOT = $originalAndroidSdkRoot
  if ($null -ne $originalLocalProperties) {
    [IO.File]::WriteAllBytes($localPropertiesPath, $originalLocalProperties)
  }
}
