$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (!(Test-Path -LiteralPath 'C:\Android')) { New-Item -ItemType Directory -Path 'C:\Android' | Out-Null }
$zip = 'C:\Android\platform-tools.zip'
$url = 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip'
[void](Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue)
try {
  Start-BitsTransfer -Source $url -Destination $zip -ErrorAction Stop
} catch {
  Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip
}
[Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
if (Test-Path -LiteralPath 'C:\Android\platform-tools') { Remove-Item -Recurse -Force 'C:\Android\platform-tools' }
[System.IO.Compression.ZipFile]::ExtractToDirectory($zip, 'C:\Android')
if (Test-Path -LiteralPath 'C:\Android\platform-tools\adb.exe') { Write-Host 'ADB OK' } else { Write-Error 'ADB missing' }
