//
//  SpectrumColorPickerImageGenerator.swift
//  Dropin
//

import UIKit

/// Renders a SpectrumColorPickerView gradient (hue vertically, lightness horizontally, fixed saturation) to a PNG written into Documents folder
/// Used to pre-bake the per-saturation-step images the picker `SpectrumColorPickerView` loads
enum SpectrumColorPickerImageGenerator {

    enum GeneratorError: Error {
        case imageCreationFailed
        case pngEncodingFailed
    }

    static let resolution = 256

    static func fileURL(lightnessRange: ClosedRange<Double>, saturation: Double) -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName(lightnessRange: lightnessRange, saturation: saturation))
    }

    static func fileName(lightnessRange: ClosedRange<Double>, saturation: Double) -> String {
        let lo = Int((lightnessRange.lowerBound * 100).rounded())
        let hi = Int((lightnessRange.upperBound * 100).rounded())
        let s = Int((saturation * 100).rounded())
        return "SpectrumColorPicker_L\(lo)-\(hi)_S\(s).png"
    }

    @discardableResult
    static func generate(lightnessRange: ClosedRange<Double>, saturation: Double) throws -> URL {
        let width = resolution
        let height = resolution
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            let hue = Double(y) / Double(height - 1) * 360
            for x in 0..<width {
                let t = Double(x) / Double(width - 1)
                let lightness = lightnessRange.upperBound - t * (lightnessRange.upperBound - lightnessRange.lowerBound)
                let rgb = hslToRGB(h: hue, s: saturation, l: lightness)
                let idx = (y * width + x) * 4
                pixels[idx]     = UInt8(clamping: Int((rgb.r * 255).rounded()))
                pixels[idx + 1] = UInt8(clamping: Int((rgb.g * 255).rounded()))
                pixels[idx + 2] = UInt8(clamping: Int((rgb.b * 255).rounded()))
                pixels[idx + 3] = 255
            }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let cgImage = CGImage(width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bitsPerPixel: 32,
                                    bytesPerRow: width * 4,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                                    provider: provider,
                                    decode: nil,
                                    shouldInterpolate: true,
                                    intent: .defaultIntent) else {
            throw GeneratorError.imageCreationFailed
        }
        guard let pngData = UIImage(cgImage: cgImage).pngData() else {
            throw GeneratorError.pngEncodingFailed
        }
        let url = fileURL(lightnessRange: lightnessRange, saturation: saturation)
        try pngData.write(to: url, options: .atomic)
        return url
    }

    // MARK: - HSL -> RGB

    static func hslToRGB(h: Double, s: Double, l: Double) -> (r: Double, g: Double, b: Double) {
        let c = (1 - abs(2 * l - 1)) * s
        let hPrime = h / 60
        let x = c * (1 - abs(hPrime.truncatingRemainder(dividingBy: 2) - 1))
        let (r1, g1, b1): (Double, Double, Double)
        switch hPrime {
            case 0..<1: (r1, g1, b1) = (c, x, 0)
            case 1..<2: (r1, g1, b1) = (x, c, 0)
            case 2..<3: (r1, g1, b1) = (0, c, x)
            case 3..<4: (r1, g1, b1) = (0, x, c)
            case 4..<5: (r1, g1, b1) = (x, 0, c)
            case 5..<6: (r1, g1, b1) = (c, 0, x)
            default:    (r1, g1, b1) = (0, 0, 0)
        }
        let m = l - c / 2
        return (r1 + m, g1 + m, b1 + m)
    }
}
