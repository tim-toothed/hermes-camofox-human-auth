param(
  [ValidateSet('headless','headed')]
  [string]$DisplayMode = 'headless'
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Vendor = Join-Path $Root 'vendor/camofox-browser'
if (-not (Test-Path (Join-Path $Vendor 'package.json'))) {
  throw 'Native Camofox is not installed. Run .\scripts\install-native.ps1 first.'
}

$env:CAMOFOX_DISPLAY_MODE = $DisplayMode
$env:CAMOFOX_PROFILE_DIR = Join-Path $Root 'data/profiles'
if (-not $env:CAMOFOX_WINDOW_WIDTH) { $env:CAMOFOX_WINDOW_WIDTH = '1280' }
if (-not $env:CAMOFOX_WINDOW_HEIGHT) { $env:CAMOFOX_WINDOW_HEIGHT = '720' }
if (-not $env:CAMOFOX_HUMAN_AUTH_ADMIN_KEY) {
  $envPath = (& hermes config env-path).Trim()
  if (Test-Path $envPath) {
    $adminLine = Get-Content $envPath | Where-Object { $_ -match '^CAMOFOX_HUMAN_AUTH_ADMIN_KEY=' } | Select-Object -First 1
    if ($adminLine) { $env:CAMOFOX_HUMAN_AUTH_ADMIN_KEY = $adminLine -replace '^CAMOFOX_HUMAN_AUTH_ADMIN_KEY=', '' }
  }
}
$env:CAMOFOX_ADMIN_KEY = $env:CAMOFOX_HUMAN_AUTH_ADMIN_KEY
$env:PORT = '9377'

Write-Host "Starting native Camofox in $DisplayMode mode on http://127.0.0.1:9377"
Write-Host 'Press Ctrl+C to stop it.'
Push-Location $Vendor
try {
  & npm.cmd start
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
  Pop-Location
}
