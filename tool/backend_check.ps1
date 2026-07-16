param(
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-Gate {
  param([Parameter(Mandatory = $true)][string]$Text)
  Write-Host "`n> $Text" -ForegroundColor Cyan
}

function Invoke-Tool {
  param(
    [Parameter(Mandatory = $true)][string]$Executable,
    [Parameter(Mandatory = $true)][string[]]$Arguments
  )

  Write-Gate "$Executable $($Arguments -join ' ')"
  & $Executable @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Gate failed with exit code ${LASTEXITCODE}: $Executable $($Arguments -join ' ')"
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
  param([Parameter(Mandatory = $true)][string]$DartExecutable)

  Write-Gate "$DartExecutable format --output=none --set-exit-if-changed lib test"
  & $DartExecutable format --output=none --set-exit-if-changed lib test
  if ($LASTEXITCODE -eq 0) {
    return
  }

  # On Windows, Dart can report only CRLF/LF normalization. A tracked content
  # diff is still a hard failure; a clean Git diff is safe to continue.
  & git diff --quiet -- lib test
  if ($LASTEXITCODE -ne 0) {
    throw 'Dart formatting changed tracked source files. Review and rerun.'
  }
  Write-Host 'Only normalized line endings changed; continuing.' -ForegroundColor DarkYellow
}

function Assert-DockerAvailable {
  $dockerCommand = Get-Command docker -ErrorAction SilentlyContinue
  if ($null -eq $dockerCommand) {
    throw 'BLOCKED: Docker is required for Supabase database tests and lint, but docker was not found.'
  }

  Write-Gate 'docker info --format {{.ServerVersion}}'
  & $dockerCommand.Source info --format '{{.ServerVersion}}'
  if ($LASTEXITCODE -ne 0) {
    throw 'BLOCKED: Docker is installed but its daemon is unavailable. Supabase database gates were not run.'
  }
}

function Ensure-LocalSupabaseDatabase {
  param([Parameter(Mandatory = $true)][string]$NpxExecutable)

  $previousErrorActionPreference = $ErrorActionPreference
  try {
    # Windows PowerShell can promote a native command's stderr to a terminating
    # NativeCommandError while ErrorActionPreference is Stop. A stopped local
    # stack is an expected probe result, so inspect the exit code explicitly.
    $ErrorActionPreference = 'Continue'
    & $NpxExecutable @('supabase', 'status', '--output', 'json') *> $null
    $statusExitCode = $LASTEXITCODE
  }
  finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }

  if ($statusExitCode -eq 0) {
    return
  }

  $excludedServices = 'analytics,edge-runtime,functions,imgproxy,inbucket,kong,meta,realtime,rest,storage,studio,vector'
  try {
    Invoke-Tool $NpxExecutable @(
      'supabase', 'start', '--exclude', $excludedServices, '--yes'
    )
  }
  catch {
    throw "BLOCKED: Docker is available but the local Supabase database could not start. $($_.Exception.Message)"
  }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

if ($DryRun) {
  Write-Host 'Backend gate dry run; no command will execute.' -ForegroundColor Yellow
  @(
    'dart format --output=none --set-exit-if-changed lib test',
    'dart analyze',
    'flutter test -r compact',
    'deno fmt --check supabase/functions',
    'deno lint supabase/functions',
    'deno test supabase/functions/tests',
    'deno check five Edge Function entrypoints',
    'docker info (BLOCKED with non-zero exit when unavailable)',
    'supabase db reset --local',
    'supabase test db',
    'supabase db lint --local --level warning --fail-on warning',
    'flutter build web',
    'flutter build apk --debug'
  ) | ForEach-Object { Write-Host "[DRY-RUN] $_" }
  exit 0
}

$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if ($null -eq $flutterCommand) {
  $defaultFlutter = Join-Path $env:USERPROFILE 'source\flutter\bin\flutter.bat'
  if (-not (Test-Path $defaultFlutter)) {
    throw 'BLOCKED: Flutter was not found on PATH or at %USERPROFILE%\source\flutter.'
  }
  $flutterCommand = Get-Command $defaultFlutter
}

$npxCommand = Get-Command npx.cmd -ErrorAction SilentlyContinue
if ($null -eq $npxCommand) {
  $npxCommand = Get-Command npx -ErrorAction SilentlyContinue
}
if ($null -eq $npxCommand) {
  throw 'BLOCKED: npx is required for pinned Deno and Supabase CLI gates.'
}

$flutterRoot = Split-Path (Split-Path $flutterCommand.Source -Parent) -Parent
$flutterExecutable = $flutterCommand.Source
$dartExecutable = Join-Path $flutterRoot 'bin\dart.bat'
$npxExecutable = $npxCommand.Source
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
    $pubCacheRoot = Join-Path $env:SystemDrive 'codex-pub-cache'
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    New-Item -ItemType Directory -Force -Path $pubCacheRoot | Out-Null
    $env:TEMP = $tempRoot
    $env:TMP = $tempRoot
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

  Push-Location $workingDirectory
  try {
    Invoke-Tool $flutterExecutable @('pub', 'get')
    Invoke-FormatCheck $dartExecutable
    Invoke-Tool $dartExecutable @('analyze')
    Invoke-Tool $flutterExecutable @('test', '-r', 'compact')

    Invoke-Tool $npxExecutable @('--yes', 'deno@2.5.6', 'fmt', '--check', 'supabase/functions')
    Invoke-Tool $npxExecutable @('--yes', 'deno@2.5.6', 'lint', '--config', 'supabase/functions/deno.json', 'supabase/functions')
    Invoke-Tool $npxExecutable @(
      '--yes', 'deno@2.5.6', 'test', '--config', 'supabase/functions/deno.json',
      '--allow-all', 'supabase/functions/tests'
    )
    foreach ($entrypoint in @(
      'verify-google-play-purchase/index.ts',
      'google-play-notification/index.ts',
      'spend-royal-jade/index.ts',
      'delete-account/index.ts',
      'sync-progress/index.ts'
    )) {
      Invoke-Tool $npxExecutable @(
        '--yes', 'deno@2.5.6', 'check', '--config',
        'supabase/functions/deno.json', "supabase/functions/$entrypoint"
      )
    }

    Assert-DockerAvailable
    Ensure-LocalSupabaseDatabase $npxExecutable
    Invoke-Tool $npxExecutable @('supabase', 'db', 'reset', '--local')
    Invoke-Tool $npxExecutable @('supabase', 'test', 'db', '--local')
    Invoke-Tool $npxExecutable @(
      'supabase', 'db', 'lint', '--local', '--level', 'warning',
      '--fail-on', 'warning'
    )

    Invoke-Tool $flutterExecutable @('build', 'web')

    if ($null -ne $mappedAndroidSdkProperty -and (Test-Path $localPropertiesPath)) {
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
  finally {
    Pop-Location
  }

  Write-Host "`nBackend checks passed." -ForegroundColor Green
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
