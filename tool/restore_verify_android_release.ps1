[CmdletBinding(DefaultParameterSetName = 'Digest')]
param(
    [Parameter(Mandatory = $true)] [string]$ArtifactDirectory,
    [Parameter(Mandatory = $true, ParameterSetName = 'Digest')]
    [string]$ExpectedManifestSha256,
    [Parameter(Mandatory = $true, ParameterSetName = 'TrustAnchor')]
    [string]$TrustAnchorPath,
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

if (-not (Test-Path -LiteralPath $ArtifactDirectory -PathType Container)) {
    throw "Backup artifact directory not found: $ArtifactDirectory"
}
$root = (Resolve-Path -LiteralPath $ArtifactDirectory).Path
$rootPrefix = $root.TrimEnd('\') + '\'
$manifestPath = Join-Path $root 'SHA256SUMS.txt'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "SHA256SUMS.txt not found in backup: $root"
}

if ($PSCmdlet.ParameterSetName -eq 'TrustAnchor') {
    if (-not (Test-Path -LiteralPath $TrustAnchorPath -PathType Leaf)) {
        throw "Manifest trust anchor file not found: $TrustAnchorPath"
    }
    $resolvedTrustAnchor = (Resolve-Path -LiteralPath $TrustAnchorPath).Path
    $trustAnchorDirectory = [IO.Path]::GetFullPath((Split-Path -Parent $resolvedTrustAnchor)).TrimEnd('\')
    if ((Test-PathContains -Parent $root -Candidate $trustAnchorDirectory) -or
        (Test-PathContains -Parent $trustAnchorDirectory -Candidate $root)) {
        throw 'Manifest trust anchor path and backup must not overlap or contain one another.'
    }
    $ExpectedManifestSha256 = (Get-Content -LiteralPath $resolvedTrustAnchor -Raw).Trim()
}
$expectedManifestHash = ($ExpectedManifestSha256 -replace '[:\s]', '').ToLowerInvariant()
if ($expectedManifestHash -notmatch '^[0-9a-f]{64}$') {
    throw 'ExpectedManifestSha256 or TrustAnchorPath must provide exactly 64 hexadecimal digits.'
}
$actualManifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualManifestHash -ne $expectedManifestHash) {
    throw 'Manifest SHA-256 does not match trust anchor.'
}

$manifestEntries = [Collections.Generic.Dictionary[string, string]]::new(
    [StringComparer]::OrdinalIgnoreCase
)
foreach ($line in Get-Content -LiteralPath $manifestPath) {
    if (-not $line.Trim()) { continue }
    if ($line -notmatch '^([0-9a-fA-F]{64})  (.+)$') {
        throw "Malformed SHA256SUMS.txt line: $line"
    }
    $expectedHash = $Matches[1].ToLowerInvariant()
    $relativePath = $Matches[2].Replace('/', '\')
    if ([IO.Path]::IsPathRooted($relativePath) -or $relativePath -match '(^|\\)\.\.(\\|$)') {
        throw "Unsafe manifest path: $relativePath"
    }
    if ($manifestEntries.ContainsKey($relativePath)) {
        throw "Duplicate manifest path: $relativePath"
    }
    $candidate = [IO.Path]::GetFullPath((Join-Path $root $relativePath))
    if (-not $candidate.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Manifest path escapes backup root: $relativePath"
    }
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        throw "Backup file listed in manifest is missing: $relativePath"
    }
    $actualHash = (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $expectedHash) { throw "Backup hash mismatch: $relativePath" }
    $manifestEntries.Add($relativePath, $expectedHash)
}
if ($manifestEntries.Count -eq 0) { throw 'SHA256SUMS.txt contains no artifact entries.' }

$actualFiles = @(Get-ChildItem -LiteralPath $root -File -Recurse | Where-Object FullName -ne $manifestPath)
foreach ($file in $actualFiles) {
    $relativePath = (Get-RelativeFilePath -BaseDirectory $root -FilePath $file.FullName).Replace('/', '\')
    if (-not $manifestEntries.ContainsKey($relativePath)) {
        throw "Unexpected backup file not covered by SHA256SUMS.txt: $relativePath"
    }
}
if ($actualFiles.Count -ne $manifestEntries.Count) {
    throw 'Backup file count does not match SHA256SUMS.txt.'
}

$fingerprintPath = Join-Path $root 'UPLOAD-CERT-SHA256.txt'
if (-not (Test-Path -LiteralPath $fingerprintPath -PathType Leaf)) {
    throw 'UPLOAD-CERT-SHA256.txt is missing from the backup.'
}
$expectedFingerprint = (Get-Content -LiteralPath $fingerprintPath -Raw).Trim()
$aabFiles = @($actualFiles | Where-Object Extension -eq '.aab')
if ($aabFiles.Count -ne 1) { throw 'Backup must contain exactly one AAB.' }
$symbolsPath = Join-Path $root 'symbols'

$verifyScript = Join-Path $PSScriptRoot 'verify_android_release.ps1'
$signature = & $verifyScript -AabPath $aabFiles[0].FullName `
    -ExpectedCertSha256 $expectedFingerprint -SymbolsPath $symbolsPath `
    -JarsignerPath $JarsignerPath -KeytoolPath $KeytoolPath

[PSCustomObject]@{
    ArtifactDirectory = $root
    ManifestEntries = $manifestEntries.Count
    ManifestSha256 = $actualManifestHash
    AabPath = $aabFiles[0].FullName
    CertificateSha256 = $signature.CertificateSha256
}
