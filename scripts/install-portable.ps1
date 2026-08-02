[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Source,
    [switch]$DesktopShortcut,
    [switch]$WidgetShortcut,
    [switch]$NoLaunch,
    [string]$ExpectedExecutableHash = 'B6DE4F2B16E4B6C98D94DA576E7E66143EC3FA0DE72A8844AD13118B85B2183D'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ([Security.Principal.WindowsIdentity]::GetCurrent().Owner -and
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Verbose 'Administrator rights are not required; continuing without privileged operations.'
}

$installRoot = Join-Path $env:LOCALAPPDATA 'Programs\Movia'
$expectedExe = Join-Path $installRoot 'movia_desktop.exe'
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Movia Desktop.lnk'
$desktop = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Movia Desktop.lnk'
$widget = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Movia Desktop Widget.lnk'
$stageRoot = Join-Path $env:LOCALAPPDATA ('Movia\Deployment\stage-' + [Guid]::NewGuid().ToString('N'))
$backupRoot = Join-Path $env:LOCALAPPDATA ('Movia\Deployment\backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$sourceRoot = $null
$movedOld = $false

function Get-AppRoot([string]$root) {
    $direct = Join-Path $root 'movia_desktop.exe'
    if (Test-Path -LiteralPath $direct -PathType Leaf) { return $root }
    $children = @(Get-ChildItem -LiteralPath $root -Directory)
    foreach ($child in $children) {
        if (Test-Path -LiteralPath (Join-Path $child.FullName 'movia_desktop.exe') -PathType Leaf) {
            return $child.FullName
        }
    }
    throw 'The source does not contain a Movia portable application directory.'
}

function Test-PackageManifest([string]$root) {
    $manifest = Join-Path $root 'SHA256SUMS.txt'
    if (!(Test-Path -LiteralPath $manifest -PathType Leaf)) { return }
    foreach ($line in Get-Content -LiteralPath $manifest) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $match = [regex]::Match($line, '^([A-Fa-f0-9]{64})\s+\*(.+)$')
        if (!$match.Success) { throw "Invalid checksum manifest line: $line" }
        $relative = $match.Groups[2].Value.Replace('/', [IO.Path]::DirectorySeparatorChar)
        $candidate = [IO.Path]::GetFullPath((Join-Path $root $relative))
        $rootPrefix = [IO.Path]::GetFullPath($root).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
        if (!$candidate.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Unsafe checksum manifest path: $relative"
        }
        if (!(Test-Path -LiteralPath $candidate -PathType Leaf)) { throw "Package file is missing: $relative" }
        $actual = (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash
        if ($actual -ine $match.Groups[1].Value) { throw "Package checksum mismatch: $relative" }
    }
}

function Stop-Movia {
    $processes = @(Get-Process -Name 'movia_desktop' -ErrorAction SilentlyContinue)
    foreach ($process in $processes) {
        if ($process.MainWindowHandle -ne 0) { [void]$process.CloseMainWindow() }
    }
    if ($processes.Count -gt 0) {
        $processes | Wait-Process -Timeout 15 -ErrorAction SilentlyContinue
        $remaining = @(Get-Process -Name 'movia_desktop' -ErrorAction SilentlyContinue)
        if ($remaining.Count -gt 0) { throw 'Movia or its widget is still running. Close it and retry.' }
    }
}

function New-MoviaShortcut([string]$path, [string]$target, [string]$arguments, [string]$description) {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($path)
    $shortcut.TargetPath = $target
    $shortcut.WorkingDirectory = Split-Path -Parent $target
    $shortcut.Description = $description
    $shortcut.IconLocation = "$target,0"
    $shortcut.Arguments = $arguments
    $shortcut.Save()
}

try {
    if (!(Test-Path -LiteralPath $Source)) { throw "Source not found: $Source" }
    New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null
    if ([IO.Path]::GetExtension($Source) -ieq '.zip') {
        Expand-Archive -LiteralPath $Source -DestinationPath $stageRoot -Force
        Test-PackageManifest $stageRoot
        $sourceRoot = Get-AppRoot $stageRoot
    } else {
        $resolved = (Resolve-Path -LiteralPath $Source).Path
        Test-PackageManifest $resolved
        $sourceRoot = Get-AppRoot $resolved
        Copy-Item -LiteralPath $sourceRoot -Destination (Join-Path $stageRoot 'app') -Recurse
        $sourceRoot = Join-Path $stageRoot 'app'
    }

    $sourceExe = Join-Path $sourceRoot 'movia_desktop.exe'
    $actualHash = (Get-FileHash -LiteralPath $sourceExe -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($actualHash -ne $ExpectedExecutableHash.ToUpperInvariant()) {
        throw "Executable SHA-256 is not approved. Expected $ExpectedExecutableHash; received $actualHash."
    }
    foreach ($required in @('flutter_windows.dll', 'data\app.so', 'data\icudtl.dat')) {
        if (!(Test-Path -LiteralPath (Join-Path $sourceRoot $required) -PathType Leaf)) {
            throw "Required release file is missing: $required"
        }
    }

    Stop-Movia
    New-Item -ItemType Directory -Path (Split-Path -Parent $installRoot) -Force | Out-Null
    if (Test-Path -LiteralPath $installRoot) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $backupRoot) -Force | Out-Null
        Move-Item -LiteralPath $installRoot -Destination $backupRoot
        $movedOld = $true
    }
    Move-Item -LiteralPath $sourceRoot -Destination $installRoot

    $deployment = [ordered]@{
        deploymentType = 'Portable Installed'
        executableHash = $actualHash
        installedAt = (Get-Date).ToUniversalTime().ToString('o')
        dataPath = (Join-Path $env:APPDATA 'Ahmed Abdelaal\Movia Desktop')
        legacyDataPath = (Join-Path $env:APPDATA 'com.movia\movia_desktop')
    }
    $deployment | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $installRoot 'deployment-info.json') -Encoding UTF8

    New-MoviaShortcut $startMenu $expectedExe '' 'Movia Desktop'
    if ($DesktopShortcut) { New-MoviaShortcut $desktop $expectedExe '' 'Movia Desktop' }
    New-MoviaShortcut $widget $expectedExe '--widget' 'Movia Desktop Widget'
    if ($DesktopShortcut -and $WidgetShortcut) {
        New-MoviaShortcut (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Movia Desktop Widget.lnk') $expectedExe '--widget' 'Movia Desktop Widget'
    }

    if (!$NoLaunch) {
        $started = Start-Process -FilePath $expectedExe -WorkingDirectory $installRoot -PassThru
        Start-Sleep -Seconds 5
        $running = Get-Process -Id $started.Id -ErrorAction SilentlyContinue
        if ($null -eq $running) { throw 'The deployed executable did not remain running.' }
        $runningPath = $running.Path
        if (![IO.Path]::GetFullPath($runningPath).Equals([IO.Path]::GetFullPath($expectedExe), [StringComparison]::OrdinalIgnoreCase)) {
            throw "Unexpected launched executable path: $runningPath"
        }
    }

    Write-Output "Portable Installed deployment succeeded: $expectedExe"
    Write-Output "Executable SHA-256: $actualHash"
    if ($movedOld) { Write-Output "Previous application backup: $backupRoot" }
} catch {
    Get-Process -Name 'movia_desktop' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    if ($movedOld) {
        if (Test-Path -LiteralPath $installRoot) {
            $failed = "$installRoot.failed-$(Get-Date -Format 'yyyyMMddHHmmss')"
            Move-Item -LiteralPath $installRoot -Destination $failed -ErrorAction SilentlyContinue
        }
        if (Test-Path -LiteralPath $backupRoot) { Move-Item -LiteralPath $backupRoot -Destination $installRoot }
    }
    throw
} finally {
    if (Test-Path -LiteralPath $stageRoot) { Remove-Item -LiteralPath $stageRoot -Recurse -Force }
}
