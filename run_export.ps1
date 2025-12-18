$ErrorActionPreference = 'Stop'

function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Err($msg) { Write-Host "[ERR]  $msg" -ForegroundColor Red }

$desktop = 'C:\Users\DEV\Desktop'
$exeCandidates = @(
  (Join-Path $desktop 'Godot_v3.1-stable_win64.exe'),
  (Join-Path $desktop 'Godot_v3.1-stable_win32.exe'),
  (Join-Path $desktop 'Godot.exe'),
  (Join-Path $desktop 'godot.exe')
)

$exePath = $null
foreach ($p in $exeCandidates) { if (Test-Path -LiteralPath $p) { $exePath = $p; break } }

if (-not $exePath) {
  Write-Info "Buscando ejecutable en $desktop..."
  $found = Get-ChildItem -LiteralPath $desktop -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'godot.*\.exe' } | Select-Object -ExpandProperty FullName -First 1
  if ($found) { $exePath = $found }
}

if (-not $exePath) { Write-Err 'No encontré el ejecutable de Godot en tu Escritorio.'; exit 1 }
Write-Ok "Usando ejecutable: $exePath"

$projRoot = (Get-Location).Path
$buildOut = Join-Path $projRoot 'builds'
if (-not (Test-Path -LiteralPath $buildOut)) { New-Item -ItemType Directory -Path $buildOut | Out-Null }

$apkPath = Join-Path $buildOut 'city-demo-debug.apk'

Write-Info 'Exportando APK (debug)...'
& $exePath --path $projRoot --export-debug 'Android' $apkPath --quit

if (Test-Path -LiteralPath $apkPath) {
  Write-Ok "APK generado: $apkPath"
} else {
  Write-Err 'La exportación no generó el APK esperado.'
  exit 1
}
