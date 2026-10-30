# Generates temporary placeholder artwork for the Nottia splash screen.
# Replace the PNG files in assets/images/ with the final exports from Figma.
# Canvas sizes are generous so the images stay crisp on high-DPI phones.

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$images = Join-Path $root "assets\images"
$stars = Join-Path $images "stars"
New-Item -ItemType Directory -Force -Path $stars | Out-Null

function New-Canvas([int]$w, [int]$h) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    return @($bmp, $g)
}

function New-PathStar([single]$cx, [single]$cy, [single]$outer, [single]$inner, [int]$points, [single]$rotation = -90) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $pts = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    for ($i = 0; $i -lt ($points * 2); $i++) {
        $r = if ($i % 2 -eq 0) { $outer } else { $inner }
        $a = [math]::PI * 2 * $i / ($points * 2) + ($rotation * [math]::PI / 180)
        $pts.Add([System.Drawing.PointF]::new($cx + [single]($r * [math]::Cos($a)), $cy + [single]($r * [math]::Sin($a))))
    }
    $path.AddPolygon($pts.ToArray())
    return $path
}

function Save-Png($bmp, $g, [string]$path) {
    $g.Dispose()
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

# ---------------------------------------------------------------- logo placeholder
# 512 x 512. Displayed at ~148 pt wide in the splash screen.
$bmp, $g = New-Canvas 512 512
$glow = [System.Drawing.Color]::FromArgb(70, 165, 175, 255)
for ($i = 14; $i -ge 1; $i--) {
    $alpha = [int](70 * (1 - ($i / 15.0)) / 3)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 150, 160, 245))
    $g.FillEllipse($brush, 256 - (118 + $i * 5), 256 - (118 + $i * 5), (118 + $i * 5) * 2, (118 + $i * 5) * 2)
    $brush.Dispose()
}
$ring = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(170, 230, 226, 205), 2)
$g.DrawEllipse($ring, 86, 86, 340, 340)
$ring.Dispose()

$moonBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.PointF]::new(180, 130),
    [System.Drawing.PointF]::new(410, 390),
    [System.Drawing.Color]::FromArgb(255, 255, 250, 232),
    [System.Drawing.Color]::FromArgb(255, 214, 197, 150))
$g.FillEllipse($moonBrush, 163, 140, 228, 228)
$moonBrush.Dispose()
# Carve the crescent.
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$cut = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Transparent)
$g.FillEllipse($cut, 251, 112, 228, 228)
$cut.Dispose()
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
# Soft inner rim on the crescent.
$rim = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(120, 255, 252, 236), 3)
$g.DrawArc($rim, 169, 146, 216, 216, 105, 150)
$rim.Dispose()
$dot = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 245, 240, 219))
$g.FillEllipse($dot, 350, 118, 10, 10)
$g.FillEllipse($dot, 96, 342, 7, 7)
$dot.Dispose()
Save-Png $bmp $g (Join-Path $images "logo_nottia.png")

