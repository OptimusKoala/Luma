#!/usr/bin/env swift
// Réécrit un PNG sans canal alpha, en place.
//
//   swift scripts/aplatir-png.swift capture.png [autre.png …]
//
// Les captures du simulateur portent un canal alpha, alors que l'App Store
// refuse toute transparence. L'image est redessinée dans un contexte opaque
// (noneSkipLast) : les pixels ne changent pas, seul le canal disparaît.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

func aplatir(_ chemin: String) -> Bool {
    let url = URL(fileURLWithPath: chemin)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        FileHandle.standardError.write("✗ illisible : \(chemin)\n".data(using: .utf8)!)
        return false
    }

    let largeur = image.width, hauteur = image.height
    guard let contexte = CGContext(
        data: nil, width: largeur, height: hauteur,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        // noneSkipLast : quatre octets par pixel, dont le dernier est ignoré.
        // Le PNG produit n'a donc pas de canal alpha.
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        FileHandle.standardError.write("✗ contexte impossible : \(chemin)\n".data(using: .utf8)!)
        return false
    }

    contexte.draw(image, in: CGRect(x: 0, y: 0, width: largeur, height: hauteur))

    guard let aplati = contexte.makeImage(),
          let destination = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        FileHandle.standardError.write("✗ écriture impossible : \(chemin)\n".data(using: .utf8)!)
        return false
    }
    CGImageDestinationAddImage(destination, aplati, nil)
    return CGImageDestinationFinalize(destination)
}

let chemins = Array(CommandLine.arguments.dropFirst())
guard !chemins.isEmpty else {
    print("usage: swift scripts/aplatir-png.swift <fichier.png> …")
    exit(2)
}
exit(chemins.allSatisfy(aplatir) ? 0 : 1)
