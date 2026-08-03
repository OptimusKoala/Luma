#!/usr/bin/env swift
// Assemble des images en une planche-contact, pour les juger d'un coup d'œil.
//
//   swift scripts/planche-contact.swift sortie.png a.jpg b.jpg c.jpg …
//
// Grille de 3 colonnes, vignettes recadrées au format du viseur de Luma
// (portrait ~0,70) : ce qu'on voit ici est ce que la capture montrera.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count >= 2 else {
    print("usage: swift scripts/planche-contact.swift <sortie.png> <images…>")
    exit(2)
}
let sortie = URL(fileURLWithPath: arguments[0])
let entrees = arguments.dropFirst().map { URL(fileURLWithPath: $0) }

let colonnes = 3
let largeurVignette = 320
let hauteurVignette = 457            // 320 / 0,70 → format du viseur
let marge = 10
let lignes = (entrees.count + colonnes - 1) / colonnes
let largeur = colonnes * largeurVignette + (colonnes + 1) * marge
let hauteur = lignes * hauteurVignette + (lignes + 1) * marge

guard let contexte = CGContext(
    data: nil, width: largeur, height: hauteur,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    FileHandle.standardError.write("contexte impossible\n".data(using: .utf8)!)
    exit(1)
}
contexte.setFillColor(CGColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1))
contexte.fill(CGRect(x: 0, y: 0, width: largeur, height: hauteur))

for (index, url) in entrees.enumerated() {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        FileHandle.standardError.write("illisible : \(url.lastPathComponent)\n"
            .data(using: .utf8)!)
        continue
    }
    let colonne = index % colonnes
    let ligne = index / colonnes
    let x = marge + colonne * (largeurVignette + marge)
    // CoreGraphics part du bas : on remplit de haut en bas.
    let y = hauteur - (marge + (ligne + 1) * hauteurVignette + ligne * marge)
    let cadre = CGRect(x: x, y: y, width: largeurVignette, height: hauteurVignette)

    // Recadrage « couvrant », comme le fera le viseur.
    let echelle = max(CGFloat(largeurVignette) / CGFloat(image.width),
                      CGFloat(hauteurVignette) / CGFloat(image.height))
    let dessinee = CGRect(
        x: cadre.midX - CGFloat(image.width) * echelle / 2,
        y: cadre.midY - CGFloat(image.height) * echelle / 2,
        width: CGFloat(image.width) * echelle,
        height: CGFloat(image.height) * echelle)

    contexte.saveGState()
    contexte.clip(to: cadre)
    contexte.draw(image, in: dessinee)
    contexte.restoreGState()
}

guard let planche = contexte.makeImage(),
      let destination = CGImageDestinationCreateWithURL(
        sortie as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    FileHandle.standardError.write("écriture impossible\n".data(using: .utf8)!)
    exit(1)
}
CGImageDestinationAddImage(destination, planche, nil)
guard CGImageDestinationFinalize(destination) else { exit(1) }
print("✓ \(sortie.path) — \(entrees.count) vignettes, \(colonnes) colonnes")
