//
//  IcoExporter.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/1/26.
//

import SwiftUI

struct IcoExporterView: View {
    
    var variant: DropinLogo.Variant
    var imageSize: CGFloat
    var bgColor: Color

    var body: some View {
        ZStack {
            bgColor
                .ignoresSafeArea()
            DropinLogo(variant: variant)
                .padding(imageSize / 10)
                .frame(width: imageSize, height: imageSize)
        }
    }
    
    init(variant: DropinLogo.Variant, imageSize: CGFloat, bgColor: Color) {
        self.variant = variant
        self.imageSize = imageSize
        self.bgColor = bgColor
    }
}

@MainActor
func IcoRenderer(variant: DropinLogo.Variant = .logo,
                 colorScheme: ColorScheme = .light,
                 imageSize: CGFloat = 1024,
                 bgColor: Color = .white) {
    let view = IcoExporterView(variant: variant,
                               imageSize: imageSize,
                               bgColor: bgColor)
        .environment(\.colorScheme, colorScheme)

    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0
    guard let uiImage = renderer.uiImage else {
        fatalError("no UIImage")
    }
    guard let data = uiImage.pngData() else {
        fatalError("Renderer error")
    }
    let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = docsURL.appendingPathComponent("export_\(variant)_\(colorScheme)_\(imageSize)_.png")

    do {
        try data.write(to: fileURL)
    } catch {
        fatalError("Write error \(error)")
    }
    Log.info("Image saved at :\(fileURL)")
}
