param(
  [string]$SourcePath = "C:\Users\User\OneDrive\Desktop\Future Times Events App\androidlogo.png",
  [string]$ProjectDir = "C:\Users\User\OneDrive\Desktop\Future Times Events App"
)

Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $SourcePath)) {
  throw "Source image not found at $SourcePath"
}

# 1. Copy to assets/images/androidlogo.png
$assetsDir = Join-Path $ProjectDir "assets\images"
if (-not (Test-Path $assetsDir)) {
  New-Item -ItemType Directory -Path $assetsDir -Force | Out-Null
}
$targetAsset = Join-Path $assetsDir "androidlogo.png"
Copy-Item -Path $SourcePath -Destination $targetAsset -Force
Write-Host "Copied logo to $targetAsset"

# Helper to resize and save image
function Resize-Image {
  param(
    [string]$Src,
    [string]$Dest,
    [int]$Width,
    [int]$Height
  )
  $srcImg = [System.Drawing.Image]::FromFile($Src)
  $bmp = New-Object System.Drawing.Bitmap($Width, $Height)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.DrawImage($srcImg, 0, 0, $Width, $Height)
  
  $destDir = Split-Path -Parent $Dest
  if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
  }
  
  # Ensure file is written
  $bmp.Save($Dest, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose()
  $bmp.Dispose()
  $srcImg.Dispose()
  Write-Host "Resized and saved: $Dest ($Width x $Height)"
}

# 2. Android mipmap densities
$resDir = Join-Path $ProjectDir "android\app\src\main\res"
Resize-Image -Src $SourcePath -Dest (Join-Path $resDir "mipmap-mdpi\ic_launcher.png") -Width 48 -Height 48
Resize-Image -Src $SourcePath -Dest (Join-Path $resDir "mipmap-hdpi\ic_launcher.png") -Width 72 -Height 72
Resize-Image -Src $SourcePath -Dest (Join-Path $resDir "mipmap-xhdpi\ic_launcher.png") -Width 96 -Height 96
Resize-Image -Src $SourcePath -Dest (Join-Path $resDir "mipmap-xxhdpi\ic_launcher.png") -Width 144 -Height 144
Resize-Image -Src $SourcePath -Dest (Join-Path $resDir "mipmap-xxxhdpi\ic_launcher.png") -Width 192 -Height 192

# 3. Web icons
$webDir = Join-Path $ProjectDir "web"
Resize-Image -Src $SourcePath -Dest (Join-Path $webDir "favicon.png") -Width 32 -Height 32
Resize-Image -Src $SourcePath -Dest (Join-Path $webDir "icons\Icon-192.png") -Width 192 -Height 192
Resize-Image -Src $SourcePath -Dest (Join-Path $webDir "icons\Icon-512.png") -Width 512 -Height 512
Resize-Image -Src $SourcePath -Dest (Join-Path $webDir "icons\Icon-Maskable-192.png") -Width 192 -Height 192
Resize-Image -Src $SourcePath -Dest (Join-Path $webDir "icons\Icon-Maskable-512.png") -Width 512 -Height 512

Write-Host "App logo integration completed successfully!"
