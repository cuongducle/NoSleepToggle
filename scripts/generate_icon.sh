#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS_DIR="$ROOT_DIR/assets"
ICONSET_DIR="$ASSETS_DIR/NoSleepToggle.iconset"
MASTER_PNG="$ASSETS_DIR/icon_1024.png"
ICNS_PATH="$ASSETS_DIR/NoSleepToggle.icns"

mkdir -p "$ASSETS_DIR"

cat > "$ASSETS_DIR/make_icon.swift" <<'SWIFT'
import AppKit

let width = 1024
let height = 1024
let size = NSSize(width: width, height: height)

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Could not create bitmap rep")
}

guard let graphics = NSGraphicsContext(bitmapImageRep: rep) else {
    fatalError("Could not create graphics context")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics
defer {
    NSGraphicsContext.restoreGraphicsState()
}

let context = graphics.cgContext

let rect = NSRect(x: 0, y: 0, width: width, height: height)

let backgroundPath = NSBezierPath(roundedRect: rect.insetBy(dx: 64, dy: 64), xRadius: 220, yRadius: 220)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.10, green: 0.22, blue: 0.55, alpha: 1.0),
    NSColor(calibratedRed: 0.02, green: 0.12, blue: 0.32, alpha: 1.0)
])!
gradient.draw(in: backgroundPath, angle: 270)

context.saveGState()
backgroundPath.addClip()

let glowColor = NSColor(calibratedRed: 0.33, green: 0.62, blue: 1.0, alpha: 0.45)
context.setShadow(offset: CGSize(width: 0, height: -8), blur: 28, color: glowColor.cgColor)

let boltPath = NSBezierPath()
boltPath.move(to: NSPoint(x: 560, y: 740))
boltPath.line(to: NSPoint(x: 470, y: 535))
boltPath.line(to: NSPoint(x: 595, y: 535))
boltPath.line(to: NSPoint(x: 455, y: 300))
boltPath.line(to: NSPoint(x: 520, y: 500))
boltPath.line(to: NSPoint(x: 415, y: 500))
boltPath.close()
NSColor(calibratedRed: 0.95, green: 0.98, blue: 1.0, alpha: 0.98).setFill()
boltPath.fill()
context.restoreGState()

if let symbol = NSImage(
    systemSymbolName: "moon.zzz.fill",
    accessibilityDescription: "NoSleep"
) {
    let config = NSImage.SymbolConfiguration(pointSize: 340, weight: .regular)
    let symbolImage = symbol.withSymbolConfiguration(config) ?? symbol
    let symbolRect = NSRect(x: 180, y: 250, width: 420, height: 420)
    NSColor.white.set()
    symbolImage.draw(in: symbolRect)
}

let borderPath = NSBezierPath(roundedRect: rect.insetBy(dx: 64, dy: 64), xRadius: 220, yRadius: 220)
NSColor(calibratedWhite: 1.0, alpha: 0.22).setStroke()
borderPath.lineWidth = 12
borderPath.stroke()

guard let pngData = rep.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode PNG")
}

let outputPath = CommandLine.arguments[1]
try pngData.write(to: URL(fileURLWithPath: outputPath))
SWIFT

/usr/bin/swift "$ASSETS_DIR/make_icon.swift" "$MASTER_PNG"
rm -f "$ASSETS_DIR/make_icon.swift"

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

sips -z 16 16 "$MASTER_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$MASTER_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$MASTER_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$MASTER_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$MASTER_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$MASTER_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$MASTER_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$MASTER_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$MASTER_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$MASTER_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null

iconutil --convert icns --output "$ICNS_PATH" "$ICONSET_DIR"
echo "Generated icon: $ICNS_PATH"
