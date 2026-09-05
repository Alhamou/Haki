import AppKit
import CoreGraphics

// Generates a 1024x1024 native macOS icon with squircle, metallic microphone, and Arabic-inspired waveform
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

// 1. Clear background
cg.clear(CGRect(x: 0, y: 0, width: size, height: size))

// 2. macOS Squircle Path
let squircleRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius: CGFloat = 185.0
let path = NSBezierPath(roundedRect: squircleRect, xRadius: cornerRadius, yRadius: cornerRadius)

// Squircle Shadow
cg.saveGState()
cg.setShadow(offset: CGSize(width: 0, height: -24), blur: 48, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.45))
NSColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1.0).setFill()
path.fill()
cg.restoreGState()

// Squircle Background Gradient (Deep obsidian teal to midnight slate)
cg.saveGState()
path.addClip()
let bgColors = [
    CGColor(red: 0.08, green: 0.14, blue: 0.18, alpha: 1.0),
    CGColor(red: 0.05, green: 0.07, blue: 0.10, alpha: 1.0)
] as CFArray
let bgGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: bgColors, locations: [0.0, 1.0])!
cg.drawLinearGradient(bgGradient, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

// Subtle inner rim light
path.lineWidth = 3.0
NSColor(red: 0.25, green: 0.45, blue: 0.45, alpha: 0.35).setStroke()
path.stroke()
cg.restoreGState()

// 3. Arabic calligraphy waveform ambient curves (representing speech & Arabic letterforms)
cg.saveGState()
path.addClip()

let waveColor1 = CGColor(red: 0.12, green: 0.55, blue: 0.48, alpha: 0.25)
let waveColor2 = CGColor(red: 0.20, green: 0.70, blue: 0.60, alpha: 0.65)

// Wave 1: Left arc curve
let leftWave = CGMutablePath()
leftWave.addArc(center: CGPoint(x: 512, y: 550), radius: 210, startAngle: CGFloat.pi * 0.75, endAngle: CGFloat.pi * 1.25, clockwise: false)
cg.addPath(leftWave)
cg.setLineWidth(14)
cg.setLineCap(.round)
cg.setStrokeColor(waveColor1)
cg.strokePath()

let leftWaveInner = CGMutablePath()
leftWaveInner.addArc(center: CGPoint(x: 512, y: 550), radius: 260, startAngle: CGFloat.pi * 0.82, endAngle: CGFloat.pi * 1.18, clockwise: false)
cg.addPath(leftWaveInner)
cg.setLineWidth(10)
cg.setLineCap(.round)
cg.setStrokeColor(waveColor2)
cg.strokePath()

// Wave 2: Right arc curve (mimicking Arabic diacritics / flow)
let rightWave = CGMutablePath()
rightWave.addArc(center: CGPoint(x: 512, y: 550), radius: 210, startAngle: -CGFloat.pi * 0.25, endAngle: CGFloat.pi * 0.25, clockwise: false)
cg.addPath(rightWave)
cg.setLineWidth(14)
cg.setLineCap(.round)
cg.setStrokeColor(waveColor1)
cg.strokePath()

let rightWaveInner = CGMutablePath()
rightWaveInner.addArc(center: CGPoint(x: 512, y: 550), radius: 260, startAngle: -CGFloat.pi * 0.18, endAngle: CGFloat.pi * 0.18, clockwise: false)
cg.addPath(rightWaveInner)
cg.setLineWidth(10)
cg.setLineCap(.round)
cg.setStrokeColor(waveColor2)
cg.strokePath()

// 4. Central Microphone
// Stand base
let baseRect = CGRect(x: 432, y: 260, width: 160, height: 26)
let basePath = NSBezierPath(roundedRect: baseRect, xRadius: 13, yRadius: 13)
NSColor(red: 0.75, green: 0.82, blue: 0.88, alpha: 0.9).setFill()
basePath.fill()

// Stand vertical stem
let stemRect = CGRect(x: 498, y: 280, width: 28, height: 110)
let stemPath = NSBezierPath(roundedRect: stemRect, xRadius: 6, yRadius: 6)
NSColor(red: 0.70, green: 0.78, blue: 0.85, alpha: 0.9).setFill()
stemPath.fill()

// Microphone cradle arc
let cradlePath = NSBezierPath()
cradlePath.appendArc(withCenter: NSPoint(x: 512, y: 490), radius: 115, startAngle: 180, endAngle: 0, clockwise: true)
cradlePath.lineWidth = 26
cradlePath.lineCapStyle = .round
NSColor(red: 0.82, green: 0.88, blue: 0.94, alpha: 0.95).setStroke()
cradlePath.stroke()

// Microphone Capsule Shadow
cg.saveGState()
cg.setShadow(offset: CGSize(width: 0, height: -12), blur: 24, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.40))

// Microphone Capsule Body
let micCapsuleRect = CGRect(x: 437, y: 440, width: 150, height: 280)
let micCapsule = NSBezierPath(roundedRect: micCapsuleRect, xRadius: 75, yRadius: 75)

// Metallic emerald-silver gradient
let micColors = [
    CGColor(red: 0.96, green: 0.98, blue: 1.0, alpha: 1.0),
    CGColor(red: 0.72, green: 0.85, blue: 0.84, alpha: 1.0),
    CGColor(red: 0.20, green: 0.65, blue: 0.55, alpha: 1.0)
] as CFArray
let micGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: micColors, locations: [0.0, 0.45, 1.0])!
cg.saveGState()
micCapsule.addClip()
cg.drawLinearGradient(micGradient, start: CGPoint(x: 437, y: 720), end: CGPoint(x: 587, y: 440), options: [])

// Microphone grille lines
cg.setLineWidth(4)
cg.setStrokeColor(CGColor(red: 0.25, green: 0.45, blue: 0.42, alpha: 0.45))
for y in stride(from: 560, through: 660, by: 22) {
    cg.move(to: CGPoint(x: 455, y: CGFloat(y)))
    cg.addLine(to: CGPoint(x: 569, y: CGFloat(y)))
    cg.strokePath()
}

// Center accent sound badge (Arabic subtle dot / talisman mark)
cg.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95))
cg.fillEllipse(in: CGRect(x: 504, y: 480, width: 16, height: 16))

cg.restoreGState() // capsule clip
cg.restoreGState() // capsule shadow
cg.restoreGState() // squircle clip

NSGraphicsContext.restoreGraphicsState()

// 5. Save master 1024x1024 PNG
let pngData = rep.representation(using: .png, properties: [:])!
let masterURL = URL(fileURLWithPath: "Resources/AppIcon-1024.png")
try! pngData.write(to: masterURL)
print("Master 1024x1024 icon generated at \(masterURL.path)")
