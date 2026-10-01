//
//  SpectrumColorPickerView.swift
//  Dropin
//

import SwiftUI

/// Custom color picker: a 2D spectrum image (hue vertically, lightness horizontally) at the current saturation
/// Displays a draggable selector circle and a saturation slider
/// The gradient images are static assets generated for luminance in  [0.25, 0.75] :
///   "SpectrumColorPicker_S000" ... "SpectrumColorPicker_S100",  in xcassets
///
/// In case assets need to be generated again `SpectrumColorPickerImageGenerator` can be used
///
struct SpectrumColorPickerView: View {

    @Binding var color: Color
    /// Lightness range mapped across the horizontal axis: left = `upperBound` (lighter), right = `lowerBound` (darker).
    /// Must match the range the "SpectrumColorPicker_S*" assets were generated with.
    var lightnessRange: ClosedRange<Double> = 0.25...0.75

    private static let circleDiameter: CGFloat = 26
    /// Granularity of the pre-baked saturation step assets.
    /// WARNING: saturation image set is generated given this step, not to be changed without generating again
    private static let saturationStep: Double = 0.05

    @State private var position: CGPoint = .zero
    @State private var saturation: Double = 1.0
    @State private var imageSize: CGSize = .zero
    /// True while `color` is being written by this view itself (drag or saturation slider)
    @State private var isInternalUpdate = false
    
    private var saturationBinding: Binding<Double> {
        Binding(get: {
            saturation
        }, set: { newValue in
            updateSaturation(newValue)
        })
    }

    var body: some View {
        VStack(spacing: 16) {
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    Image(Self.assetName(for: saturation))
                        .resizable()
                        .frame(width: geo.size.width, height: geo.size.height)
                    Circle()
                        .strokeBorder(.white, lineWidth: 2)
                        .background(Circle().fill(color))
                        .frame(width: Self.circleDiameter, height: Self.circleDiameter)
                        .shadow(radius: 1)
                        .position(position)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updatePosition(value.location, in: geo.size)
                        }
                )
                .onAppear {
                    imageSize = geo.size
                    saturation = Self.extractSaturation(for: color)
                    position = Self.circlePosition(for: color, in: geo.size, lightnessRange: lightnessRange)
                }
                .onChange(of: geo.size) { _, newSize in
                    imageSize = newSize
                    position = Self.circlePosition(for: color, in: newSize, lightnessRange: lightnessRange)
                }
                .onChange(of: color) { _, newColor in
                    guard !isInternalUpdate else { return }
                    saturation = Self.extractSaturation(for: newColor)
                    position = Self.circlePosition(for: newColor, in: geo.size, lightnessRange: lightnessRange)
                }
            }
            HStack(spacing: 20) {
                Text("common.saturation")
                    .textStyle(.body)
                Slider(value: saturationBinding,
                       in: 0...1,
                       step: Self.saturationStep) {
                    Text("common.saturation")
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("1")
                }
            }
            .tint(.dropinPrimary)
        }
    }

    private func updatePosition(_ location: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let clamped = CGPoint(x: min(max(location.x, 0), size.width),
                              y: min(max(location.y, 0), size.height))
        position = clamped
        isInternalUpdate = true
        color = Self.makeColor(at: clamped, in: size, saturation: saturation, lightnessRange: lightnessRange)
        isInternalUpdate = false
    }

    private func updateSaturation(_ newValue: Double) {
        saturation = newValue
        isInternalUpdate = true
        color = Self.makeColor(at: position, in: imageSize, saturation: newValue, lightnessRange: lightnessRange)
        isInternalUpdate = false
    }

    /// Get asset catalog name for the nearest saturation step, e.g. "SpectrumColorPicker_S065".
    private static func assetName(for saturation: Double) -> String {
        let stepped = (saturation / saturationStep).rounded() * saturationStep
        let pct = Int((stepped * 100).rounded())
        return "SpectrumColorPicker_S\(String(format: "%03d", pct))"
    }

    // MARK: - Position <-> Color

    private static func makeColor(at point: CGPoint, in size: CGSize, saturation: Double, lightnessRange: ClosedRange<Double>) -> Color {
        let hue = Double(point.y / size.height) * 360
        let t = Double(point.x / size.width)
        let lightness = lightnessRange.upperBound - t * (lightnessRange.upperBound - lightnessRange.lowerBound)
        let rgb = hslToRGB(h: hue, s: saturation, l: lightness)
        return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
    }

    /// Inverse mapping, used to place the circle for an existing color (can be provided externally)
    private static func circlePosition(for color: Color,
                                       in size: CGSize,
                                       lightnessRange: ClosedRange<Double>) -> CGPoint {
        guard size.width > 0, size.height > 0 else { return .zero }
        let rgba = color.rgba
        let hsl = rgbToHSL(r: rgba.r, g: rgba.g, b: rgba.b)
        let y = (hsl.h / 360) * size.height
        let span = lightnessRange.upperBound - lightnessRange.lowerBound
        let t = span > 0 ? (lightnessRange.upperBound - hsl.l) / span : 0
        let x = min(max(t, 0), 1) * size.width
        return CGPoint(x: x, y: y)
    }

    private static func extractSaturation(for color: Color) -> Double {
        let rgba = color.rgba
        return rgbToHSL(r: rgba.r, g: rgba.g, b: rgba.b).s
    }

    // MARK: - HSL <-> RGB

    private static func hslToRGB(h: Double, s: Double, l: Double) -> (r: Double, g: Double, b: Double) {
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

    private static func rgbToHSL(r: Double, g: Double, b: Double) -> (h: Double, s: Double, l: Double) {
        let maxV = max(r, g, b)
        let minV = min(r, g, b)
        let l = (maxV + minV) / 2
        let delta = maxV - minV
        guard delta > 0.0001 else { return (0, 0, l) }

        let s = delta / (1 - abs(2 * l - 1))
        var h: Double
        if maxV == r {
            h = 60 * (((g - b) / delta).truncatingRemainder(dividingBy: 6))
        } else if maxV == g {
            h = 60 * (((b - r) / delta) + 2)
        } else {
            h = 60 * (((r - g) / delta) + 4)
        }
        if h < 0 { h += 360 }
        return (h, s, l)
    }
}
