$ErrorActionPreference = 'Stop'
$exe = 'C:\Users\DEV\Desktop\Godot_v3.1-stable_win64.exe'
$proj = 'C:\city_demo'
$out = Join-Path $proj 'builds'
if (-not (Test-Path -LiteralPath $out)) { New-Item -ItemType Directory -Path $out | Out-Null }
$apk = Join-Path $out 'city-demo-debug.apk'

Start-Process -FilePath $exe -ArgumentList '--path',$proj,'--export-debug','Android',$apk,'--quit' -WorkingDirectory $proj

$deadline = (Get-Date).AddMinutes(3)
while ((Get-Date) -lt $deadline) {
  Start-Sleep -Seconds 5
  if (Test-Path -LiteralPath $apk) { Write-Host "APK generado: $apk"; exit 0 }
}
Write-Error 'Timeout esperando la generación del APK'
