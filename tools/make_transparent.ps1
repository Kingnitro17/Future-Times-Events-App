Add-Type -AssemblyName System.Drawing

function Make-Transparent ($inputPath, $outputPath) {
    if (-not (Test-Path $inputPath)) { Write-Host "File not found: $inputPath"; return }
    $img = [System.Drawing.Image]::FromFile((Convert-Path $inputPath))
    $width = $img.Width
    $height = $img.Height
    
    # Create 32bppARGB bitmap
    $bmp = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.DrawImage($img, 0, 0, $width, $height)
    $g.Dispose()
    $img.Dispose()

    # Make black pixels outside the rounded crest transparent
    # Find distance from corners or black threshold (R < 15, G < 15, B < 15)
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            $pixel = $bmp.GetPixel($x, $y)
            # If near-black outer border (R < 12, G < 12, B < 12)
            if ($pixel.R -lt 12 -and $pixel.G -lt 12 -and $pixel.B -lt 12) {
                # Check if it's outside the main central logo area or near corners
                $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            }
        }
    }

    $bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Processed $inputPath -> $outputPath (Transparent outer border)"
}

Make-Transparent "assets/images/androidlogo.png" "assets/images/androidlogo_clean.png"
Make-Transparent "assets/images/appicon.png" "assets/images/appicon_clean.png"
