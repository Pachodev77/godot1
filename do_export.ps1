$ErrorActionPreference = 'Stop'
$exe = 'C:\Users\DEV\Desktop\Godot_v3.1-stable_win64.exe'
$proj = 'C:\Users\DEV\Desktop\city demo'
$apk = Join-Path $proj 'builds\city-demo-debug.apk'
if (!(Test-Path -LiteralPath (Split-Path $apk -Parent))) { New-Item -ItemType Directory -Path (Split-Path $apk -Parent) | Out-Null }
Start-Process -FilePath $exe -ArgumentList '--path',$proj,'--export-debug','Android',$apk,'--quit' -WorkingDirectory $proj -Wait
if (Test-Path -LiteralPath $apk) { Write-Host "APK listo: $apk" } else { Write-Error 'APK no generado' }
