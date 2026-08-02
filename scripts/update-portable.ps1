[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ExtractedRelease,
    [Parameter(Mandatory = $true)][string]$ExpectedExecutableHash
)
$ErrorActionPreference = 'Stop'
$installer = Join-Path $PSScriptRoot 'install-portable.ps1'
try {
    & $installer -Source $ExtractedRelease -ExpectedExecutableHash $ExpectedExecutableHash -DesktopShortcut -WidgetShortcut
} catch {
    Write-Error 'Windows Smart App Control may not have authorized this new Movia version yet. Your previous working version has been restored.'
    Write-Error $_
    exit 1
}
