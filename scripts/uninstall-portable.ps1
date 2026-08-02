[CmdletBinding(SupportsShouldProcess)]
param([switch]$DeleteUserData)
$ErrorActionPreference = 'Stop'
$installRoot = Join-Path $env:LOCALAPPDATA 'Programs\Movia'
$shortcuts = @(
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Movia Desktop.lnk'),
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Movia Desktop Widget.lnk'),
    (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Movia Desktop.lnk'
    )
)
Get-Process -Name 'movia_desktop' -ErrorAction SilentlyContinue | ForEach-Object { [void]$_.CloseMainWindow() }
Get-Process -Name 'movia_desktop' -ErrorAction SilentlyContinue | Wait-Process -Timeout 15 -ErrorAction SilentlyContinue
if (Get-Process -Name 'movia_desktop' -ErrorAction SilentlyContinue) { throw 'Movia is still running.' }
if ($PSCmdlet.ShouldProcess($installRoot, 'Remove Movia application binaries')) {
    if (Test-Path -LiteralPath $installRoot) { Remove-Item -LiteralPath $installRoot -Recurse -Force }
    foreach ($shortcut in $shortcuts) { Remove-Item -LiteralPath $shortcut -Force -ErrorAction SilentlyContinue }
}
if ($DeleteUserData) {
    $confirmation = Read-Host 'Type DELETE MOVIA DATA to permanently remove Movia databases and preferences'
    if ($confirmation -ceq 'DELETE MOVIA DATA') {
        foreach ($path in @(
            (Join-Path $env:APPDATA 'Ahmed Abdelaal\Movia Desktop'),
            (Join-Path $env:APPDATA 'com.movia\movia_desktop')
        )) {
            if ($PSCmdlet.ShouldProcess($path, 'Permanently remove user data')) { Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue }
        }
    } else { Write-Output 'User data retained.' }
} else { Write-Output 'User data retained (default).' }
