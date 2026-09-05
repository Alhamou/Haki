import AppKit
import CoreGraphics

// Generates a 1024x1024 native macOS icon tailored for "Haki / حكي"
// Minimal, modern Apple aesthetic: deep space slate squircle, dynamic voice waves (inspired by spoken Arabic flow), and metallic microphone capsule.

let size: CGFloat = 1024.0
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size),
    pixelsHigh: Int(size),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!

NSGraphicsContext.saveGraphicsState()
let context = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = context
let cg = context.cgContext

// 1. Clear Canvas
cg.clear(CGRect(x: 0, y: 0, width: size, height: size))

// 2. macOS HIG Standard Squircle Path
let squircleRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius: CGFloat = 185.0
let path = NSBezierPath(roundedRect: squircleRect, xRadius: cornerRadius, yRadius: cornerRadius)

// Squircle Soft Deep Shadow
cg.saveGState()
cg.setShadow(offset: CGSize(width: 0, height: -28), blur: 54, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.50))
NSColor(red: 0.07, green: 0.09, blue: 0.13, alpha: 1.0).setFill()
path.fill()
cg.restoreGState()

// Squircle Background: Dark Obsidian to Midnight Slate Gradient
cg.saveGState()
path.addClip()
let bgColors = [
    CGColor(red: 0.10, green: 0.15, blue: 0.22, alpha: 1.0),
    CGColor(red: 0.05, green: 0.07, blue: 0.11, alpha: 1.0)
] as CFArray
let bgGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: bgColors, locations: [0.0, 1.0])!
cg.drawLinearGradient(bgGradient, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

// Radial Ambient Speech Glow in Center
let glowColors = [
    CGColor(red: 0.18, green: 0.65, blue: 0.60, alpha: 0.28),
    CGColor(red: 0.10, green: 0.35, blue: 0.45, alpha: 0.0)
] as CFArray
let glowGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: glowColors, locations: [0.0, 1.0])!
cg.drawRadialGradient(glowGradient, startCenter: CGPoint(x: 512, y: 550), startRadius: 10, endCenter: CGPoint(x: 512, y: 550), endRadius: 360, options: [])

// Outer Border Rim Highlight
path.lineWidth = 3.5
NSColor(red: 0.30, green: 0.52, blue: 0.65, alpha: 0.30).setStroke()
path.stroke()

// 3. Dynamic Speech Waveforms (Concentric arcs embodying conversational Arabic flow & "حكي")
let waveEmerald = CGColor(red: 0.22, green: 0.78, blue: 0.68, alpha: 0.75)
let waveCyan = CGColor(red: 0.28, green: 0.82, blue: 0.88, alpha: 0.50)
let waveSoft = CGColor(red: 0.20, green: 0.55, blue: 0.60, alpha: 0.25)

// Left Waves
func drawArc(radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, width: CGFloat, color: CGColor) {
    let p = CGMutablePath()
    p.addArc(center: CGPoint(x: 512, y: 560), radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
    cg.addPath(p)
    cg.setLineWidth(width)
    cg.setLineCap(.round)
    cg.setStrokeColor(color)
    cg.strokePath()
}

// Left Speech Arcs
drawArc(radius: 205, startAngle: CGFloat.pi * 0.74, endAngle: CGFloat.pi * 1.26, width: 14, color: waveEmerald)
drawArc(radius: 260, startAngle: CGFloat.pi * 0.80, endAngle: CGFloat.pi * 1.20, width: 10, color: waveCyan)
drawArc(radius: 315, startAngle: CGFloat.pi * 0.86, endAngle: CGFloat.pi * 1.14, width: 7, color: waveSoft)

// Right Speech Arcs (Conversational echo)
drawArc(radius: 205, startAngle: -CGFloat.pi * 0.26, endAngle: CGFloat.pi * 0.26, width: 14, color: waveEmerald)
drawArc(radius: 260, startAngle: -CGFloat.pi * 0.20, endAngle: CGFloat.pi * 0.20, width: 10, color: waveCyan)
drawArc(radius: 315, startAngle: -CGFloat.pi * 0.14, endAngle: CGFloat.pi * 0.14, width: 7, color: waveSoft)

// 4. Central Precision Microphone
// Stand Base
let baseRect = CGRect(x: 432, y: 260, width: 160, height: 26)
let basePath = NSBezierPath(roundedRect: baseRect, xRadius: 13, yRadius: 13)
NSColor(red: 0.76, green: 0.84, blue: 0.90, alpha: 0.92).setFill()
basePath.fill()

// Stand Vertical Stem
let stemRect = CGRect(x: 498, y: 280, width: 28, height: 115)
let stemPath = NSBezierPath(roundedRect: stemRect, xRadius: 6, yRadius: 6)
NSColor(red: 0.70, green: 0.78, blue: 0.86, alpha: 0.90).setFill()
stemPath.fill()

// Microphone Cradle Curved Arc
let cradlePath = NSBezierPath()
cradlePath.appendArc(withCenter: NSPoint(x: 512, y: 500), radius: 118, startAngle: 180, endAngle: 0, clockwise: true)
cradlePath.lineWidth = 26
cradlePath.lineCapStyle = .round
NSColor(red: 0.82, green: 0.89, blue: 0.95, alpha: 0.95).setStroke()
cradlePath.stroke()

// Microphone Capsule Glow & Shadow
cg.saveGState()
cg.setShadow(offset: CGSize(width: 0, height: -14), blur: 28, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.45))

// Microphone Capsule Body
let micCapsuleRect = CGRect(x: 437, y: 445, width: 150, height: 285)
let micCapsule = NSBezierPath(roundedRect: micCapsuleRect, xRadius: 75, yRadius: 75)

// Metallic Platinum & Turquoise Gradient
let micColors = [
    CGColor(red: 0.98, green: 0.99, blue: 1.0, alpha: 1.0),
    CGColor(red: 0.75, green: 0.88, blue: 0.87, alpha: 1.0),
    CGColor(red: 0.22, green: 0.68, blue: 0.60, alpha: 1.0)
] as CFArray
let micGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: micColors, locations: [0.0, 0.48, 1.0])!
cg.saveGState()
micCapsule.addClip()
cg.drawLinearGradient(micGradient, start: CGPoint(x: 437, y: 730), end: CGPoint(x: 587, y: 445), options: [])

// Acoustic Grille Lines
cg.setLineWidth(4.5)
cg.setStrokeColor(CGColor(red: 0.20, green: 0.45, blue: 0.42, alpha: 0.45))
for y in stride(from: 565, through: 675, by: 22) {
    cg.move(to: CGPoint(x: 454, y: CGFloat(y)))
    cg.addLine(to: CGPoint(x: 570, y: CGFloat(y)))
    cg.strokePath()
}

// Active Voice Status Dot (Haki Voice Beacon)
cg.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95))
cg.fillEllipse(in: CGRect(x: 504, y: 485, width: 16, height: 16))

cg.restoreGState() // capsule clip
cg.restoreGState() // capsule shadow
cg.restoreGState() // squircle clip

NSGraphicsContext.restoreGraphicsState()

// 5. Export Master 1024x1024 PNG
let pngData = rep.representation(using: .png, properties: [:])!
let masterURL = URL(fileURLWithPath: "Resources/AppIcon-1024.png")
try! pngData.write(to: masterURL)
print("Haki master 1024x1024 icon generated at \(masterURL.path)")
