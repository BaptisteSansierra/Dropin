//
//  ShapeStyle+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/7/25.
//

import SwiftUI

extension ShapeStyle where Self == Color {
    
//    static var dropinPrimary: Color { return Color(rgba: "#62899e") }
//    static var dropinSecondary: Color { return Color(rgba: "#E1C16E") }

//    static var dropinPrimary: Color { return Color(rgba: "#1E40AF") }
//    static var dropinSecondary: Color { return Color(rgba: "#F97316") }
//    static var dropinTertiary: Color { return Color(rgba: "#E5E7EB") }
    
    // MARK: - App colors
    static var primaryLight: Color { return Color(rgba: "#588B8B") }
    static var primaryDark: Color { return Color(rgba: "#6FAFB0") }
    static var dropinPrimary: Color { return Color(light: primaryLight, dark: primaryDark) }
    
    static var secondaryLight: Color { return Color(rgba: "#A01A58") }
    static var secondaryDark: Color { return Color(rgba: "#C14C84") }
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
    
//    static var textPrimaryLight: Color { return Color(rgba: "#000000") }
//    static var textPrimaryDark: Color { return Color(rgba: "#FFFFFF") }
//    static var textPrimary: Color { return Color(light: textPrimaryLight, dark: textPrimaryDark) }
//
//    static var textSecondaryLight: Color { return Color(rgba: "#000000") }
//    static var textSecondaryDark: Color { return Color(rgba: "#FFFFFF") }
//    static var textSecondary: Color { return Color(light: textSecondaryLight, dark: textSecondaryDark) }

    // MARK: - Texts
    static var textPrimaryLight: Color { Color(rgba: "#111111") }
    static var textPrimaryDark: Color  { Color(rgba: "#F5F5F5") }
    static var textPrimary: Color {
        Color(light: textPrimaryLight, dark: textPrimaryDark)
    }

    static var textSecondaryLight: Color { Color(rgba: "#444444") }
    static var textSecondaryDark: Color  { Color(rgba: "#C7C7C7") }
    static var textSecondary: Color {
        Color(light: textSecondaryLight, dark: textSecondaryDark)
    }

    static var textTertiaryLight: Color { Color(rgba: "#7A7A7A") }
    static var textTertiaryDark: Color  { Color(rgba: "#8E8E8E") }
    static var textTertiary: Color {
        Color(light: textTertiaryLight, dark: textTertiaryDark)
    }
    
    static var disabledLight: Color { Color(rgba: "#BDBDBD") }
    static var disabledDark: Color  { Color(rgba: "#5A5A5A") }
    static var disabled: Color {
        Color(light: disabledLight, dark: disabledDark)
    }
    
    static var overlayAlphaLayer: Color { textTertiary.opacity(0.25) }

    
    /*
    static var textPrimaryLight: Color { Color(rgba: "#0B1F1F") }      // near-black teal
    static var textPrimaryDark: Color  { Color(rgba: "#E6F0F0") }      // near-white teal
    static var textPrimary: Color {
        Color(light: textPrimaryLight, dark: textPrimaryDark)
    }

    static var textSecondaryLight: Color { Color(rgba: "#3F5F5F") }    // muted
    static var textSecondaryDark: Color  { Color(rgba: "#A9C6C6") }
    static var textSecondary: Color {
        Color(light: textSecondaryLight, dark: textSecondaryDark)
    }

    static var textTertiaryLight: Color { Color(rgba: "#7A9A9A") }     // hints / metadata
    static var textTertiaryDark: Color  { Color(rgba: "#6F8F8F") }
    static var textTertiary: Color {
        Color(light: textTertiaryLight, dark: textTertiaryDark)
    }
     */
    
    // MARK: - Background
    static var backgroundPrimaryLight: Color { Color(rgba: "#FFFFFF") }
    static var backgroundPrimaryDark: Color  { Color(rgba: "#000000") }
    static var backgroundPrimary: Color {
        Color(light: backgroundPrimaryLight, dark: backgroundPrimaryDark)
    }

    static var backgroundSecondaryLight: Color { Color(rgba: "#F2F2F2") }
    static var backgroundSecondaryDark: Color  { Color(rgba: "#1C1C1E") }
    static var backgroundSecondary: Color {
        Color(light: backgroundSecondaryLight, dark: backgroundSecondaryDark)
    }

    static var backgroundTertiaryLight: Color { Color(rgba: "#E5E5E5") }
    static var backgroundTertiaryDark: Color  { Color(rgba: "#2C2C2E") }
    static var backgroundTertiary: Color {
        Color(light: backgroundTertiaryLight, dark: backgroundTertiaryDark)
    }
    /*
    static var backgroundPrimaryLight: Color { Color(rgba: "#FFFFFF") }
    static var backgroundPrimaryDark: Color  { Color(rgba: "#0F1C1C") }
    static var backgroundPrimary: Color {
        Color(light: backgroundPrimaryLight, dark: backgroundPrimaryDark)
    }

    static var backgroundSecondaryLight: Color { Color(rgba: "#F3F7F7") } // cards / lists
    static var backgroundSecondaryDark: Color  { Color(rgba: "#1E2F2F") }
    static var backgroundSecondary: Color {
        Color(light: backgroundSecondaryLight, dark: backgroundSecondaryDark)
    }

    static var backgroundTertiaryLight: Color { Color(rgba: "#E4EEEE") }  // separators
    static var backgroundTertiaryDark: Color  { Color(rgba: "#2A3F3F") }
    static var backgroundTertiary: Color {
        Color(light: backgroundTertiaryLight, dark: backgroundTertiaryDark)
    }*/
}

