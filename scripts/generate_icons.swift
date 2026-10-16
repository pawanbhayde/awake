import Foundation
import Cocoa
import CoreGraphics

func createAwakeIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let scale = size / 1024.0

    // Coordinate system in AppKit lockFocus: (0,0) is bottom-left
    // 1. Drop Shadows for Squircle
    let iconRect = CGRect(x: 106 * scale, y: 106 * scale, width: 812 * scale, height: 812 * scale)
    let cornerRadius = 182.0 * scale
    let squirclePath = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Deep Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -28 * scale), blur: 36 * scale, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.45))
    ctx.addPath(squirclePath)
    ctx.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // Ambient Contact Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -6 * scale), blur: 12 * scale, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.35))
    ctx.addPath(squirclePath)
    ctx.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // 2. Base Squircle Fill (Dark Obsidian / Slate Metallic)
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    let baseColors = [
        CGColor(red: 36/255, green: 40/255, blue: 50/255, alpha: 1.0),
        CGColor(red: 24/255, green: 27/255, blue: 34/255, alpha: 1.0),
        CGColor(red: 14/255, green: 16/255, blue: 20/255, alpha: 1.0)
    ] as CFArray
    let baseLocations: [CGFloat] = [0.0, 0.45, 1.0]
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    if let baseGrad = CGGradient(colorsSpace: colorSpace, colors: baseColors, locations: baseLocations) {
        ctx.drawLinearGradient(baseGrad, start: CGPoint(x: 512 * scale, y: 918 * scale), end: CGPoint(x: 512 * scale, y: 106 * scale), options: [])
    }

    // Subtle Radial Ambient Glow behind emblem
    if let radialGrad = CGGradient(colorsSpace: colorSpace, colors: [
        CGColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 0.22),
        CGColor(red: 1.0, green: 0.35, blue: 0.0, alpha: 0.08),
        CGColor(red: 1.0, green: 0.35, blue: 0.0, alpha: 0.0)
    ] as CFArray, locations: [0.0, 0.5, 1.0]) {
        ctx.drawRadialGradient(radialGrad,
                               startCenter: CGPoint(x: 512 * scale, y: 520 * scale),
                               startRadius: 0,
                               endCenter: CGPoint(x: 512 * scale, y: 520 * scale),
                               endRadius: 360 * scale,
                               options: [])
    }

    // Subtle brushed inner surface highlight
    let innerHighlightPath = CGPath(roundedRect: iconRect.insetBy(dx: 1.5 * scale, dy: 1.5 * scale),
                                    cornerWidth: cornerRadius - 1.5 * scale,
                                    cornerHeight: cornerRadius - 1.5 * scale,
                                    transform: nil)
    ctx.setLineWidth(1.8 * scale)
    ctx.addPath(innerHighlightPath)
    ctx.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.16))
    ctx.strokePath()

    // 3. Central Graphic: Glowing Coffee Cup & Lightning Bolt
    // A. Coffee Cup Outline / Silhouette
    let cupCenter = CGPoint(x: 480 * scale, y: 480 * scale)
    let cupTopWidth: CGFloat = 340 * scale
    let cupBottomWidth: CGFloat = 230 * scale
    let cupHeight: CGFloat = 260 * scale
    let cupTopY = cupCenter.y + cupHeight * 0.5
    let cupBottomY = cupCenter.y - cupHeight * 0.5

    // Cup Handle (Right side)
    let handlePath = CGMutablePath()
    let handleRect = CGRect(x: cupCenter.x + cupTopWidth * 0.35,
                            y: cupCenter.y - 60 * scale,
                            width: 140 * scale,
                            height: 150 * scale)
    handlePath.addRoundedRect(in: handleRect, cornerWidth: 55 * scale, cornerHeight: 55 * scale)
    let innerHandleRect = handleRect.insetBy(dx: 26 * scale, dy: 26 * scale).offsetBy(dx: -8 * scale, dy: 0)
    handlePath.addRoundedRect(in: innerHandleRect, cornerWidth: 35 * scale, cornerHeight: 35 * scale)

    ctx.saveGState()
    ctx.addPath(handlePath)
    ctx.setFillColor(CGColor(red: 1.0, green: 0.65, blue: 0.15, alpha: 0.45))
    ctx.setShadow(offset: .zero, blur: 24 * scale, color: CGColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.6))
    ctx.fillPath(using: .evenOdd)
    ctx.restoreGState()

    // Cup Body
    let cupPath = CGMutablePath()
    let topLeft = CGPoint(x: cupCenter.x - cupTopWidth * 0.5, y: cupTopY)
    let topRight = CGPoint(x: cupCenter.x + cupTopWidth * 0.5, y: cupTopY)
    let bottomRight = CGPoint(x: cupCenter.x + cupBottomWidth * 0.5, y: cupBottomY)
    let bottomLeft = CGPoint(x: cupCenter.x - cupBottomWidth * 0.5, y: cupBottomY)

    cupPath.move(to: topLeft)
    cupPath.addLine(to: topRight)
    cupPath.addCurve(to: bottomRight,
                     control1: CGPoint(x: topRight.x - 10 * scale, y: cupCenter.y),
                     control2: CGPoint(x: bottomRight.x + 30 * scale, y: cupBottomY + 20 * scale))
    cupPath.addCurve(to: bottomLeft,
                     control1: CGPoint(x: cupCenter.x, y: cupBottomY - 15 * scale),
                     control2: CGPoint(x: cupCenter.x, y: cupBottomY - 15 * scale))
    cupPath.addCurve(to: topLeft,
                     control1: CGPoint(x: bottomLeft.x - 30 * scale, y: cupBottomY + 20 * scale),
                     control2: CGPoint(x: topLeft.x + 10 * scale, y: cupCenter.y))
    cupPath.closeSubpath()

    // Fill Cup with rich dark obsidian & amber rim glow
    ctx.saveGState()
    ctx.addPath(cupPath)
    ctx.setFillColor(CGColor(red: 18/255, green: 20/255, blue: 26/255, alpha: 0.85))
    ctx.fillPath()

    // Stroke Cup with glowing amber neon
    ctx.addPath(cupPath)
    ctx.setLineWidth(16 * scale)
    ctx.setStrokeColor(CGColor(red: 1.0, green: 0.60, blue: 0.10, alpha: 0.85))
    ctx.setShadow(offset: .zero, blur: 20 * scale, color: CGColor(red: 1.0, green: 0.45, blue: 0.0, alpha: 0.75))
    ctx.strokePath()
    ctx.restoreGState()

    // Cup Rim Ellipse
    let rimRect = CGRect(x: cupCenter.x - cupTopWidth * 0.5, y: cupTopY - 25 * scale, width: cupTopWidth, height: 50 * scale)
    let rimPath = CGPath(ellipseIn: rimRect, transform: nil)
    ctx.saveGState()
    ctx.addPath(rimPath)
    ctx.setFillColor(CGColor(red: 25/255, green: 28/255, blue: 36/255, alpha: 0.95))
    ctx.fillPath()
    ctx.addPath(rimPath)
    ctx.setLineWidth(12 * scale)
    ctx.setStrokeColor(CGColor(red: 1.0, green: 0.70, blue: 0.20, alpha: 0.90))
    ctx.setShadow(offset: .zero, blur: 16 * scale, color: CGColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.8))
    ctx.strokePath()
    ctx.restoreGState()

    // B. Vibrant Electric Lightning Bolt (Centerpiece)
    let boltPath = CGMutablePath()
    // Dynamic sharp lightning bolt
    boltPath.move(to: CGPoint(x: 520 * scale, y: 760 * scale))      // Top peak
    boltPath.addLine(to: CGPoint(x: 410 * scale, y: 500 * scale))   // Mid-left corner
    boltPath.addLine(to: CGPoint(x: 495 * scale, y: 500 * scale))   // Inner step
    boltPath.addLine(to: CGPoint(x: 435 * scale, y: 260 * scale))   // Bottom sharp tip
    boltPath.addLine(to: CGPoint(x: 585 * scale, y: 535 * scale))   // Mid-right corner
    boltPath.addLine(to: CGPoint(x: 495 * scale, y: 535 * scale))   // Inner step return
    boltPath.closeSubpath()

    // Layer 1: Wide Intense Bloom
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 45 * scale, color: CGColor(red: 1.0, green: 0.40, blue: 0.0, alpha: 0.95))
    ctx.addPath(boltPath)
    ctx.setFillColor(CGColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 0.9))
    ctx.fillPath()
    ctx.restoreGState()

    // Layer 2: Medium Core Glow
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 18 * scale, color: CGColor(red: 1.0, green: 0.75, blue: 0.1, alpha: 1.0))
    ctx.addPath(boltPath)
    ctx.setFillColor(CGColor(red: 1.0, green: 0.70, blue: 0.15, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // Layer 3: Gradient Core with Specular Center
    ctx.saveGState()
    ctx.addPath(boltPath)
    ctx.clip()
    let boltColors = [
        CGColor(red: 1.0, green: 0.95, blue: 0.65, alpha: 1.0), // Electric bright gold/white
        CGColor(red: 1.0, green: 0.70, blue: 0.10, alpha: 1.0), // Radiant Amber
        CGColor(red: 1.0, green: 0.35, blue: 0.00, alpha: 1.0)  // Deep Orange
    ] as CFArray
    if let boltGrad = CGGradient(colorsSpace: colorSpace, colors: boltColors, locations: [0.0, 0.45, 1.0]) {
        ctx.drawLinearGradient(boltGrad,
                               start: CGPoint(x: 500 * scale, y: 760 * scale),
                               end: CGPoint(x: 500 * scale, y: 260 * scale),
                               options: [])
    }
    ctx.restoreGState()

    // 4. Subtle Top Glass Rim Highlight on Squircle
    let topBezelPath = CGMutablePath()
    topBezelPath.addArc(center: CGPoint(x: iconRect.minX + cornerRadius, y: iconRect.maxY - cornerRadius),
                        radius: cornerRadius, startAngle: .pi, endAngle: .pi * 0.5, clockwise: true)
    topBezelPath.addLine(to: CGPoint(x: iconRect.maxX - cornerRadius, y: iconRect.maxY))
    topBezelPath.addArc(center: CGPoint(x: iconRect.maxX - cornerRadius, y: iconRect.maxY - cornerRadius),
                        radius: cornerRadius, startAngle: .pi * 0.5, endAngle: 0, clockwise: true)
    ctx.saveGState()
    ctx.addPath(topBezelPath)
    ctx.setLineWidth(2.5 * scale)
    ctx.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.28))
    ctx.strokePath()
    ctx.restoreGState()

    ctx.restoreGState() // End squircle clip

    image.unlockFocus()
    return image
}

let testImage = createAwakeIcon(size: 1024)
if let tiffData = testImage.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    let outUrl = URL(fileURLWithPath: "scripts/test_icon_1024.png")
    try pngData.write(to: outUrl)
    print("Successfully generated test_icon_1024.png")
}
