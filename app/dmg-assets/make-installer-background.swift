// Generates the DMG installer background (arrow + "drag to Applications" instruction).
// Usage: swift make-installer-background.swift <output.png>
import AppKit

let W = 600.0, H = 400.0
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

// y measured from the TOP (to match create-dmg icon coordinates); convert to AppKit bottom-left.
func yb(_ top: Double) -> Double { H - top }

// Soft vertical gradient background.
let grad = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [NSColor(calibratedRed: 0.97, green: 0.98, blue: 0.97, alpha: 1).cgColor,
             NSColor(calibratedRed: 0.89, green: 0.93, blue: 0.90, alpha: 1).cgColor] as CFArray,
    locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])

// Arrow pointing from the app (left) toward the Applications folder (right), at icon center y=195.
let ay = yb(195), x0 = 250.0, x1 = 350.0
let arrowColor = NSColor(calibratedWhite: 0.40, alpha: 1)
arrowColor.setStroke()
let shaft = NSBezierPath()
shaft.lineWidth = 5
shaft.lineCapStyle = .round
shaft.move(to: CGPoint(x: x0, y: ay))
shaft.line(to: CGPoint(x: x1 - 4, y: ay))
shaft.stroke()
arrowColor.setFill()
let head = NSBezierPath()
head.move(to: CGPoint(x: x1 + 10, y: ay))
head.line(to: CGPoint(x: x1 - 10, y: ay + 11))
head.line(to: CGPoint(x: x1 - 10, y: ay - 11))
head.close()
head.fill()

// Centered text helper (top-origin y).
func text(_ s: String, size: CGFloat, weight: NSFont.Weight, white: CGFloat, topY: Double) {
    let p = NSMutableParagraphStyle(); p.alignment = .center
    let a = NSAttributedString(string: s, attributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: NSColor(calibratedWhite: white, alpha: 1),
        .paragraphStyle: p])
    let h = a.size().height
    a.draw(in: NSRect(x: 0, y: yb(topY) - h / 2, width: W, height: h))
}

text("Install MenuFC", size: 24, weight: .bold, white: 0.13, topY: 56)
text("Drag the MenuFC icon onto the Applications folder", size: 14, weight: .regular, white: 0.34, topY: 92)

NSGraphicsContext.restoreGraphicsState()
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "installer-background.png"
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
