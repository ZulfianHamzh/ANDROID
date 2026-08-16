# Optimize DHBH POS logo: 2048x2048 (4MB) -> 256x256 (high quality, alpha preserved)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$srcPath = 'I:\Projek\ANDROID\lib\assets\logo-dhbh.png'
$bakDir  = 'I:\Projek\ANDROID\build\logo-backup'
$bakPath = Join-Path $bakDir 'logo-dhbh-2048.png'
$outPath = 'I:\Projek\ANDROID\lib\assets\logo-dhbh.png'

# 1. Backup original
New-Item -ItemType Directory -Force -Path $bakDir | Out-Null
Copy-Item -Path $srcPath -Destination $bakPath -Force
Write-Output ("Backup: " + $bakPath + " (" + (Get-Item $bakPath).Length + " bytes)")

# 2. Load source
$src = [System.Drawing.Image]::FromFile($bakPath)
Write-Output ("Source: " + $src.Width + "x" + $src.Height + " " + $src.PixelFormat)

# 3. Create resized bitmap (32bpp ARGB to preserve alpha)
$size = 256
$bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::Transparent)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$g.DrawImage($src, 0, 0, $size, $size)
$g.Dispose()

# 4. Save optimized PNG (compressed)
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
$src.Dispose()

Write-Output ("Optimized: " + $outPath + " (" + (Get-Item $outPath).Length + " bytes)")

# 5. Verify result
$check = [System.Drawing.Image]::FromFile($outPath)
Write-Output ("Result: " + $check.Width + "x" + $check.Height + " " + $check.PixelFormat)
$check.Dispose()
