//
//  PlaceImagesTabView.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import SwiftUI

struct PlaceImagesTabView: View {

    private let thumbnails: [(id: UUID, thumbnail: Data)]
    private let onTapImage: (Int) -> Void
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]

    init(thumbnails: [(id: UUID, thumbnail: Data)], onTapImage: @escaping (Int) -> Void) {
        self.thumbnails = thumbnails
        self.onTapImage = onTapImage
    }
    
    var body: some View {
        if thumbnails.isEmpty {
            ContentUnavailableView("placeholder.no_images.title",
                                   systemImage: "photo.on.rectangle",
                                   description: Text("placeholder.no_images.body"))
                .padding(.top, 20)
        } else {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(thumbnails.enumerated()), id: \.element.id) { index, item in
                    Button {
                        onTapImage(index)
                    } label: {
                        if let image = UIImage(data: item.thumbnail) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(minWidth: 100, minHeight: 100)
                                .clipped()
                        } else {
                            Color.backgroundSecondary
                                .frame(height: 100)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

#Preview {
    let thumbnails: [(UUID, Data)] =
    [
        (UUID(), UIImage.random(square: DropinApp.storage.thumbnailSize)
                        .jpegData(compressionQuality: DropinApp.storage.thumbnailCompression)!),
        (UUID(), UIImage.rdGeo(square: DropinApp.storage.thumbnailSize)
                        .jpegData(compressionQuality: DropinApp.storage.thumbnailCompression)!),
        (UUID(), UIImage.random(square: DropinApp.storage.thumbnailSize)
                        .jpegData(compressionQuality: DropinApp.storage.thumbnailCompression)!),
        (UUID(), UIImage.constant(size: CGSize(square: DropinApp.storage.thumbnailSize),
                                  color: .purple)
                        .jpegData(compressionQuality: DropinApp.storage.thumbnailCompression)!),
    ]
    PlaceImagesTabView(thumbnails: thumbnails,
                       onTapImage: { _ in })
}
