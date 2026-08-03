#!/usr/bin/env swift
// Génère l'icône d'app Luma (1024×1024) : logo « Diaphragme » crème sur
// fond cuir noir dégradé. Même géométrie que LumaLogo.swift (espace 100×100).
// Usage : swift scripts/generate-appicon.swift
// Sortie : Luma/Assets.xcassets/AppIcon.appiconset/icon-1024.png
// PNG sans canal alpha : une icône App Store avec alpha est rejetée (ITMS-90717).

import AppKit
import ImageIO
import UniformTypeIdentifiers

// Paramètres, pour pouvoir comparer des variantes sans dupliquer le tracé :
//   --couverture <n>  part de la largeur occupée par le motif (défaut 0,78)
//   --coeur <n>       rayon du point rouge dans l'espace 100×100 (défaut 6,5)
//   --sortie <chemin>
//
// L'ancienne valeur de couverture était 0,53 : le motif y paraissait petit et
// fragile, et le cœur rouge tombait à 2 px dans les listes de réglages.
func argument(_ nom: String, defaut: CGFloat) -> CGFloat {
    guard let index = CommandLine.arguments.firstIndex(of: nom),
          index + 1 < CommandLine.arguments.count,
          let valeur = Double(CommandLine.arguments[index + 1]) else { return defaut }
    return CGFloat(valeur)
}

let side = 1024
let couverture = argument("--couverture", defaut: 0.78)
let rayonCoeur = argument("--coeur", defaut: 6.5)
let outputPath: String = {
    if let index = CommandLine.arguments.firstIndex(of: "--sortie"),
       index + 1 < CommandLine.arguments.count {
        return CommandLine.arguments[index + 1]
    }
    return "Luma/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
}()

// Palette (Theme.swift) — crème, rouge FM2, cuir.
let cream = CGColor(red: 0.94, green: 0.93, blue: 0.90, alpha: 1)
let fm2Red = CGColor(red: 0.75, green: 0.22, blue: 0.17, alpha: 1)
let leatherTop = CGColor(red: 0.15, green: 0.14, blue: 0.12, alpha: 1)
let leatherBottom = CGColor(red: 0.08, green: 0.075, blue: 0.06, alpha: 1)

// Contexte RGBX (pas de canal alpha dans le PNG final).
guard let ctx = CGContext(data: nil, width: side, height: side,
                          bitsPerComponent: 8, bytesPerRow: 0,
                          space: CGColorSpaceCreateDeviceRGB(),
                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    fatalError("CGContext allocation failed")
}

let sideF = CGFloat(side)

// Fond : dégradé cuir plein cadre (iOS arrondit lui-même les coins).
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: [leatherTop, leatherBottom] as CFArray,
                          locations: [0, 1])!
ctx.drawLinearGradient(gradient,
                       start: CGPoint(x: 0, y: sideF),
                       end: CGPoint(x: sideF, y: 0), options: [])

// Logo centré. Espace de référence 100×100, centre (50,50).
// L'emprise réelle du motif est le fût : cercle r=40 plus son trait de 5,
// soit 85 unités. C'est cette emprise que « couverture » cadre, et non les
// 100 unités de l'espace de référence — sans quoi la marge serait trompeuse.
let scale = sideF * couverture / 85
let center = CGPoint(x: sideF / 2, y: sideF / 2)
func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    // Coordonnées façon SVG (y vers le bas) → CoreGraphics (y vers le haut).
    CGPoint(x: center.x + (x - 50) * scale, y: center.y - (y - 50) * scale)
}

ctx.setLineCap(.round)

// Fût : cercle r=40, trait 5 centré.
ctx.setStrokeColor(cream)
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
ctx.setFillColor(fm2Red)
ctx.fillEllipse(in: CGRect(x: center.x - rayonCoeur * scale,
                           y: center.y - rayonCoeur * scale,
                           width: rayonCoeur * 2 * scale,
                           height: rayonCoeur * 2 * scale))

guard let image = ctx.makeImage() else { fatalError("makeImage failed") }
try FileManager.default.createDirectory(
    atPath: (outputPath as NSString).deletingLastPathComponent,
    withIntermediateDirectories: true)
let url = URL(fileURLWithPath: outputPath) as CFURL
guard let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString,
                                                 1, nil) else {
    fatalError("CGImageDestination creation failed")
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("PNG write failed") }
print("OK → \(outputPath)")
