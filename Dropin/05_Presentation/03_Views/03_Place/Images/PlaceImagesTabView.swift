//
//  PlaceImagesTabView.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import SwiftUI

struct PlaceImagesTabView: View {

    private let thumbnails: [(id: UUID, state: ImageLoadState)]
    private let onTapImage: (Int) -> Void
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]

    init(thumbnails: [(id: UUID, state: ImageLoadState)], onTapImage: @escaping (Int) -> Void) {
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
                        if case .cached = item.state { onTapImage(index) }
                    } label: {
                        cell(for: item.state)
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .disabled(!isCached(item.state))
                }
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private func cell(for state: ImageLoadState) -> some View {
        switch state {
        case .cached(let data):
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 100, minHeight: 100)
                    .clipped()
            } else {
                placeholder(systemName: "photo")
            }
        case .downloading:
            ZStack {
                Color.backgroundSecondary
                ProgressView()
            }
            .frame(minWidth: 100, minHeight: 100)
        case .failed:
            placeholder(systemName: "exclamationmark.triangle")
        case .missing:
            placeholder(systemName: "trash")
        }
    }

    private func placeholder(systemName: String) -> some View {
        ZStack {
            Color.backgroundSecondary
            Image(systemName: systemName)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 100, minHeight: 100)
    }

    private func isCached(_ state: ImageLoadState) -> Bool {
        if case .cached = state { return true }
        return false
    }
}

#Preview {
    let sample: [(UUID, ImageLoadState)] = [
        (UUID(), .cached(UIImage.random(square: DropinApp.storage.thumbnailSize)
                            .jpegData(compressionQuality: DropinApp.storage.thumbnailCompression)!)),
        (UUID(), .downloading),
        (UUID(), .failed),
        (UUID(), .cached(UIImage.constant(size: CGSize(square: DropinApp.storage.thumbnailSize),
                                          color: .purple)
                            .jpegData(compressionQuality: DropinApp.storage.thumbnailCompression)!)),
    ]
    PlaceImagesTabView(thumbnails: sample, onTapImage: { _ in })
}
