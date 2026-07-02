#!/usr/bin/env swift
// Génère l'icône d'app Luma (1024×1024) : logo « Diaphragme » crème sur
// fond cuir noir dégradé. Même géométrie que LumaLogo.swift (espace 100×100).
// Usage : swift scripts/generate-appicon.swift
// Sortie : Luma/Assets.xcassets/AppIcon.appiconset/icon-1024.png

import AppKit

let side: CGFloat = 1024
let outputPath = "Luma/Assets.xcassets/AppIcon.appiconset/icon-1024.png"

// Palette (Theme.swift) — crème, rouge FM2, cuir.
let cream = NSColor(red: 0.94, green: 0.93, blue: 0.90, alpha: 1)
let fm2Red = NSColor(red: 0.75, green: 0.22, blue: 0.17, alpha: 1)
let leatherTop = NSColor(red: 0.15, green: 0.14, blue: 0.12, alpha: 1)
let leatherBottom = NSColor(red: 0.08, green: 0.075, blue: 0.06, alpha: 1)

guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(side),
                                 pixelsHigh: Int(side), bitsPerSample: 8,
                                 samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                 colorSpaceName: .deviceRGB, bytesPerRow: 0,
                                 bitsPerPixel: 0) else {
    fatalError("bitmap allocation failed")
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
guard let ctx = NSGraphicsContext.current?.cgContext else {
    fatalError("no graphics context")
}

// Fond : dégradé cuir plein cadre (iOS arrondit lui-même les coins ;
// pas de transparence dans une icône).
let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [leatherTop.cgColor, leatherBottom.cgColor] as CFArray,
    locations: [0, 1])!
ctx.drawLinearGradient(gradient,
                       start: CGPoint(x: 0, y: side),
                       end: CGPoint(x: side, y: 0), options: [])

// Logo centré, ~62 % du cadre. Espace de référence 100×100, centre (50,50).
let scale = side * 0.62 / 100
let center = CGPoint(x: side / 2, y: side / 2)
func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    // Coordonnées façon SVG (y vers le bas) → CoreGraphics (y vers le haut).
    CGPoint(x: center.x + (x - 50) * scale, y: center.y - (y - 50) * scale)
}

ctx.setLineCap(.round)

// Fût : cercle r=40, trait 5.
ctx.setStrokeColor(cream.cgColor)
ctx.setLineWidth(5 * scale)
ctx.strokeEllipse(in: CGRect(x: center.x - 40 * scale, y: center.y - 40 * scale,
                             width: 80 * scale, height: 80 * scale))

// 7 lamelles : segment (50,36)→(78.4,27.8) répété par rotation de 360/7°.
ctx.setLineWidth(3.5 * scale)
for blade in 0..<7 {
    let angle = CGFloat(blade) * 2 * .pi / 7
    ctx.saveGState()
    ctx.translateBy(x: center.x, y: center.y)
    ctx.rotate(by: angle)
    ctx.translateBy(x: -center.x, y: -center.y)
    ctx.move(to: pt(50, 36))
    ctx.addLine(to: pt(78.4, 27.8))
    ctx.strokePath()
    ctx.restoreGState()
}

// Cœur rouge : r=5.
ctx.setFillColor(fm2Red.cgColor)
ctx.fillEllipse(in: CGRect(x: center.x - 5 * scale, y: center.y - 5 * scale,
                           width: 10 * scale, height: 10 * scale))

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("PNG encoding failed")
}
try FileManager.default.createDirectory(
    atPath: (outputPath as NSString).deletingLastPathComponent,
    withIntermediateDirectories: true)
try png.write(to: URL(fileURLWithPath: outputPath))
print("OK → \(outputPath) (\(png.count / 1024) Ko)")
