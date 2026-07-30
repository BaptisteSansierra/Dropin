//
//  ShapeStyle+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/7/25.
//

import SwiftUI

extension ShapeStyle where Self == Color {
    
    // MARK: - App colors
    static var primaryLight: Color { return Color(rgba: "#588B8B") }
    static var primaryDark: Color { return Color(rgba: "#6FAFB0") }
    static var dropinPrimary: Color { return Color(light: primaryLight, dark: primaryDark) }
    
    static var secondaryLight: Color { return Color(rgba: "#A8657E") }
    static var secondaryDark: Color { return Color(rgba: "#C48CA6") }
    static var dropinSecondary: Color { return Color(light: secondaryLight, dark: secondaryDark) }
    
    static var destructiveLight: Color { Color(rgba: "#D32F2F") }
    static var destructiveDark: Color  { Color(rgba: "#FF6B6B") }
    static var destructive: Color {
        Color(light: destructiveLight, dark: destructiveDark)
    }
    
    static var warningLight: Color { Color(rgba: "#F57C00") }
    static var warningDark: Color  { Color(rgba: "#FFB74D") }
    static var warning: Color {
        Color(light: warningLight, dark: warningDark)
    }
    
    static var successLight: Color { Color(rgba: "#2E7D32") }
    static var successDark: Color  { Color(rgba: "#81C784") }
    static var success: Color {
        Color(light: successLight, dark: successDark)
    }
    
    static var infoLight: Color { Color(rgba: "#1976D2") }
    static var infoDark: Color  { Color(rgba: "#90CAF9") }
    static var info: Color {
        Color(light: infoLight, dark: infoDark)
    }
    
    // MARK: - Texts
    static var textPrimary: Color { Color(light: dark1, dark: light1) }
    static var textSecondary: Color { Color(light: dark2, dark: light4) }
    static var textTertiary: Color { Color(light: dark3, dark: light5) }

    static var disabled: Color {
        Color(light: light4, dark: dark2)
    }
    
    // MARK: - Background
    // screen base
    static var backgroundPrimaryL: Color { Color(rgba: "#F2EADA") }
    static var backgroundPrimaryD: Color { Color(rgba: "#1A1712") }

    static var backgroundPrimary: Color { Color(light: backgroundPrimaryL,
                                                dark: backgroundPrimaryD) }
    // recessed wells / section fills
    static var backgroundSecondary: Color { Color(light: Color(rgba: "#E6DCC8"),
                                                  dark: Color(rgba: "#15110C")) }
    // deepest recess / separators-as-fill
    static var backgroundTertiary: Color { Color(light: Color(rgba: "#DCCFB8"),
                                                 dark: Color(rgba: "#100D0A")) }
    static var overlayAlphaLayer: Color { textTertiary.opacity(0.25) }

    static var fieldBorder: Color { Color(light: Color(rgba: "#E6DCCB"),
                                          dark: Color(rgba: "#38312A")) }
    
    // fields, cards, sheets — the top surface, almost white, it pops on paper
    static var surface1: Color { Color(light: Color(rgba: "#FDFCF8"),
                                       dark: Color(rgba: "#262019")) }
    
    // back-button/icon wells, chips nestled on paper
    static var surface2: Color { Color(light: Color(rgba: "#FBF6EE"),
                                       dark: Color(rgba: "#221E17")) }
    
    // MARK: - Light shades
    static var light1: Color { Color(rgba: "#FAF4EA") } // textPrimary
    static var light2: Color { Color(rgba: "#F4EDDF") }
    static var light3: Color { Color(rgba: "#ECE3D2") }
    static var light4: Color { Color(rgba: "#E3D9C6") } // textSecondary
    static var light5: Color { Color(rgba: "#8A8073") } // textTertiary
    static var light6: Color { Color(rgba: "#4A443B") }

    // MARK: - Dark shades
    static var dark1: Color { Color(rgba: "#1A1712") } // textPrimary
    static var dark2: Color { Color(rgba: "#4A443B") } // textSecondary
    static var dark3: Color { Color(rgba: "#857B6D") } // textTertiary
    static var dark4: Color { Color(rgba: "#CFC3AD") }
    static var dark5: Color { Color(rgba: "#E7DDCB") }
    static var dark6: Color { Color(rgba: "#FAF4EA") }
    
