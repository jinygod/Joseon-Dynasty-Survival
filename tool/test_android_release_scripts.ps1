$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-ThrowsLike {
    param(
        [Parameter(Mandatory = $true)] [scriptblock]$Action,
        [Parameter(Mandatory = $true)] [string]$Pattern
    )
    try {
        & $Action
    }
    catch {
        if ($_.Exception.Message -notlike $Pattern) {
            throw "Expected '$Pattern', got '$($_.Exception.Message)'."
        }
        return
    }
    throw "Expected failure matching '$Pattern'."
}

function Write-HashManifest {
    param([Parameter(Mandatory = $true)] [string]$Root)
    $manifestPath = Join-Path $Root 'SHA256SUMS.txt'
    $lines = Get-ChildItem -LiteralPath $Root -File -Recurse |
        Where-Object FullName -ne $manifestPath |
        Sort-Object FullName |
        ForEach-Object {
            $relative = $_.FullName.Substring($Root.TrimEnd('\').Length + 1).Replace('\', '/')
            $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            "$hash  $relative"
        }
    [IO.File]::WriteAllText($manifestPath, (($lines -join "`n") + "`n"))
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$buildScript = Join-Path $PSScriptRoot 'build_android_release.ps1'
$restoreScript = Join-Path $PSScriptRoot 'restore_verify_android_release.ps1'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) "pixel-survivor-release-script-test-$PID"
$outputRoot = Join-Path $testRoot 'output'
$backupRoot = Join-Path $testRoot 'backup'
$trustRoot = Join-Path $testRoot 'trust'
$fakeFlutter = Join-Path $testRoot 'flutter-fail.cmd'
$oldEnvironment = @{}
$signingNames = @(
    'ANDROID_KEYSTORE_PATH', 'ANDROID_KEYSTORE_PASSWORD', 'ANDROID_KEY_ALIAS',
    'ANDROID_KEY_PASSWORD', 'ANDROID_UPLOAD_CERT_SHA256'
)
foreach ($name in $signingNames) { $oldEnvironment[$name] = [Environment]::GetEnvironmentVariable($name) }

New-Item -ItemType Directory -Path $testRoot | Out-Null
try {
    Assert-ThrowsLike -Pattern '*must not overlap*' -Action {
        & $buildScript -OutputRoot $outputRoot -BackupRoot $outputRoot `
            -TrustAnchorRoot $trustRoot -ReleaseId 'overlap'
    }
    Assert-ThrowsLike -Pattern '*must not overlap*' -Action {
        & $buildScript -OutputRoot $outputRoot -BackupRoot (Join-Path $outputRoot 'nested') `
            -TrustAnchorRoot $trustRoot -ReleaseId 'nested-overlap'
    }
    Assert-ThrowsLike -Pattern '*must not overlap*' -Action {
        & $buildScript -OutputRoot (Join-Path $backupRoot 'nested') -BackupRoot $backupRoot `
            -TrustAnchorRoot $trustRoot -ReleaseId 'reverse-nested-overlap'
    }
    Assert-ThrowsLike -Pattern '*trust anchor*must not overlap*' -Action {
        & $buildScript -OutputRoot $outputRoot -BackupRoot $backupRoot `
            -TrustAnchorRoot (Join-Path $backupRoot 'trust') -ReleaseId 'trust-overlap'
    }
    foreach ($name in $signingNames) { [Environment]::SetEnvironmentVariable($name, $null) }
    Assert-ThrowsLike -Pattern '*uploadCertSha256 must contain exactly 64 hexadecimal digits*' -Action {
        & $buildScript -OutputRoot $outputRoot -BackupRoot $backupRoot `
            -TrustAnchorRoot $trustRoot -ReleaseId 'missing-fingerprint'
    }

    [IO.File]::WriteAllText($fakeFlutter, "@exit /b 23`r`n")
    $env:ANDROID_KEYSTORE_PATH = Join-Path $testRoot 'unused.jks'
    $env:ANDROID_KEYSTORE_PASSWORD = 'unused'
    $env:ANDROID_KEY_ALIAS = 'unused'
    $env:ANDROID_KEY_PASSWORD = 'unused'
    $env:ANDROID_UPLOAD_CERT_SHA256 = 'A' * 64
    foreach ($unsafeReleaseId in @('.', '..')) {
        Assert-ThrowsLike -Pattern '*ReleaseId must not be dot traversal*' -Action {
            & $buildScript -OutputRoot $outputRoot -BackupRoot $backupRoot -TrustAnchorRoot $trustRoot `
                -ReleaseId $unsafeReleaseId -FlutterExecutable $fakeFlutter
        }
    }
    Assert-ThrowsLike -Pattern '*flutter build appbundle failed*' -Action {
        & $buildScript -OutputRoot $outputRoot -BackupRoot $backupRoot -TrustAnchorRoot $trustRoot `
            -ReleaseId 'retryable' -FlutterExecutable $fakeFlutter
    }
    if (Test-Path -LiteralPath (Join-Path $outputRoot 'retryable')) {
        throw 'Failed release directory was not cleaned.'
    }
    if (Test-Path -LiteralPath (Join-Path $backupRoot 'retryable')) {
        throw 'Failed backup directory was not cleaned.'
    }

    $restoreRoot = Join-Path $testRoot 'restore'
    New-Item -ItemType Directory -Path (Join-Path $restoreRoot 'symbols') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $restoreRoot 'app.aab'), 'not-a-real-aab')
    [IO.File]::WriteAllText((Join-Path $restoreRoot 'symbols\app.android-arm64.symbols'), 'symbols')
    [IO.File]::WriteAllText((Join-Path $restoreRoot 'BUILD-METADATA.txt'), 'metadata')
    [IO.File]::WriteAllText((Join-Path $restoreRoot 'UPLOAD-CERT-SHA256.txt'), ('A' * 64))
    Write-HashManifest -Root $restoreRoot
    $expectedManifestHash = (Get-FileHash -LiteralPath (Join-Path $restoreRoot 'SHA256SUMS.txt') `
        -Algorithm SHA256).Hash
    New-Item -ItemType Directory -Path $trustRoot -Force | Out-Null
    $trustAnchorPath = Join-Path $trustRoot 'restore.MANIFEST-SHA256.txt'
    [IO.File]::WriteAllText($trustAnchorPath, $expectedManifestHash)
    $internalAnchorPath = Join-Path $restoreRoot 'untrusted-anchor.txt'
    [IO.File]::WriteAllText($internalAnchorPath, $expectedManifestHash)
    Assert-ThrowsLike -Pattern '*trust anchor path and backup must not overlap*' -Action {
        & $restoreScript -ArtifactDirectory $restoreRoot -TrustAnchorPath $internalAnchorPath
    }
    Remove-Item -LiteralPath $internalAnchorPath
    [IO.File]::WriteAllText((Join-Path $restoreRoot 'unexpected.txt'), 'unexpected')
    Assert-ThrowsLike -Pattern '*Unexpected backup file*' -Action {
        & $restoreScript -ArtifactDirectory $restoreRoot -ExpectedManifestSha256 $expectedManifestHash
    }
    Remove-Item -LiteralPath (Join-Path $restoreRoot 'unexpected.txt')
    [IO.File]::AppendAllText((Join-Path $restoreRoot 'BUILD-METADATA.txt'), '-tampered')
    Assert-ThrowsLike -Pattern '*Backup hash mismatch*' -Action {
        & $restoreScript -ArtifactDirectory $restoreRoot -ExpectedManifestSha256 $expectedManifestHash
    }
    Write-HashManifest -Root $restoreRoot
    Assert-ThrowsLike -Pattern '*Manifest SHA-256 does not match trust anchor*' -Action {
        & $restoreScript -ArtifactDirectory $restoreRoot -TrustAnchorPath $trustAnchorPath
    }

    $global:LASTEXITCODE = 0
    Write-Host 'Android release script regression tests passed.'
}
finally {
    foreach ($name in $signingNames) {
        [Environment]::SetEnvironmentVariable($name, $oldEnvironment[$name])
    }
    if (Test-Path -LiteralPath $testRoot) {
        $resolved = (Resolve-Path -LiteralPath $testRoot).Path
        $tempPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
        if (-not $resolved.StartsWith($tempPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing unsafe test cleanup: $resolved"
        }
        [IO.Directory]::Delete($resolved, $true)
    }
}
