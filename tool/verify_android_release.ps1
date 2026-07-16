[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$AabPath,
    [Parameter(Mandatory = $true)] [string]$ExpectedCertSha256,
    [string]$SymbolsPath,
    [string]$JarsignerPath,
    [string]$KeytoolPath,
    [string]$HashOutputPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Resolve-JavaTool {
    param(
        [Parameter(Mandatory = $true)] [string]$ToolName,
        [string]$RequestedPath
    )

    $candidates = [System.Collections.Generic.List[string]]::new()
    if ($RequestedPath) { $candidates.Add($RequestedPath) }
    $command = Get-Command $ToolName -ErrorAction SilentlyContinue
    if ($command) { $candidates.Add($command.Source) }
    if ($env:JAVA_HOME) { $candidates.Add((Join-Path $env:JAVA_HOME "bin\$ToolName.exe")) }
    $candidates.Add("C:\Program Files\Android\Android Studio\jbr\bin\$ToolName.exe")

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    throw "$ToolName was not found. Pass its explicit path or set JAVA_HOME to a JDK."
}

function Normalize-CertificateFingerprint {
    param([Parameter(Mandatory = $true)] [string]$Fingerprint)

    $normalized = ($Fingerprint -replace '[:\s]', '').ToUpperInvariant()
    if ($normalized -notmatch '^[0-9A-F]{64}$') {
        throw 'ExpectedCertSha256 must contain exactly 64 hexadecimal digits.'
    }
    return $normalized
}

if (-not (Test-Path -LiteralPath $AabPath -PathType Leaf)) { throw "AAB not found: $AabPath" }
$resolvedAab = (Resolve-Path -LiteralPath $AabPath).Path
if ([IO.Path]::GetExtension($resolvedAab) -ne '.aab') { throw "Expected an .aab artifact: $resolvedAab" }
if ((Get-Item -LiteralPath $resolvedAab).Length -eq 0) { throw "AAB is empty: $resolvedAab" }
$expectedFingerprint = Normalize-CertificateFingerprint -Fingerprint $ExpectedCertSha256

$resolvedSymbols = $null
if ($SymbolsPath) {
    if (-not (Test-Path -LiteralPath $SymbolsPath -PathType Container)) {
        throw "Split debug info directory not found: $SymbolsPath"
    }
    $resolvedSymbols = (Resolve-Path -LiteralPath $SymbolsPath).Path
    $symbolFiles = @(Get-ChildItem -LiteralPath $resolvedSymbols -File -Recurse)
    if ($symbolFiles.Count -eq 0 -or @($symbolFiles | Where-Object Length -gt 0).Count -eq 0) {
        throw "Split debug info directory contains no non-empty files: $resolvedSymbols"
    }
}

$resolvedJarsigner = Resolve-JavaTool -ToolName 'jarsigner' -RequestedPath $JarsignerPath
$resolvedKeytool = Resolve-JavaTool -ToolName 'keytool' -RequestedPath $KeytoolPath
$jarsignerOutput = & $resolvedJarsigner @('-verify', '-strict', $resolvedAab) 2>&1
$jarsignerExitCode = $LASTEXITCODE
$jarsignerText = $jarsignerOutput -join "`n"

$fatalSignerProblem = '(?i)(has expired|not yet valid|disabled algorithm|algorithm .* is disabled|treated as unsigned)'
if ($jarsignerText -match $fatalSignerProblem) {
    $jarsignerOutput | Write-Host
    throw 'AAB signer certificate has expired, is not yet valid, or uses a disabled algorithm.'
}
if ($jarsignerText -notmatch '(?i)jar verified') {
    $jarsignerOutput | Write-Host
    throw "jarsigner -verify -strict did not verify the AAB (exit $jarsignerExitCode)."
}
if ($jarsignerExitCode -eq 4) {
    $errorBlock = [regex]::Match(
        $jarsignerText,
        '(?ms)^Error:\s*\r?\n(?<body>.*?)(?=^Warning:|\z)'
    )
    if (-not $errorBlock.Success) {
        throw 'jarsigner exit 4 did not contain the expected self-signed certificate error block.'
    }
    $errorLines = @($errorBlock.Groups['body'].Value -split '\r?\n' | Where-Object { $_.Trim() })
    $allowedErrorPatterns = @(
        '^This jar contains entries whose certificate chain is invalid\. Reason: PKIX path building failed: .+$',
        '^This jar contains entries whose signer certificate is self-signed\.$'
    )
    foreach ($line in $errorLines) {
        if (-not @($allowedErrorPatterns | Where-Object { $line -match $_ }).Count) {
            throw "Unexpected jarsigner strict error: $line"
        }
    }
    if ($errorLines.Count -ne 2) {
        throw 'jarsigner exit 4 is allowed only for the self-signed upload certificate chain warnings.'
    }
    Write-Warning 'AAB entries verified; only the expected self-signed upload certificate chain is untrusted locally.'
}
elseif ($jarsignerExitCode -ne 0) {
    $jarsignerOutput | Write-Host
    throw "jarsigner -verify -strict failed with exit code $jarsignerExitCode."
}

$certificateOutput = & $resolvedKeytool @('-printcert', '-rfc', '-jarfile', $resolvedAab) 2>&1
if ($LASTEXITCODE -ne 0) {
    $certificateOutput | Write-Host
    throw 'keytool could not extract the AAB signer certificate.'
}
$certificateMatch = [regex]::Match(
    ($certificateOutput -join "`n"),
    '(?ms)-----BEGIN CERTIFICATE-----\s*(?<body>[A-Za-z0-9+/=\s]+?)\s*-----END CERTIFICATE-----'
)
if (-not $certificateMatch.Success) { throw 'AAB signer certificate was not found.' }
$certificateBytes = [Convert]::FromBase64String(($certificateMatch.Groups['body'].Value -replace '\s', ''))
$certificate = [Security.Cryptography.X509Certificates.X509Certificate2]::new($certificateBytes)
$now = [DateTime]::UtcNow
if ($certificate.NotAfter.ToUniversalTime() -le $now) { throw 'AAB signer certificate has expired.' }
if ($certificate.NotBefore.ToUniversalTime() -gt $now) { throw 'AAB signer certificate is not yet valid.' }
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $actualFingerprint = -join ($sha256.ComputeHash($certificate.RawData) | ForEach-Object { $_.ToString('X2') })
}
finally { $sha256.Dispose() }
if ($actualFingerprint -ne $expectedFingerprint) {
    throw 'AAB signer certificate fingerprint does not match ExpectedCertSha256.'
}

$aabHash = Get-FileHash -LiteralPath $resolvedAab -Algorithm SHA256
if ($HashOutputPath) {
    $hashParent = Split-Path -Parent $HashOutputPath
    if ($hashParent) { New-Item -ItemType Directory -Path $hashParent -Force | Out-Null }
    $hashLine = "$($aabHash.Hash.ToLowerInvariant())  $([IO.Path]::GetFileName($resolvedAab))`n"
    [IO.File]::WriteAllText(
        [IO.Path]::GetFullPath($HashOutputPath), $hashLine, [Text.UTF8Encoding]::new($false)
    )
}

[PSCustomObject]@{
    AabPath = $resolvedAab
    Sha256 = $aabHash.Hash.ToLowerInvariant()
    CertificateSha256 = $actualFingerprint
    CertificateNotBefore = $certificate.NotBefore.ToUniversalTime()
    CertificateNotAfter = $certificate.NotAfter.ToUniversalTime()
    SymbolsPath = $resolvedSymbols
    JarsignerPath = $resolvedJarsigner
    KeytoolPath = $resolvedKeytool
}
