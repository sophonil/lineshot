// Original LineNote icon artwork: a cream notebook on a deep teal tile.
// Copyright (c) 2026 sophonil. Licensed under the MIT License.
// Usage: swift scripts/make-icon.swift out.png
import AppKit

let size = 1024
let output = CommandLine.arguments.dropFirst().first ?? "icon.png"
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
let context = NSGraphicsContext.current!.cgContext
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor {
    NSColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: 1)
}
func rounded(_ rect: NSRect, _ radius: CGFloat, _ fill: NSColor) {
    fill.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}
context.saveGState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
shadow.shadowBlurRadius = 24
shadow.shadowOffset = NSSize(width: 0, height: -10)
shadow.set()
rounded(NSRect(x: 100, y: 100, width: 824, height: 824), 184, color(29, 83, 82))
context.restoreGState()
let tile = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 184, yRadius: 184)
NSGradient(starting: color(52, 123, 117), ending: color(19, 57, 65))!.draw(in: tile, angle: -80)
context.saveGState()
context.translateBy(x: 512, y: 502)
context.rotate(by: -0.06)
shadow.shadowBlurRadius = 30
shadow.shadowOffset = NSSize(width: 0, height: -18)
shadow.set()
rounded(NSRect(x: -253, y: -276, width: 506, height: 564), 40, color(252, 247, 231))
context.restoreGState()
context.saveGState()
context.translateBy(x: 512, y: 502)
context.rotate(by: -0.06)
rounded(NSRect(x: -253, y: 183, width: 506, height: 12), 6, color(222, 208, 179))
for x in [-149.0, -49, 51, 151] {
    rounded(NSRect(x: x - 10, y: 252, width: 20, height: 79), 10, color(247, 181, 88))
}
for (i, length) in [246.0, 211, 165].enumerated() {
    let y = 96.0 - Double(i) * 116
    let box = NSBezierPath(roundedRect: NSRect(x: -175, y: y - 20, width: 40, height: 40), xRadius: 12, yRadius: 12)
    color(54, 119, 112).setStroke()
    box.lineWidth = 7
    box.stroke()
    rounded(NSRect(x: -94, y: y - 5, width: length, height: 12), 6, color(113, 126, 119))
    if i == 0 {
        let check = NSBezierPath()
        check.move(to: NSPoint(x: -172, y: y))
        check.line(to: NSPoint(x: -158, y: y - 13))
        check.line(to: NSPoint(x: -127, y: y + 26))
        check.lineWidth = 9
        check.lineCapStyle = .round
        color(31, 104, 97).setStroke()
        check.stroke()
    }
}
context.restoreGState()
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
