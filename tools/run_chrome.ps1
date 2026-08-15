param(
  [int]$Port = 7357,
  [switch]$Debug
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot 'config\app_config.local.json'

if (-not (Test-Path -LiteralPath $configPath)) {
  Write-Error @"
Missing config\app_config.local.json.
Copy config\app_config.example.json to config\app_config.local.json and add
your public Supabase URL and anonymous/publishable key. This local file is
ignored by Git. Never put the service-role key in a Flutter app.
"@
}

$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($config.SUPABASE_URL) -or
    [string]::IsNullOrWhiteSpace($config.SUPABASE_ANON_KEY) -or
    $config.SUPABASE_URL -match 'your-project-id' -or
    $config.SUPABASE_ANON_KEY -match '^your-') {
  Write-Error 'The local Supabase configuration still contains placeholder values.'
}

Set-Location -LiteralPath $projectRoot
$mode = if ($Debug) { 'debug' } else { 'release' }
Write-Host "Starting Future Times in $mode mode at http://localhost:$Port"

$flutterArgs = @('run', '-d', 'chrome')
if (-not $Debug) {
  $flutterArgs += '--release'
}
$flutterArgs += "--web-port=$Port"
$flutterArgs += "--dart-define-from-file=$configPath"

& flutter @flutterArgs
