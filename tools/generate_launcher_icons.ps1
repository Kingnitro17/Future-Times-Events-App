Add-Type -AssemblyName System.Drawing

$projectDir = "c:\Users\User\OneDrive\Desktop\Future Times Events App"
$sourceIcon = Join-Path $projectDir "assets\images\appicon.png"
$resDir = Join-Path $projectDir "android\app\src\main\res"

if (-not (Test-Path $sourceIcon)) {
    throw "Source icon appicon.png not found at $sourceIcon"
}

$srcImg = [System.Drawing.Image]::FromFile($sourceIcon)

# 1. Helper for resizing image cleanly
function Save-ResizedImage ($src, $dest, $width, $height) {
    $bmp = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($src, 0, 0, $width, $height)
    
    $dir = Split-Path -Parent $dest
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $bmp.Save($dest, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Saved: $dest ($width x $height)"
}

# Helper for adaptive foreground (padded so safe zone fills ~78%)
function Save-AdaptiveForeground ($src, $dest, $size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    # Scale icon to fill 78% of the canvas for optimal Samsung One UI fill
    $iconSize = [int]($size * 0.78)
    $offset = [int](($size - $iconSize) / 2)
    $g.DrawImage($src, $offset, $offset, $iconSize, $iconSize)

    $dir = Split-Path -Parent $dest
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $bmp.Save($dest, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Saved Adaptive Foreground: $dest ($size x $size)"
}

$densities = @(
    @{ folder = "mipmap-mdpi"; size = 48; fgSize = 108 },
    @{ folder = "mipmap-hdpi"; size = 72; fgSize = 162 },
    @{ folder = "mipmap-xhdpi"; size = 96; fgSize = 216 },
    @{ folder = "mipmap-xxhdpi"; size = 144; fgSize = 324 },
    @{ folder = "mipmap-xxxhdpi"; size = 192; fgSize = 432 }
)

foreach ($d in $densities) {
    $folderPath = Join-Path $resDir $d.folder
    Save-ResizedImage $srcImg (Join-Path $folderPath "ic_launcher.png") $d.size $d.size
    Save-ResizedImage $srcImg (Join-Path $folderPath "ic_launcher_round.png") $d.size $d.size
    Save-AdaptiveForeground $srcImg (Join-Path $folderPath "ic_launcher_foreground.png") $d.fgSize
}

$srcImg.Dispose()

# 2. Add ic_launcher_background color resource in values/colors.xml
$valuesDir = Join-Path $resDir "values"
if (-not (Test-Path $valuesDir)) { New-Item -ItemType Directory -Path $valuesDir -Force | Out-Null }
$colorsXml = @"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#160833</color>
    <color name="splash_background">#F7F7FA</color>
</resources>
"@
Set-Content -Path (Join-Path $valuesDir "colors.xml") -Value $colorsXml -Encoding UTF8

# 3. Add adaptive icon XML in mipmap-anydpi-v26
$anyDpiDir = Join-Path $resDir "mipmap-anydpi-v26"
if (-not (Test-Path $anyDpiDir)) { New-Item -ItemType Directory -Path $anyDpiDir -Force | Out-Null }

$adaptiveXml = @"
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />
</adaptive-icon>
"@
Set-Content -Path (Join-Path $anyDpiDir "ic_launcher.xml") -Value $adaptiveXml -Encoding UTF8
Set-Content -Path (Join-Path $anyDpiDir "ic_launcher_round.xml") -Value $adaptiveXml -Encoding UTF8

Write-Host "Android launcher icons generated successfully!"
