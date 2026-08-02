[CmdletBinding()]
param([Parameter(Position = 0)][string]$PackageRoot = $PSScriptRoot)
$ErrorActionPreference = 'Stop'
$manifestPath = Join-Path $PackageRoot 'SHA256SUMS.txt'
if (!(Test-Path -LiteralPath $manifestPath)) { throw 'SHA256SUMS.txt is missing.' }
$verified = 0
foreach ($line in Get-Content -LiteralPath $manifestPath) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $match = [regex]::Match($line, '^([A-Fa-f0-9]{64})\s+\*(.+)$')
    if (!$match.Success) { throw "Invalid manifest line: $line" }
    $relative = $match.Groups[2].Value.Replace('/', [IO.Path]::DirectorySeparatorChar)
    $file = Join-Path $PackageRoot $relative
    if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing package file: $relative" }
    $actual = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
    if ($actual -ine $match.Groups[1].Value) { throw "Checksum mismatch: $relative" }
    $verified++
}
if ($verified -eq 0) { throw 'The checksum manifest is empty.' }
Write-Output "Verified $verified package files."
