$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$os = if ($env:OS -eq 'Windows_NT') { 'Windows' } else { 'Unknown' }
Write-Host "Detected OS: $os"
Write-Host ''
Write-Host 'Choose Camofox backend:'
Write-Host '1. Local: Native headed/headless'
Write-Host '2. VPS/Server: Docker + noVNC'
$choice = Read-Host 'Select [1/2]'
if ($choice -notin @('1', '2')) { throw 'Choose 1 or 2.' }

$backend = if ($choice -eq '1') { 'native' } else { 'docker' }
$backendUrl = if ($backend -eq 'native') { 'http://127.0.0.1:9377' } else { 'http://127.0.0.1:9378' }
$envPath = (& hermes config env-path).Trim()
$envDir = Split-Path -Parent $envPath
New-Item -ItemType Directory -Force $envDir | Out-Null
$lines = if (Test-Path $envPath) { @(Get-Content $envPath) } else { @() }
$lines = @($lines | Where-Object { $_ -notmatch '^CAMOFOX_HUMAN_AUTH_BACKEND=' })
$lines += "CAMOFOX_HUMAN_AUTH_BACKEND=$backend"
Set-Content -Path $envPath -Value $lines -Encoding utf8

if ($backend -eq 'native') {
  & (Join-Path $PSScriptRoot 'install-native.ps1')
} else {
  & (Join-Path $PSScriptRoot 'install.ps1')
}

# Configure the normal Hermes browser only after explicit user consent.
$configPath = (& hermes config path).Trim()
$provider = ''
if (Test-Path $configPath) {
  $match = Select-String -Path $configPath -Pattern '^\s*cloud_provider:\s*([^\s#]+)' | Select-Object -First 1
  if ($match) { $provider = $match.Matches[0].Groups[1].Value.ToLowerInvariant() }
}
$existingUrlLine = Get-Content $envPath | Where-Object { $_ -match '^CAMOFOX_URL=' } | Select-Object -First 1
$hasCamofoxUrl = [bool]($existingUrlLine -and (($existingUrlLine -replace '^CAMOFOX_URL=', '').Trim()))

function Set-EnvValue([string]$Key, [string]$Value) {
  $script:lines = @($script:lines | Where-Object { $_ -notmatch "^$Key=" })
  $script:lines += "$Key=$Value"
  Set-Content -Path $script:envPath -Value $script:lines -Encoding utf8
}

if (-not $provider -and -not $hasCamofoxUrl) {
  Write-Host ''
  Write-Host 'No Hermes browser provider is configured.' -ForegroundColor Yellow
  $answer = Read-Host 'Configure Hermes browser provider to Camofox now? [y/N]'
  if ($answer -match '^(y|yes)$') {
    & hermes config set browser.cloud_provider camofox
    Set-EnvValue 'CAMOFOX_URL' $backendUrl
    Write-Host 'Hermes browser provider configured: Camofox'
  } else {
    Write-Host 'Camofox backend installed, but Hermes browser provider was left unchanged.' -ForegroundColor Yellow
  }
} elseif ($provider -and $provider -ne 'camofox' -and -not $hasCamofoxUrl) {
  Write-Host ''
  Write-Host "Hermes currently uses browser provider '$provider'." -ForegroundColor Yellow
  $answer = Read-Host 'Switch Hermes browser provider to Camofox now? [y/N]'
  if ($answer -match '^(y|yes)$') {
    & hermes config set browser.cloud_provider camofox
    Set-EnvValue 'CAMOFOX_URL' $backendUrl
    Write-Host 'Hermes browser provider switched to Camofox.'
  } else {
    Write-Host 'Existing browser provider preserved; Camofox Human Auth remains separately installed.' -ForegroundColor Yellow
  }
} elseif ($provider -eq 'camofox' -and -not $hasCamofoxUrl) {
  Write-Host 'Hermes is configured for Camofox but CAMOFOX_URL is missing.' -ForegroundColor Yellow
  $answer = Read-Host "Set CAMOFOX_URL to $backendUrl now? [y/N]"
  if ($answer -match '^(y|yes)$') { Set-EnvValue 'CAMOFOX_URL' $backendUrl }
}

Write-Host "Camofox backend selected: $backend"
Write-Host 'Restart Hermes after setup so it loads the selected backend.'
