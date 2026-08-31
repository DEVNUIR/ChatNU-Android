$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

if (!(Test-Path "windows")) {
    $tempBase = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [System.IO.Path]::GetTempPath() }
    $tempRoot = Join-Path $tempBase ("chatnu-windows-" + [Guid]::NewGuid().ToString("N"))
    $tempProject = Join-Path $tempRoot "chatnu"
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    try {
        flutter create --platforms=windows --org ir.devnu --project-name chatnu $tempProject
        Copy-Item -Recurse -Force (Join-Path $tempProject "windows") (Join-Path $root "windows")
    }
    finally {
        Remove-Item -Recurse -Force $tempRoot -ErrorAction SilentlyContinue
    }
}

# Keep a compact, reviewable PNG source in git and wrap it as a standards-valid
# single-image ICO before the Windows runner is compiled. Windows accepts PNG
# image data inside ICO containers and scales the 256px source for smaller sizes.
$iconSource = Join-Path $root "tool\windows\chatnu.png"
$iconTarget = Join-Path $root "windows\runner\resources\app_icon.ico"
if (!(Test-Path $iconSource)) {
    throw "ChatNU Windows icon source is missing: $iconSource"
}
if (!(Test-Path (Split-Path -Parent $iconTarget))) {
    throw "Flutter Windows runner resources directory is missing."
}

$png = [System.IO.File]::ReadAllBytes($iconSource)
$stream = New-Object System.IO.MemoryStream
$writer = New-Object System.IO.BinaryWriter($stream)
try {
    $writer.Write([UInt16]0)       # reserved
    $writer.Write([UInt16]1)       # ICO image type
    $writer.Write([UInt16]1)       # one image
    $writer.Write([Byte]0)         # width 256
    $writer.Write([Byte]0)         # height 256
    $writer.Write([Byte]0)         # palette colors
    $writer.Write([Byte]0)         # reserved
    $writer.Write([UInt16]1)       # color planes
    $writer.Write([UInt16]32)      # bits per pixel
    $writer.Write([UInt32]$png.Length)
    $writer.Write([UInt32]22)      # image data offset
    $writer.Write($png)
    $writer.Flush()
    [System.IO.File]::WriteAllBytes($iconTarget, $stream.ToArray())
}
finally {
    $writer.Dispose()
    $stream.Dispose()
}

if (!(Test-Path $iconTarget) -or ((Get-Item $iconTarget).Length -le 22)) {
    throw "ChatNU Windows icon generation failed."
}

flutter pub get
