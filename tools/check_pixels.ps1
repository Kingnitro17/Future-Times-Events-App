Add-Type -AssemblyName System.Drawing

$img = [System.Drawing.Image]::FromFile((Convert-Path "assets/images/androidlogo.png"))
$bmp = New-Object System.Drawing.Bitmap($img)
Write-Host "Corner 0,0: R=$($bmp.GetPixel(0,0).R) G=$($bmp.GetPixel(0,0).G) B=$($bmp.GetPixel(0,0).B) A=$($bmp.GetPixel(0,0).A)"
Write-Host "Quarter 300,300: R=$($bmp.GetPixel(300,300).R) G=$($bmp.GetPixel(300,300).G) B=$($bmp.GetPixel(300,300).B) A=$($bmp.GetPixel(300,300).A)"
$bmp.Dispose()
$img.Dispose()
