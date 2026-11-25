//
//  UIImage+Resize.swift
//  Dropin
//

import UIKit

extension UIImage {

    /// Aspect-fit resize so the longest side equals `maxDimension`. Returns self if already smaller.
    func resized(maxDimension: CGFloat) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return self }
        let scale = maxDimension / longestSide
        let newSize = CGSize(width: (size.width * scale).rounded(),
                             height: (size.height * scale).rounded())
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    /// Resize + JPEG compress, stepping quality down until under `maxDiskSize`.
    /// Returns nil if no encoding could be produced.
    func compressedForStorage(maxDimension: CGFloat = DropinApp.storage.imageMaxSize,
                              maxDiskSize: Int = DropinApp.storage.imageMaxDiskSize) -> Data? {
        let resized = self.resized(maxDimension: maxDimension)
        for quality: CGFloat in [0.8, 0.65, 0.5, 0.35] {
            guard let data = resized.jpegData(compressionQuality: quality) else { continue }
            if data.count <= maxDiskSize { return data }
        }
        return resized.jpegData(compressionQuality: 0.35)
    }

    /// Thumbnail JPEG sized for list/grid display.
    func thumbnailData(size: CGFloat = DropinApp.storage.thumbnailSize,
                       compression: CGFloat = DropinApp.storage.thumbnailCompression) -> Data? {
        let target = CGSize(width: size, height: size)
        let thumb = preparingThumbnail(of: target) ?? self
        return thumb.jpegData(compressionQuality: compression)
    }
}
