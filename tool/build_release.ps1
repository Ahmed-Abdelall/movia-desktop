param(
  [switch]$SkipTests,
  [string]$FlutterCommand = 'flutter',
  [string]$InnoSetupCompiler = ''
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$flutter = (Get-Command $FlutterCommand -ErrorAction Stop).Source
$iscc = if ($InnoSetupCompiler) {
  (Resolve-Path $InnoSetupCompiler).Path
} else {
  "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
}
$commit = (git -C $root rev-parse HEAD).Trim()
$stamp = (Get-Date).ToUniversalTime().ToString('o')
$staging = Join-Path $root 'staging\windows-release'
$release = Join-Path $root 'release'
$portableStage = Join-Path $root 'staging\portable'
$portableInstalledStage = Join-Path $root 'staging\portable-installed'
if (Test-Path $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
if (Test-Path $portableStage) { Remove-Item -LiteralPath $portableStage -Recurse -Force }
if (Test-Path $portableInstalledStage) { Remove-Item -LiteralPath $portableInstalledStage -Recurse -Force }
Get-ChildItem -LiteralPath $release -Filter 'Movia-Desktop-*1.2.0*' -ErrorAction SilentlyContinue | Remove-Item -Force
& $flutter clean
& $flutter pub get
& $flutter analyze
if (-not $SkipTests) { & $flutter test }
& $flutter build windows --release --dart-define=MOVIA_COMMIT=$commit --dart-define=MOVIA_BUILD_TIME=$stamp --dart-define=MOVIA_BUILD_TYPE=release
$built = Join-Path $root 'build\windows\x64\runner\Release'
New-Item -ItemType Directory -Path $staging -Force | Out-Null
Copy-Item -Path "$built\*" -Destination $staging -Recurse -Force
Copy-Item -LiteralPath (Join-Path $root 'scripts\update-portable.ps1') -Destination $staging -Force
@{version='1.2.0';commit=$commit;buildTimestamp=$stamp;buildType='release'} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $staging 'build-info.json') -Encoding utf8
& $iscc (Join-Path $root 'installer\movia-desktop.iss')
New-Item -ItemType Directory -Path $portableStage -Force | Out-Null
Copy-Item -Path "$staging\*" -Destination $portableStage -Recurse -Force
$zip = Join-Path $release 'Movia-Desktop-1.2.0-portable.zip'
tar.exe -a -c -f $zip -C $portableStage .
$portableInstalledZip = Join-Path $release 'Movia-Desktop-1.2.0-portable-installed.zip'
New-Item -ItemType Directory -Path (Join-Path $portableInstalledStage 'Movia') -Force | Out-Null
Copy-Item -Path "$staging\*" -Destination (Join-Path $portableInstalledStage 'Movia') -Recurse -Force
Copy-Item -LiteralPath (Join-Path $root 'scripts\install-portable.ps1'),(Join-Path $root 'scripts\uninstall-portable.ps1'),(Join-Path $root 'scripts\verify-package.ps1'),(Join-Path $root 'scripts\update-portable.ps1'),(Join-Path $root 'README-INSTALL.txt') -Destination $portableInstalledStage
$manifest = Join-Path $portableInstalledStage 'SHA256SUMS.txt'
$lines = Get-ChildItem -LiteralPath $portableInstalledStage -Recurse -File | Sort-Object FullName | ForEach-Object {
  $relative = $_.FullName.Substring($portableInstalledStage.Length + 1).Replace('\','/')
  "$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash) *$relative"
}
$lines | Set-Content -LiteralPath $manifest -Encoding ascii
tar.exe -a -c -f $portableInstalledZip -C $portableInstalledStage .
$installer = Join-Path $release 'Movia-Desktop-Setup-1.2.0.exe'
foreach ($artifact in @($installer,$zip,$portableInstalledZip)) {
  $hash=(Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToLowerInvariant()
  "$hash  $([IO.Path]::GetFileName($artifact))" | Set-Content -LiteralPath "$artifact.sha256" -Encoding ascii
}
Get-Item $installer,$zip,$portableInstalledZip | Select-Object FullName,Length,LastWriteTime
