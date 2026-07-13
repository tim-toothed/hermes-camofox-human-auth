param(
  [string]$CamofoxRef = 'master',
  [switch]$SkipHermesConfig
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

foreach ($command in @('git', 'node', 'npm')) {
  if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
    throw "$command is required. Install Node.js and Git first."
  }
}
if (-not (Get-Command hermes -ErrorAction SilentlyContinue)) {
  throw 'Hermes is required and must be available as hermes.'
}

$Vendor = Join-Path $Root 'vendor/camofox-browser'
if (-not (Test-Path (Join-Path $Vendor '.git'))) {
  New-Item -ItemType Directory -Force (Split-Path $Vendor) | Out-Null
  git clone --depth 1 --branch master https://github.com/jo-inc/camofox-browser.git $Vendor
}

Push-Location $Vendor
try {
  git fetch --depth 1 origin master
  if ($CamofoxRef -eq 'master') {
    git checkout --detach origin/master
  } else {
    git fetch --depth 1 origin $CamofoxRef
    git checkout --detach $CamofoxRef
  }
  git reset --hard HEAD
  $Patch = Join-Path $Root 'patches/server-native-headed.patch'
  git apply --check --ignore-space-change --ignore-whitespace $Patch
  git apply --ignore-space-change --ignore-whitespace $Patch
  npm install
} finally {
  Pop-Location
}

$envPath = (& hermes config env-path).Trim()
$envDir = Split-Path -Parent $envPath
New-Item -ItemType Directory -Force $envDir | Out-Null
$lines = if (Test-Path $envPath) { @(Get-Content $envPath) } else { @() }
$adminKeyLine = $lines | Where-Object { $_ -match '^CAMOFOX_HUMAN_AUTH_ADMIN_KEY=' } | Select-Object -First 1
$adminKey = if ($adminKeyLine) { $adminKeyLine -replace '^CAMOFOX_HUMAN_AUTH_ADMIN_KEY=', '' } else { [guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N') }
$set = @{
  CAMOFOX_HUMAN_AUTH_BACKEND = 'native'
  CAMOFOX_HUMAN_AUTH_URL = 'http://127.0.0.1:9377'
  CAMOFOX_HUMAN_AUTH_USER_ID = 'hermes'
  CAMOFOX_HUMAN_AUTH_SESSION_KEY = 'native-auth'
  CAMOFOX_HUMAN_AUTH_DISPLAY_MODE = 'headless'
  CAMOFOX_HUMAN_AUTH_PROFILE_DIR = (Join-Path $Root 'data/profiles')
  CAMOFOX_HUMAN_AUTH_ADMIN_KEY = $adminKey
}
foreach ($key in $set.Keys) {
  $lines = @($lines | Where-Object { $_ -notmatch "^$key=" })
  $lines += "$key=$($set[$key])"
}
Set-Content -Path $envPath -Value $lines -Encoding utf8

Write-Host "Native Camofox installed in $Vendor"
Write-Host "Hermes env configured at $envPath"
Write-Host "Run .\scripts\start-native.ps1 -DisplayMode headless"
