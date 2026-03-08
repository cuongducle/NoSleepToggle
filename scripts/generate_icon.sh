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
let insetRect = rect.insetBy(dx: 64, dy: 64)
let backgroundPath = NSBezierPath(roundedRect: insetRect, xRadius: 220, yRadius: 220)
let backgroundGradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.04, green: 0.09, blue: 0.20, alpha: 1.0),
    NSColor(calibratedRed: 0.07, green: 0.20, blue: 0.33, alpha: 1.0),
    NSColor(calibratedRed: 0.03, green: 0.12, blue: 0.24, alpha: 1.0)
])!
backgroundGradient.draw(in: backgroundPath, angle: 90)

context.saveGState()
backgroundPath.addClip()

let haloPath = NSBezierPath(ovalIn: NSRect(x: 210, y: 230, width: 620, height: 620))
let haloGradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.21, green: 0.53, blue: 0.82, alpha: 0.30),
    NSColor(calibratedRed: 0.21, green: 0.53, blue: 0.82, alpha: 0.0)
])!
haloGradient.draw(in: haloPath, relativeCenterPosition: .zero)

let moonPath = NSBezierPath()
moonPath.appendOval(in: NSRect(x: 220, y: 235, width: 440, height: 440))
moonPath.appendOval(in: NSRect(x: 390, y: 300, width: 310, height: 310))
moonPath.windingRule = .evenOdd
NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.93, alpha: 1.0).setFill()
moonPath.fill()

let shadow = NSShadow()
shadow.shadowColor = NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.16, alpha: 0.35)
shadow.shadowBlurRadius = 34
shadow.shadowOffset = NSSize(width: 0, height: -8)
shadow.set()

let slashPath = NSBezierPath()
slashPath.lineCapStyle = .round
slashPath.lineWidth = 96
slashPath.move(to: NSPoint(x: 700, y: 760))
slashPath.line(to: NSPoint(x: 335, y: 295))
NSColor(calibratedRed: 1.0, green: 0.56, blue: 0.18, alpha: 1.0).setStroke()
slashPath.stroke()

let highlightPath = NSBezierPath()
highlightPath.lineCapStyle = .round
highlightPath.lineWidth = 22
highlightPath.move(to: NSPoint(x: 660, y: 730))
highlightPath.line(to: NSPoint(x: 390, y: 385))
NSColor(calibratedRed: 1.0, green: 0.86, blue: 0.45, alpha: 0.9).setStroke()
highlightPath.stroke()
context.restoreGState()

let borderPath = NSBezierPath(roundedRect: insetRect, xRadius: 220, yRadius: 220)
NSColor(calibratedWhite: 1.0, alpha: 0.14).setStroke()
borderPath.lineWidth = 10
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