#Preview {
    HStack() {
        ZStack {
            Color(rgba: "FFFFFF").ignoresSafeArea()
            VStack(spacing: 10) {
                Text("dropinPrimary")
                    .fontWeight(.bold)
                    .foregroundStyle(.primaryLight)
                Text("dropinSecondary")
                    .fontWeight(.bold)
                    .foregroundStyle(.secondaryLight)
                Text("textPrimary")
                    .fontWeight(.bold)
                    .foregroundStyle(.textPrimaryLight)
                Text("textSecondary")
                    .fontWeight(.bold)
                    .foregroundStyle(.textSecondaryLight)
                Text("textTertiary")
                    .fontWeight(.bold)
                    .foregroundStyle(.textTertiaryLight)
                
                ZStack {
                    Rectangle()
                        .frame(width: 150, height: 45)
                        .border(.backgroundPrimaryDark, width: 1)
                        .foregroundStyle(.backgroundPrimaryLight)
                    Text("BG primary")
                        .fontWeight(.bold)
                        .foregroundStyle(.textPrimaryLight)
                }
                ZStack {
                    Rectangle()
                        .frame(width: 150, height: 45)
                        .border(.backgroundPrimaryDark, width: 1)
                        .foregroundStyle(.backgroundSecondaryLight)
                    Text("BG secondary")
                        .fontWeight(.bold)
                        .foregroundStyle(.textPrimaryLight)
                }
                ZStack {
                    Rectangle()
                        .frame(width: 150, height: 45)
                        .border(.backgroundPrimaryDark, width: 1)
                        .foregroundStyle(.backgroundTertiaryLight)
                    Text("BG tertiary")
                        .fontWeight(.bold)
                        .foregroundStyle(.textPrimaryLight)
                }
                
                Text("destructive")
                    .fontWeight(.bold)
                    .foregroundStyle(.destructiveLight)
                Text("warning")
                    .fontWeight(.bold)
                    .foregroundStyle(.warningLight)
                Text("success")
                    .fontWeight(.bold)
                    .foregroundStyle(.successLight)
                Text("disabled")
                    .fontWeight(.bold)
                    .foregroundStyle(.disabledLight)
                Text("info")
                    .fontWeight(.bold)
                    .foregroundStyle(.infoLight)
            }
        }
        ZStack {
            Color(rgba: "0000").ignoresSafeArea()
            VStack(spacing: 10) {
                Text("dropinPrimary")
                    .fontWeight(.bold)
                    .foregroundStyle(.primaryDark)
                Text("dropinSecondary")
                    .fontWeight(.bold)
                    .foregroundStyle(.secondaryDark)
                Text("textPrimary")
                    .fontWeight(.bold)
                    .foregroundStyle(.textPrimaryDark)
                Text("textSecondary")
                    .fontWeight(.bold)
                    .foregroundStyle(.textSecondaryDark)
                Text("textTertiary")
                    .fontWeight(.bold)
                    .foregroundStyle(.textTertiaryDark)
                
                ZStack {
                    Rectangle()
                        .frame(width: 150, height: 45)
                        .border(.backgroundPrimaryLight, width: 1)
                        .foregroundStyle(.backgroundPrimaryDark)
                    Text("BG primary")
                        .fontWeight(.bold)
                        .foregroundStyle(.textPrimaryDark)
                }
                ZStack {
                    Rectangle()
                        .frame(width: 150, height: 45)
                        .border(.backgroundPrimaryLight, width: 1)
                        .foregroundStyle(.backgroundSecondaryDark)
                    Text("BG secondary")
                        .fontWeight(.bold)
                        .foregroundStyle(.textPrimaryDark)
                }
                ZStack {
                    Rectangle()
                        .frame(width: 150, height: 45)
                        .border(.backgroundPrimaryLight, width: 1)
                        .foregroundStyle(.backgroundTertiaryDark)
                    Text("BG tertiary")
                        .fontWeight(.bold)
                        .foregroundStyle(.textPrimaryDark)
                }

                Text("destructive")
                    .fontWeight(.bold)
                    .foregroundStyle(.destructiveDark)
                Text("warning")
                    .fontWeight(.bold)
                    .foregroundStyle(.warningDark)
                Text("success")
                    .fontWeight(.bold)
                    .foregroundStyle(.successDark)
                Text("disabled")
                    .fontWeight(.bold)
                    .foregroundStyle(.disabledDark)
                Text("info")
                    .fontWeight(.bold)
                    .foregroundStyle(.infoDark)
            }
        }
    }
}
