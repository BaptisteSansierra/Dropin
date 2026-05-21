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
    /*
//    static var textPrimaryLight: Color { Color(rgba: "#111111") }
//    static var textPrimaryDark: Color  { Color(rgba: "#F5F5F5") }
    static var textPrimaryLight: Color { .dark1 }
    static var textPrimaryDark: Color  { .light1 }
    static var textPrimary: Color {
        Color(light: textPrimaryLight, dark: textPrimaryDark)
    }
    
//    static var textSecondaryLight: Color { Color(rgba: "#444444") }
//    static var textSecondaryDark: Color  { Color(rgba: "#C7C7C7") }
    static var textSecondaryLight: Color { .light5 }
    static var textSecondaryDark: Color  { .dark4 }
    static var textSecondary: Color {
        Color(light: textSecondaryLight, dark: textSecondaryDark)
    }
    
//    static var textTertiaryLight: Color { Color(rgba: "#7A7A7A") }
//    static var textTertiaryDark: Color  { Color(rgba: "#8E8E8E") }
    static var textTertiaryLight: Color { .light4 }
    static var textTertiaryDark: Color  { .light5 }
    static var textTertiary: Color {
        Color(light: textTertiaryLight, dark: textTertiaryDark)
    }
    */
    
    //static var disabledLight: Color { Color(rgba: "#BDBDBD") }
    //static var disabledDark: Color  { Color(rgba: "#5A5A5A") }
    static var disabled: Color {
        Color(light: light4, dark: dark2)
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
    /*
    static var backgroundPrimaryLight: Color { .light1 /*Color(rgba: "#F5F5F5")*/ }
    static var backgroundPrimaryDark: Color  { .dark1 /*Color(rgba: "#000000")*/ }
    static var backgroundPrimary: Color {
        Color(light: backgroundPrimaryLight, dark: backgroundPrimaryDark)
    }
    
    static var backgroundSecondaryLight: Color { .light2 /*Color(rgba: "#F2F2F2")*/ }
    static var backgroundSecondaryDark: Color  { .dark2 /*Color(rgba: "#1C1C1E")*/ }
    //static var backgroundSecondaryDark: Color  { Color(rgba: "#1C1C1E") }
    static var backgroundSecondary: Color {
        Color(light: backgroundSecondaryLight, dark: backgroundSecondaryDark)
    }
    
//    static var backgroundTertiaryLight: Color { Color(rgba: "#E5E5E5") }
//    static var backgroundTertiaryDark: Color  { Color(rgba: "#2C2C2E") }
    static var backgroundTertiaryLight: Color { .light3 }
    static var backgroundTertiaryDark: Color  { .dark3 }
    static var backgroundTertiary: Color {
        Color(light: backgroundTertiaryLight, dark: backgroundTertiaryDark)
    }
     */
    
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
    
//    static var textPrimary: Color { shade1 }
//    static var textSecondary: Color { shade3 }
//    static var textTertiary: Color { shade4 }
//    
//    static var backgroundPrimary: Color { Color(light: dark1, dark: light1) }
//    static var backgroundSecondary: Color { Color(light: dark2, dark: light2) }
//    static var backgroundTertiary: Color { Color(light: dark3, dark: light3) }

    #if true
    static var backgroundPrimary: Color { shade1 }
    static var backgroundSecondary: Color { shade3 }
    static var backgroundTertiary: Color { shade4 }
    
    static var textPrimary: Color { Color(light: dark1, dark: light1) }
    static var textSecondary: Color { Color(light: dark2, dark: light4) }
    static var textTertiary: Color { Color(light: dark3, dark: light5) }
    #else
    static var backgroundPrimary: Color { Color(uiColor: UIColor.systemBackground) }
    static var backgroundSecondary: Color { Color(uiColor: UIColor.secondarySystemBackground) }
    static var backgroundTertiary: Color { Color(uiColor: UIColor.systemFill) }
    
    static var textPrimary: Color { Color(uiColor: UIColor.label) }
    static var textSecondary: Color { Color(uiColor: UIColor.secondaryLabel) }
    static var textTertiary: Color { Color(uiColor: UIColor.tertiaryLabel) }
    #endif

    // MARK: - Light shades
    static var light1: Color { Color(rgba: "#FFFFFF") }
    static var light2: Color { Color(rgba: "#F5F5F5") }
    static var light3: Color { Color(rgba: "#E5E5E5") }
    static var light4: Color { Color(rgba: "#C7C7C7") }
    static var light5: Color { Color(rgba: "#7A7A7A") }
    static var light6: Color { Color(rgba: "#444444") }

    // MARK: - Dark shades
    static var dark1: Color { Color(rgba: "#111111") }
    static var dark2: Color { Color(rgba: "#444444") }
    static var dark3: Color { Color(rgba: "#7A7A7A") }
    static var dark4: Color { Color(rgba: "#C7C7C7") }
    static var dark5: Color { Color(rgba: "#E5E5E5") }
    static var dark6: Color { Color(rgba: "#FFFFFF") }

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
            }

        }
    }
}

#Preview {
    ColorsPreview()
}

#endif
