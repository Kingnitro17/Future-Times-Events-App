Add-Type -AssemblyName System.Drawing

function Check-Img ($path) {
    if (-not (Test-Path $path)) { Write-Host "$path does not exist"; return }
    $img = [System.Drawing.Image]::FromFile((Convert-Path $path))
    Write-Host "$path : $($img.Width) x $($img.Height), PixelFormat: $($img.PixelFormat)"
    $bmp = New-Object System.Drawing.Bitmap($img)
    $topLeft = $bmp.GetPixel(0, 0)
    $center = $bmp.GetPixel([int]($img.Width/2), [int]($img.Height/2))
    Write-Host "  TopLeft Pixel ARGB: Alpha=$($topLeft.A), R=$($topLeft.R), G=$($topLeft.G), B=$($topLeft.B)"
    Write-Host "  Center Pixel ARGB: Alpha=$($center.A), R=$($center.R), G=$($center.G), B=$($center.B)"
    $bmp.Dispose()
    $img.Dispose()
}

Check-Img "appicon.png"
Check-Img "assets/images/appicon.png"
