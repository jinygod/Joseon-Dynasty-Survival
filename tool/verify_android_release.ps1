[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$AabPath,
    [string]$SymbolsPath,
    [string]$JarsignerPath,
    [string]$HashOutputPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Resolve-Jarsigner {
    param([string]$RequestedPath)

    $candidates = [System.Collections.Generic.List[string]]::new()
    if ($RequestedPath) { $candidates.Add($RequestedPath) }
    $command = Get-Command 'jarsigner' -ErrorAction SilentlyContinue
    if ($command) { $candidates.Add($command.Source) }
    if ($env:JAVA_HOME) { $candidates.Add((Join-Path $env:JAVA_HOME 'bin\jarsigner.exe')) }
    $candidates.Add('C:\Program Files\Android\Android Studio\jbr\bin\jarsigner.exe')

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    throw 'jarsigner was not found. Pass -JarsignerPath or set JAVA_HOME to a JDK.'
}

if (-not (Test-Path -LiteralPath $AabPath -PathType Leaf)) { throw "AAB not found: $AabPath" }
$resolvedAab = (Resolve-Path -LiteralPath $AabPath).Path
if ([IO.Path]::GetExtension($resolvedAab) -ne '.aab') { throw "Expected an .aab artifact: $resolvedAab" }
if ((Get-Item -LiteralPath $resolvedAab).Length -eq 0) { throw "AAB is empty: $resolvedAab" }

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

$resolvedJarsigner = Resolve-Jarsigner -RequestedPath $JarsignerPath
$jarsignerOutput = & $resolvedJarsigner @('-verify', '-strict', $resolvedAab) 2>&1
$jarsignerExitCode = $LASTEXITCODE
$jarsignerText = $jarsignerOutput -join "`n"
# Android upload certificates are normally self-signed. jarsigner reports that
# untrusted certificate chain as exit code 4 even when every AAB entry verifies.
if ($jarsignerExitCode -notin @(0, 4) -or $jarsignerText -notmatch 'jar verified') {
    $jarsignerOutput | Write-Host
    throw "jarsigner -verify -strict failed with exit code $jarsignerExitCode."
}
if ($jarsignerExitCode -eq 4) {
    Write-Warning 'AAB signatures verified; jarsigner cannot establish trust for the self-signed upload certificate.'
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
    SymbolsPath = $resolvedSymbols
    JarsignerPath = $resolvedJarsigner
}