# ---------------------------------------------------------------- half moon (bottom)
# 1200 x 1200 canvas, orb occupies the middle. The splash shows the top half only.
$bmp, $g = New-Canvas 1200 1200
$orb = 920.0
$cx = 600.0
$cy = 640.0
# Outer atmospheric glow: one smooth radial falloff instead of stacked rings.
$glowPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$glowRadius = 650.0
$glowPath.AddEllipse($cx - $glowRadius, $cy - $glowRadius, $glowRadius * 2, $glowRadius * 2)
$glowBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($glowPath)
$glowBrush.CenterPoint = [System.Drawing.PointF]::new($cx, $cy)
$glowBrush.CenterColor = [System.Drawing.Color]::FromArgb(105, 238, 225, 185)
$glowBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 238, 225, 185))
$g.FillPath($glowBrush, $glowPath)
$glowBrush.Dispose()
$glowPath.Dispose()
$moonPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$moonPath.AddEllipse($cx - $orb / 2, $cy - $orb / 2, $orb, $orb)
$moonBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($moonPath)
$moonBrush.CenterPoint = [System.Drawing.PointF]::new(500, 430)
$moonBrush.CenterColor = [System.Drawing.Color]::FromArgb(255, 255, 251, 236)
$moonBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(255, 225, 208, 160))
$g.FillPath($moonBrush, $moonPath)
$moonBrush.Dispose()
# Crater shadows, kept very soft.
$craters = @(
    @(470, 500, 170, 130, 20),
    @(660, 660, 220, 160, 16),
    @(590, 400, 90, 70, 18),
    @(760, 520, 80, 95, 14),
    @(420, 700, 120, 80, 14)
)
foreach ($c in $craters) {
    for ($k = 5; $k -ge 1; $k--) {
        $alpha = [int]($c[4] * (1 - ($k / 6.0)) / 3)
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 150, 132, 102))
        $g.FillEllipse($brush, $c[0] - $c[2] / 2 - $k * 3, $c[1] - $c[3] / 2 - $k * 3, $c[2] + $k * 6, $c[3] + $k * 6)
        $brush.Dispose()
    }
}
# Bright rim along the top-left edge.
$rimPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(170, 255, 253, 245), 7)
$g.DrawArc($rimPen, $cx - $orb / 2 + 4, $cy - $orb / 2 + 4, $orb - 8, $orb - 8, 150, 120)
$rimPen.Dispose()
$rimPen2 = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60, 255, 253, 245), 22)
$g.DrawArc($rimPen2, $cx - $orb / 2 + 6, $cy - $orb / 2 + 6, $orb - 12, $orb - 12, 152, 116)
$rimPen2.Dispose()
$moonPath.Dispose()
Save-Png $bmp $g (Join-Path $images "moon_half.png")

# ---------------------------------------------------------------- 4 tiny stars
$starSpecs = @(
    @{ Name = "star_01.png"; Kind = "four"; Size = 7 },
    @{ Name = "star_02.png"; Kind = "five"; Size = 8 },
    @{ Name = "star_03.png"; Kind = "diamond"; Size = 6 },
    @{ Name = "star_04.png"; Kind = "flare"; Size = 6 }
)
foreach ($spec in $starSpecs) {
    $bmp, $g = New-Canvas 128 128
    # Halo
    for ($i = 26; $i -ge 1; $i--) {
        $alpha = [int](120 * (1 - ($i / 27.0)) / 4)
        if ($alpha -le 0) { continue }
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 246, 243, 226))
        $r = 6 + $i * 1.7
        $g.FillEllipse($brush, 64 - $r, 64 - $r, $r * 2, $r * 2)
        $brush.Dispose()
    }
    $fill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 252, 240))
    switch ($spec.Kind) {
        "four" {
            $path = New-Object System.Drawing.Drawing2D.GraphicsPath
            $path.AddBezier(64, 12, 72, 48, 80, 56, 116, 64)
            $path.AddBezier(116, 64, 80, 72, 72, 80, 64, 116)
            $path.AddBezier(64, 116, 56, 80, 48, 72, 12, 64)
            $path.AddBezier(12, 64, 48, 56, 56, 48, 64, 12)
            $path.CloseFigure()
            $g.FillPath($fill, $path)
            $path.Dispose()
        }
        "five" {
            $path = New-PathStar 64 66 46 18 5
            $g.FillPath($fill, $path)
            $path.Dispose()
        }
        "diamond" {
            $path = New-PathStar 64 64 48 12 4
            $g.FillPath($fill, $path)
            $path.Dispose()
        }
        "flare" {
            $g.FillEllipse($fill, 44, 44, 40, 40)
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(235, 255, 252, 240), 12)
            $g.DrawLine($pen, 64, 10, 64, 44)
            $g.DrawLine($pen, 64, 84, 64, 118)
            $g.DrawLine($pen, 10, 64, 44, 64)
            $g.DrawLine($pen, 84, 64, 118, 64)
            $pen.Dispose()
        }
    }
    $fill.Dispose()
    Save-Png $bmp $g (Join-Path $stars $spec.Name)
}

Write-Host "Placeholder assets generated in $images"
