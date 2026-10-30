# Captures the login preview at exactly 393 x 852 (Figma frame size).
# Requires the preview server:
#   python -m http.server 8124 --bind 127.0.0.1   (inside build/preview-login)
# Then run:
#   powershell -File tool/capture_login.ps1

Add-Type -AssemblyName System.Drawing

$chrome = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
if (!(Test-Path $chrome)) {
    $chrome = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
}

$tmp = Join-Path $env:TEMP "nottia-login-shot"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$shot = Join-Path $tmp "preview.png"
Remove-Item $shot -Force -ErrorAction SilentlyContinue

& $chrome `
    --headless=new `
    --no-sandbox `
    --disable-gpu `
    --hide-scrollbars `
    --user-data-dir="$tmp\profile-$([guid]::NewGuid().ToString('N'))" `
    --window-size=900,1000 `
    --force-device-scale-factor=1 `
    --virtual-time-budget=20000 `
    --run-all-compositor-stages-before-draw `
    --screenshot="$shot" `
    "http://127.0.0.1:8124/preview.html" 2>$null

if (!(Test-Path $shot)) {
    throw "Chrome did not produce a screenshot. Is the preview server running on port 8124?"
}

$img = [System.Drawing.Bitmap]::FromFile($shot)
$left = 0
for ($x = 0; $x -lt $img.Width; $x++) {
    if ($img.GetPixel($x, 400).B -gt 45) {
        $left = $x
        break
    }
}

$outDir = Join-Path (Split-Path -Parent $PSScriptRoot) "docs\preview"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$out = Join-Path $outDir "login_393x852.png"

$rect = New-Object System.Drawing.Rectangle($left, 32, 393, 852)
$crop = $img.Clone($rect, $img.PixelFormat)
$crop.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$crop.Dispose()
$img.Dispose()

Write-Host "Saved $out (393 x 852)."
