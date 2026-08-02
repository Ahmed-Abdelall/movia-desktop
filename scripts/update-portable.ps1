[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$PackageZip)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$stage = Join-Path $env:LOCALAPPDATA ('Movia\Updates\' + [Guid]::NewGuid().ToString('N'))
try {
    if (!(Test-Path -LiteralPath $PackageZip -PathType Leaf)) { throw 'Downloaded update ZIP is missing.' }
    New-Item -ItemType Directory -Path $stage -Force | Out-Null
    Expand-Archive -LiteralPath $PackageZip -DestinationPath $stage -Force
    $verify = Join-Path $stage 'verify-package.ps1'
    $install = Join-Path $stage 'install-portable.ps1'
    $app = Join-Path $stage 'Movia'
    if (!(Test-Path -LiteralPath $verify) -or !(Test-Path -LiteralPath $install) -or !(Test-Path -LiteralPath $app)) {
        throw 'The Portable Installed package layout is invalid.'
    }
    & $verify -PackageRoot $stage
    $exe = Join-Path $app 'movia_desktop.exe'
    $hash = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
    Get-Process -Name movia_desktop -ErrorAction SilentlyContinue | Wait-Process -Timeout 30 -ErrorAction SilentlyContinue
    if (Get-Process -Name movia_desktop -ErrorAction SilentlyContinue) { throw 'Movia did not close in time.' }
    & $install -Source $stage -ExpectedExecutableHash $hash -DesktopShortcut -WidgetShortcut
} catch {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        'Windows Smart App Control has not authorized this new Movia version yet. Your previous working version has been restored.',
        'Movia update', 'OK', 'Warning'
    ) | Out-Null
    throw
} finally {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
