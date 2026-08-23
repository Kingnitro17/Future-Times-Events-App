Add-Type -AssemblyName System.Drawing

$projectDir = "c:\Users\User\OneDrive\Desktop\Future Times Events App"
$sourceLogo = Join-Path $projectDir "assets\images\androidlogo.png"
$resDir = Join-Path $projectDir "android\app\src\main\res"

$srcImg = [System.Drawing.Image]::FromFile($sourceLogo)

function Save-SplashLogo ($src, $dest, $width, $height) {
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
    Write-Host "Saved Splash Logo: $dest ($width x $height)"
}

$splashSizes = @(
    @{ folder = "drawable"; width = 120; height = 120 },
    @{ folder = "drawable-hdpi"; width = 160; height = 160 },
    @{ folder = "drawable-xhdpi"; width = 240; height = 240 },
    @{ folder = "drawable-xxhdpi"; width = 320; height = 320 },
    @{ folder = "drawable-xxxhdpi"; width = 480; height = 480 }
)

foreach ($s in $splashSizes) {
    $dest = Join-Path (Join-Path $resDir $s.folder) "splash_logo.png"
    Save-SplashLogo $srcImg $dest $s.width $s.height
}

$srcImg.Dispose()
Write-Host "Splash logo assets generated!"
