param(
  [string]$FlutterExecutable,
  [string]$DartExecutable,
  [int]$OpenP0 = 0,
  [int]$OpenP1 = 0,
  [int]$OpenP2 = 0,
  [int]$OpenP3 = 0,
  [string]$P2ExceptionsJson,
  [string]$P3RecordsJson,
  [string]$Output = 'build/qa/release-candidate-evidence.json'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$qaRoot = Join-Path $repoRoot 'build\qa\release-gates'
New-Item -ItemType Directory -Force -Path $qaRoot | Out-Null

function Get-ArtifactRecord {
  param(
    [string]$Command,
    [int]$ExitCode,
    [string]$Path,
    [datetime]$CompletedAt
  )
  $item = Get-Item -LiteralPath $Path
  $relative = [IO.Path]::GetRelativePath($repoRoot, $item.FullName)
  $hash = (& git -C $repoRoot hash-object -- $relative).Trim()
  return [ordered]@{
    command = $Command
    exitCode = $ExitCode
    completedAt = $CompletedAt.ToUniversalTime().ToString('o')
    artifactPath = $relative.Replace('\', '/')
    artifactHash = $hash
    artifactModifiedAt = $item.LastWriteTimeUtc.ToString('o')
  }
}

function Invoke-EvidenceGate {
  param(
    [string]$Name,
    [string]$Executable,
    [string[]]$Arguments
  )
  $log = Join-Path $qaRoot "$Name.log"
  Push-Location $repoRoot
  try {
    & $Executable @Arguments *>&1 | Tee-Object -FilePath $log | Out-Host
    $code = $LASTEXITCODE
  }
  finally {
    Pop-Location
  }
  $completed = [datetime]::UtcNow
  return Get-ArtifactRecord `
    -Command "$Executable $($Arguments -join ' ')" `
    -ExitCode $code `
    -Path $log `
    -CompletedAt $completed
}

$flutter = if ([string]::IsNullOrWhiteSpace($FlutterExecutable)) {
  (Get-Command flutter -ErrorAction Stop).Source
} else { $FlutterExecutable }
$dart = if ([string]::IsNullOrWhiteSpace($DartExecutable)) {
  (Get-Command dart -ErrorAction Stop).Source
} else { $DartExecutable }
$gates = [ordered]@{}
$gates.analyze = Invoke-EvidenceGate 'analyze' $dart @('analyze')
$gates.tests = Invoke-EvidenceGate 'tests' $flutter @('test', '-r', 'compact')
$gates.webBuild = Invoke-EvidenceGate 'web-build' $flutter @('build', 'web')
$gates.fiveMinuteProfile = Invoke-EvidenceGate `
  'five-minute-profile' $flutter `
  @('test', 'test/game/five_minute_performance_development_log_test.dart', '-r', 'compact')
$gates.goldens = Invoke-EvidenceGate `
  'goldens' $flutter `
  @('test', 'test/app/release_surface_golden_test.dart', '-r', 'compact')

function Read-Records {
  param([string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path)) {
    Write-Output -NoEnumerate @()
    return
  }
  Write-Output -NoEnumerate @(
    Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  )
}

$branch = (& git -C $repoRoot branch --show-current).Trim()
$commit = (& git -C $repoRoot rev-parse HEAD).Trim()
$versionMatch = Select-String `
  -Path (Join-Path $repoRoot 'pubspec.yaml') `
  -Pattern '^version:\s*(\S+)\s*$'
if ($null -eq $versionMatch) { throw 'pubspec.yaml version is missing.' }
$version = $versionMatch.Matches[0].Groups[1].Value
$manifest = [ordered]@{
  branch = $branch
  commit = $commit
  version = $version
  generatedAt = [datetime]::UtcNow.ToString('o')
  gates = $gates
  defects = [ordered]@{
    openP0 = $OpenP0
    openP1 = $OpenP1
    openP2 = $OpenP2
    openP3 = $OpenP3
    p2Exceptions = Read-Records $P2ExceptionsJson
    p3Records = Read-Records $P3RecordsJson
  }
}

$outputPath = if ([IO.Path]::IsPathRooted($Output)) {
  $Output
} else {
  Join-Path $repoRoot $Output
}
New-Item -ItemType Directory -Force -Path (Split-Path $outputPath) | Out-Null
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $outputPath -Encoding utf8
Write-Host "Evidence manifest: $outputPath"
Write-Host 'Run the report tool to revalidate repository identity and artifacts.'
