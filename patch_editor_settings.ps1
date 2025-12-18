$ErrorActionPreference = 'Stop'
$f = Join-Path $env:APPDATA 'Godot\editor_settings-3.tres'
if (-not (Test-Path -LiteralPath $f)) { throw 'editor_settings-3.tres not found' }
$lines = Get-Content -LiteralPath $f

function SetKV([string]$key, [string]$value) {
  $pattern = '^' + [regex]::Escape($key) + '\s*=\s*.*$'
  $repl = $key + ' = "' + $value + '"'
  $idx = -1
  for ($i = 0; $i -lt $lines.Length; $i++) {
    if ([regex]::IsMatch($lines[$i], $pattern)) { $idx = $i; break }
  }
  if ($idx -ge 0) { $lines[$idx] = $repl } else { $lines += $repl }
}

Add-Type -AssemblyName System.Core
SetKV 'export/android/adb' 'C:/Android/platform-tools/adb.exe'
SetKV 'export/android/jarsigner' 'C:/Program Files/Android/Android Studio/jbr/bin/jarsigner.exe'
SetKV 'export/android/debug_keystore' 'C:/Android/debug.keystore'
SetKV 'export/android/debug_keystore_user' 'androiddebugkey'
SetKV 'export/android/debug_keystore_pass' 'android'
SetKV 'export/android/sdk_path' 'C:/Android'
SetKV 'export/android/zipalign' 'C:/Android/build-tools/28.0.3/zipalign.exe'
SetKV 'export/android/apksigner' 'C:/Android/build-tools/28.0.3/apksigner.bat'
SetKV 'export/android/ndk_path' 'C:/Android/ndk/r19c'

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($f, $lines, $utf8NoBom)
Write-Host 'Updated editor_settings-3.tres'
