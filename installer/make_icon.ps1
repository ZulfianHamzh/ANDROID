# Generate a DHBH-branded multi-size Windows .ico from the optimized logo (256x256 PNG).
# Sizes: 16, 24, 32, 48, 64, 128, 256 — all PNG-compressed entries (supported by Windows Vista+).
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$logoPath = 'I:\Projek\ANDROID\lib\assets\logo-dhbh.png'
$icoPath  = 'I:\Projek\ANDROID\windows\runner\resources\app_icon.ico'

$src = [System.Drawing.Image]::FromFile($logoPath)

function Get-PngBytes($size) {
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
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $bytes = $ms.ToArray()
    $ms.Dispose()
    $bmp.Dispose()
    return ,$bytes   # comma prevents PowerShell array unrolling
}

$sizes = @(16, 24, 32, 48, 64, 128, 256)
$pngs = @{}
foreach ($s in $sizes) { $pngs[$s] = Get-PngBytes $s }

$count = $sizes.Count
$headerLen = 6
$entryLen = 16
$dataStart = $headerLen + ($entryLen * $count)
$total = $dataStart
foreach ($s in $sizes) { $total += $pngs[$s].Length }

$stream = New-Object System.IO.FileStream($icoPath, [System.IO.FileMode]::Create)
$bw = New-Object System.IO.BinaryWriter($stream)

# ICONDIR
$bw.Write([UInt16]0)          # reserved
$bw.Write([UInt16]1)          # type = icon
$bw.Write([UInt16]$count)     # number of images

# ICONDIRENTRY + data
$offset = $dataStart
foreach ($s in $sizes) {
    $dim = if ($s -ge 256) { 0 } else { $s }   # 0 means 256
    $bw.Write([Byte]$dim)      # width
    $bw.Write([Byte]$dim)      # height
    $bw.Write([Byte]0)         # color count
    $bw.Write([Byte]0)         # reserved
    $bw.Write([UInt16]1)       # planes
    $bw.Write([UInt16]32)      # bit count
    $bw.Write([UInt32]$pngs[$s].Length)  # bytes in resource
    $bw.Write([UInt32]$offset) # image offset
    $offset += $pngs[$s].Length
}
foreach ($s in $sizes) { $bw.Write([byte[]]$pngs[$s]) }

$bw.Flush()
$bw.Close()
$stream.Close()
$src.Dispose()

Write-Output ("ICO written: " + $icoPath + " (" + (Get-Item $icoPath).Length + " bytes)")

# Validate by reloading as an Icon
$icon = New-Object System.Drawing.Icon($icoPath)
Write-Output ("Icon loaded OK: " + $icon.Width + "x" + $icon.Height)
$icon.Dispose()
