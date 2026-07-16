[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$BackupRoot,
    [string]$OutputRoot,
    [string]$ReleaseId,
    [string]$FlutterExecutable = 'flutter',
    [string]$JarsignerPath,
    [string]$KeytoolPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-RelativeFilePath {
    param(
        [Parameter(Mandatory = $true)] [string]$BaseDirectory,
        [Parameter(Mandatory = $true)] [string]$FilePath
    )
    $baseUri = [Uri]($BaseDirectory.TrimEnd('\') + '\')
    return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri([Uri]$FilePath).ToString())
}

function Test-PathContains {
    param(
        [Parameter(Mandatory = $true)] [string]$Parent,
        [Parameter(Mandatory = $true)] [string]$Candidate
    )
    $parentPrefix = $Parent.TrimEnd('\') + '\'
    return $Candidate.Equals($Parent, [StringComparison]::OrdinalIgnoreCase) -or
        $Candidate.StartsWith($parentPrefix, [StringComparison]::OrdinalIgnoreCase)
}

function Read-KeyProperties {
    param([Parameter(Mandatory = $true)] [string]$Path)
    $values = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith('#') -or $trimmed.StartsWith('!')) { continue }
        if ($trimmed -notmatch '^([^:=\s]+)\s*[:=]\s*(.*)$') {
            throw "Malformed android/key.properties line: $line"
        }
        $values[$Matches[1]] = $Matches[2].Trim()
    }
    return $values
}

function Remove-PartialReleaseDirectory {
    param(
        [Parameter(Mandatory = $true)] [string]$Directory,
        [Parameter(Mandatory = $true)] [string]$ExpectedParent
    )
    if (-not (Test-Path -LiteralPath $Directory)) { return }
    $fullDirectory = [IO.Path]::GetFullPath($Directory)
    if (-not (Test-PathContains -Parent $ExpectedParent -Candidate $fullDirectory) -or
        $fullDirectory.Equals($ExpectedParent, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing unsafe partial release cleanup: $fullDirectory"
    }
    Remove-Item -LiteralPath $fullDirectory -Recurse -Force
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $OutputRoot) { $OutputRoot = Join-Path $repoRoot 'dist\android' }
$resolvedOutputRoot = [IO.Path]::GetFullPath($OutputRoot).TrimEnd('\')
$resolvedBackupRoot = [IO.Path]::GetFullPath($BackupRoot).TrimEnd('\')
if (Test-PathContains -Parent $repoRoot -Candidate $resolvedBackupRoot) {
    throw 'BackupRoot must be outside the repository.'
}
if ((Test-PathContains -Parent $resolvedOutputRoot -Candidate $resolvedBackupRoot) -or
    (Test-PathContains -Parent $resolvedBackupRoot -Candidate $resolvedOutputRoot)) {
    throw 'OutputRoot and BackupRoot must not overlap or contain one another.'
}

$signingEnvironmentNames = @(
    'ANDROID_KEYSTORE_PATH',
    'ANDROID_KEYSTORE_PASSWORD',
    'ANDROID_KEY_ALIAS',
    'ANDROID_KEY_PASSWORD',
    'ANDROID_UPLOAD_CERT_SHA256'
)
$configuredEnvironmentNames = @($signingEnvironmentNames | Where-Object {
    [Environment]::GetEnvironmentVariable($_)
})
$keyPropertiesPath = Join-Path $repoRoot 'android\key.properties'
if ((Test-Path -LiteralPath $keyPropertiesPath -PathType Leaf) -and $configuredEnvironmentNames.Count -gt 0) {
    throw 'Release signing configuration must not mix android/key.properties and ANDROID_* environment variables.'
}
if (Test-Path -LiteralPath $keyPropertiesPath -PathType Leaf) {
    $keyProperties = Read-KeyProperties -Path $keyPropertiesPath
    $expectedFingerprint = [string]$keyProperties['uploadCertSha256']
}
else {
    $expectedFingerprint = $env:ANDROID_UPLOAD_CERT_SHA256
}
$expectedFingerprint = ($expectedFingerprint -replace '[:\s]', '').ToUpperInvariant()
if ($expectedFingerprint -notmatch '^[0-9A-F]{64}$') {
    throw 'ANDROID_UPLOAD_CERT_SHA256 or uploadCertSha256 must contain exactly 64 hexadecimal digits.'
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
if ($ReleaseId -in @('.', '..')) {
    throw 'ReleaseId must not be dot traversal.'
}

$releaseDirectory = Join-Path $resolvedOutputRoot $ReleaseId
$symbolsDirectory = Join-Path $releaseDirectory 'symbols'
$backupDirectory = Join-Path $resolvedBackupRoot $ReleaseId
foreach ($path in @($releaseDirectory, $backupDirectory)) {
    if (Test-Path -LiteralPath $path) { throw "Refusing to overwrite an existing release directory: $path" }
}

$releaseDirectoryCreated = $false
$backupDirectoryCreated = $false
try {
    New-Item -ItemType Directory -Path $symbolsDirectory -Force | Out-Null
    $releaseDirectoryCreated = $true

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
    & $verifyScript -AabPath $artifactPath -ExpectedCertSha256 $expectedFingerprint `
        -SymbolsPath $symbolsDirectory -JarsignerPath $JarsignerPath -KeytoolPath $KeytoolPath |
        Out-Null

    $metadata = @(
        "release_id=$ReleaseId"
        "version=$version"
        'flutter_command=flutter build appbundle --release --obfuscate --split-debug-info=<release>/symbols'
    ) -join "`n"
    [IO.File]::WriteAllText(
        (Join-Path $releaseDirectory 'BUILD-METADATA.txt'), "$metadata`n", [Text.UTF8Encoding]::new($false)
    )
    [IO.File]::WriteAllText(
        (Join-Path $releaseDirectory 'UPLOAD-CERT-SHA256.txt'), "$expectedFingerprint`n",
        [Text.UTF8Encoding]::new($false)
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
    $backupDirectoryCreated = $true
    $restoreVerifyScript = Join-Path $PSScriptRoot 'restore_verify_android_release.ps1'
    & $restoreVerifyScript -ArtifactDirectory $backupDirectory `
        -JarsignerPath $JarsignerPath -KeytoolPath $KeytoolPath | Out-Null

    [PSCustomObject]@{
        ReleaseId = $ReleaseId
        ArtifactPath = $artifactPath
        SymbolsPath = $symbolsDirectory
        HashManifest = $manifestPath
        BackupPath = $backupDirectory
        CertificateSha256 = $expectedFingerprint
    }
}
catch {
    if ($backupDirectoryCreated -or (Test-Path -LiteralPath $backupDirectory)) {
        Remove-PartialReleaseDirectory -Directory $backupDirectory -ExpectedParent $resolvedBackupRoot
    }
    if ($releaseDirectoryCreated -or (Test-Path -LiteralPath $releaseDirectory)) {
        Remove-PartialReleaseDirectory -Directory $releaseDirectory -ExpectedParent $resolvedOutputRoot
    }
    throw
}
