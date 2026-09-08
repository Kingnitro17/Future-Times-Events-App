param(
  [string]$Device,
  [switch]$Release
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot 'config\app_config.local.json'

if (-not (Test-Path -LiteralPath $configPath)) {
  throw 'Missing config\app_config.local.json. Copy config\app_config.example.json and add the public Supabase configuration.'
}

$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$expectedProjectId = 'ecbbmcqwluivbzlaqdsd'
$configuredUrl = [string]$config.SUPABASE_URL
$validUrl = $configuredUrl -eq $expectedProjectId -or
  $configuredUrl -eq "https://$expectedProjectId.supabase.co"
if (-not $validUrl -or
    [string]::IsNullOrWhiteSpace([string]$config.SUPABASE_ANON_KEY) -or
    [string]$config.SUPABASE_ANON_KEY -match '^your-') {
  throw 'The local Supabase configuration is missing, uses placeholders, or targets the wrong project.'
}

Set-Location -LiteralPath $projectRoot
$flutterArgs = @('run')
if (-not [string]::IsNullOrWhiteSpace($Device)) {
  $flutterArgs += @('-d', $Device)
}
if ($Release) {
  $flutterArgs += '--release'
}
$flutterArgs += "--dart-define-from-file=config/app_config.local.json"

& flutter @flutterArgs
