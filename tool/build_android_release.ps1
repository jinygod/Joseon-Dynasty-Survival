[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$BackupRoot,
    [string]$OutputRoot,
    [string]$ReleaseId,
    [string]$FlutterExecutable = 'flutter',
    [string]$JarsignerPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-RelativeFilePath {
    param(
        [Parameter(Mandatory = $true)] [string]$BaseDirectory,
        [Parameter(Mandatory = $true)] [string]$FilePath
    )

    $baseUri = [Uri]($BaseDirectory.TrimEnd('\') + '\')
    $fileUri = [Uri]$FilePath
    return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($fileUri).ToString())
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $OutputRoot) { $OutputRoot = Join-Path $repoRoot 'dist\android' }
$resolvedOutputRoot = [IO.Path]::GetFullPath($OutputRoot)
$resolvedBackupRoot = [IO.Path]::GetFullPath($BackupRoot)
$repoPrefix = $repoRoot.TrimEnd('\') + '\'
if ($resolvedBackupRoot.Equals($repoRoot, [StringComparison]::OrdinalIgnoreCase) -or
    $resolvedBackupRoot.StartsWith($repoPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'BackupRoot must be outside the repository.'
}

$versionLine = Select-String -LiteralPath (Join-Path $repoRoot 'pubspec.yaml') `
    -Pattern '^version:\s*(\S+)\s*$' | Select-Object -First 1
if (-not $versionLine) { throw 'Unable to read version from pubspec.yaml.' }
$version = $versionLine.Matches[0].Groups[1].Value
if (-not $ReleaseId) {
    $safeVersion = $version -replace '[^A-Za-z0-9._+-]', '_'
    $ReleaseId = "$safeVersion-$([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ'))"
}
if ($ReleaseId -notmatch '^[A-Za-z0-9._+-]+$') {
    throw 'ReleaseId may contain only letters, numbers, dot, underscore, plus, and hyphen.'
}

$releaseDirectory = Join-Path $resolvedOutputRoot $ReleaseId
$symbolsDirectory = Join-Path $releaseDirectory 'symbols'
$backupDirectory = Join-Path $resolvedBackupRoot $ReleaseId
foreach ($path in @($releaseDirectory, $backupDirectory)) {
    if (Test-Path -LiteralPath $path) { throw "Refusing to overwrite an existing release directory: $path" }
}
New-Item -ItemType Directory -Path $symbolsDirectory -Force | Out-Null

$flutterCommand = Get-Command $FlutterExecutable -ErrorAction Stop
$flutterArgs = @('build', 'appbundle', '--release', '--obfuscate', "--split-debug-info=$symbolsDirectory")
Push-Location $repoRoot
try {
    & $flutterCommand.Source @flutterArgs
    if ($LASTEXITCODE -ne 0) { throw "flutter build appbundle failed with exit code $LASTEXITCODE." }
}
finally { Pop-Location }

$builtAab = Join-Path $repoRoot 'build\app\outputs\bundle\release\app-release.aab'
if (-not (Test-Path -LiteralPath $builtAab -PathType Leaf)) {
    throw "Flutter completed without the expected AAB: $builtAab"
}
$artifactPath = Join-Path $releaseDirectory "pixel-survivor-$version.aab"
Copy-Item -LiteralPath $builtAab -Destination $artifactPath

$verifyScript = Join-Path $PSScriptRoot 'verify_android_release.ps1'
& $verifyScript -AabPath $artifactPath -SymbolsPath $symbolsDirectory `
    -JarsignerPath $JarsignerPath -HashOutputPath (Join-Path $releaseDirectory 'SHA256SUMS.txt') |
    Out-Null

$metadata = @(
    "release_id=$ReleaseId"
    "version=$version"
    'flutter_command=flutter build appbundle --release --obfuscate --split-debug-info=<release>/symbols'
) -join "`n"
[IO.File]::WriteAllText(
    (Join-Path $releaseDirectory 'BUILD-METADATA.txt'), "$metadata`n", [Text.UTF8Encoding]::new($false)
)

$manifestPath = Join-Path $releaseDirectory 'SHA256SUMS.txt'
$manifestLines = Get-ChildItem -LiteralPath $releaseDirectory -File -Recurse |
    Where-Object FullName -ne $manifestPath |
    Sort-Object FullName |
    ForEach-Object {
        $relativePath = Get-RelativeFilePath -BaseDirectory $releaseDirectory -FilePath $_.FullName
        $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  $relativePath"
    }
[IO.File]::WriteAllText(
    $manifestPath, (($manifestLines -join "`n") + "`n"), [Text.UTF8Encoding]::new($false)
)

New-Item -ItemType Directory -Path $resolvedBackupRoot -Force | Out-Null
Copy-Item -LiteralPath $releaseDirectory -Destination $backupDirectory -Recurse
foreach ($sourceFile in Get-ChildItem -LiteralPath $releaseDirectory -File -Recurse) {
    $relativePath = (Get-RelativeFilePath -BaseDirectory $releaseDirectory -FilePath $sourceFile.FullName).Replace('/', '\')
    $backupFile = Join-Path $backupDirectory $relativePath
    if (-not (Test-Path -LiteralPath $backupFile -PathType Leaf)) {
        throw "Backup is incomplete; missing: $relativePath"
    }
    $sourceHash = (Get-FileHash -LiteralPath $sourceFile.FullName -Algorithm SHA256).Hash
    $backupHash = (Get-FileHash -LiteralPath $backupFile -Algorithm SHA256).Hash
    if ($sourceHash -ne $backupHash) { throw "Backup hash mismatch: $relativePath" }
}

[PSCustomObject]@{
    ReleaseId = $ReleaseId
    ArtifactPath = $artifactPath
    SymbolsPath = $symbolsDirectory
    HashManifest = $manifestPath
    BackupPath = $backupDirectory
}
