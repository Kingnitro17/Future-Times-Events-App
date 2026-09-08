param([switch]$Release)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot 'config\app_config.local.json'
if (-not (Test-Path -LiteralPath $configPath)) {
  throw 'Missing config\app_config.local.json.'
}

$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$expectedProjectId = 'ecbbmcqwluivbzlaqdsd'
$configuredUrl = [string]$config.SUPABASE_URL
$validUrl = $configuredUrl -eq $expectedProjectId -or
  $configuredUrl -eq "https://$expectedProjectId.supabase.co"
if (-not $validUrl -or
    [string]::IsNullOrWhiteSpace([string]$config.SUPABASE_ANON_KEY) -or
    [string]$config.SUPABASE_ANON_KEY -match '^your-') {
  throw 'The local Supabase configuration is invalid.'
}

Set-Location -LiteralPath $projectRoot
$mode = if ($Release) { 'release' } else { 'debug' }
$logPath = Join-Path $projectRoot 'build\configured-android-build.log'
& flutter build apk "--$mode" "--dart-define-from-file=config/app_config.local.json" *> $logPath
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
  Get-Content -LiteralPath $logPath -Tail 40
  throw "Configured Android $mode build failed."
}
Remove-Item -LiteralPath $logPath -Force
$apkPath = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-$mode.apk"
Write-Host "Configured Android $mode APK built: $apkPath"