    // MARK: - Shade accessor
    static var shade1: Color { Color(light: light1, dark: dark1) }
    static var shade2: Color { Color(light: light2, dark: dark2) }
    static var shade3: Color { Color(light: light3, dark: dark3) }
    static var shade4: Color { Color(light: light4, dark: dark4) }
    static var shade5: Color { Color(light: light5, dark: dark5) }
    static var shade6: Color { Color(light: light6, dark: dark6) }
}

#if DEBUG

struct ColorsPreview: View {
    
    @State private var dummyTfV: String = ""

    var body: some View {
        HStack {
            content
                .environment(\.colorScheme, .light)
            content
                .environment(\.colorScheme, .dark)
        }
    }
    
    private var content: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: 10) {
                HStack {
                    Rectangle()
                        .foregroundStyle(.shade1)
                        .border(.textPrimary)
                        .frame(width: 20, height: 20)
                    Rectangle()
                        .foregroundStyle(.shade2)
                        .border(.textPrimary)
                        .frame(width: 20, height: 20)
                    Rectangle()
                        .foregroundStyle(.shade3)
                        .border(.textPrimary)
                        .frame(width: 20, height: 20)
                    Rectangle()
                        .foregroundStyle(.shade4)
                        .border(.textPrimary)
                        .frame(width: 20, height: 20)
                    Rectangle()
                        .foregroundStyle(.shade5)
                        .border(.textPrimary)
                        .frame(width: 20, height: 20)
                    Rectangle()
                        .foregroundStyle(.shade6)
                        .border(.textPrimary)
                        .frame(width: 20, height: 20)
                }
                Text(verbatim: "dropinPrimary")
                    .fontWeight(.bold)
                    .foregroundStyle(.primaryLight)
                Text(verbatim: "dropinSecondary")
                    .fontWeight(.bold)
                    .foregroundStyle(.secondaryLight)
                Text(verbatim: "textPrimary")
                    .fontWeight(.bold)
                    .foregroundStyle(.textPrimary)
                Text(verbatim: "textSecondary")
                    .fontWeight(.bold)
                    .foregroundStyle(.textSecondary)
                Text(verbatim: "textTertiary")
                    .fontWeight(.bold)
                    .foregroundStyle(.textTertiary)
                
                ZStack {
                    Rectangle()
                        .frame(width: 150, height: 45)
                        .border(.textPrimary, width: 1)
                        .foregroundStyle(.backgroundPrimary)
                    Text(verbatim: "BG primary")
                        .fontWeight(.bold)
                        .foregroundStyle(.textPrimary)
                }
                ZStack {
                    Rectangle()
                        .frame(width: 150, height: 45)
                        .border(.textPrimary, width: 1)
                        .foregroundStyle(.backgroundSecondary)
                    Text(verbatim: "BG secondary")
                        .fontWeight(.bold)
                        .foregroundStyle(.textPrimary)
                }
                ZStack {
                    Rectangle()
                        .frame(width: 150, height: 45)
                        .border(.textPrimary, width: 1)
                        .foregroundStyle(.backgroundTertiary)
                    Text(verbatim: "BG tertiary")
                        .fontWeight(.bold)
                        .foregroundStyle(.textPrimary)
                }
                
                Text(verbatim: "destructive")
                    .fontWeight(.bold)
                    .foregroundStyle(.destructive)
                Text(verbatim: "warning")
                    .fontWeight(.bold)
                    .foregroundStyle(.warning)
                Text(verbatim: "success")
                    .fontWeight(.bold)
                    .foregroundStyle(.success)
                Text(verbatim: "disabled")
                    .fontWeight(.bold)
                    .foregroundStyle(.disabled)
                Text(verbatim: "info")
                    .fontWeight(.bold)
                    .foregroundStyle(.infoLight)

                TextField("empty", text: $dummyTfV)

            }
        }
    }
}

#Preview {
    ColorsPreview()
}

#endif
