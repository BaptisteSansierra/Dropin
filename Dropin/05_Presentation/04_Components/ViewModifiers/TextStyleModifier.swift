//
//  TextStyleModifier.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/1/26.
//

import SwiftUI

///
/// Define app font semantics
///

enum TextStyle: String, CaseIterable {
    case title
    case title2
    case authTitle
    case body
    case bodySemibold
    case bodyWarning
    case bodyError
    case bodyInfo
    case subheadline
    case caption
    case caption2
    case placeholder
    case fieldPlaceholder
    case link
    case mainButton
    case secondaryButton
    case smallButton
    case xSmallButton
    case stringFieldTitle
    case stringFieldContent
    case cellTitle
    case cellSubtitle
    case cellDetail
    case tagSticker
    case groupSticker
    case groupStickerSmall
    case groupStickerBig
    case formSectionTitle
    case formSectionTitle2
    case avatarLarge
    case avatarSmall
    case profileName
    case sidebarTitle
    case sidebarSubtitle
    case tabBarTxt
    case tabBarImg
    case formFieldError
    case keyboardToolbarAction
    case cardAction
    case cardPlaceholder
    case cardDescription
    case settingTitle
    case settingTitleAction
    case settingValue

    var font: Font {
        return values.0
    }
    
    var color: Color {
        return values.1 ?? .textPrimary
    }

    var tracking: CGFloat? {
        return values.2
    }
    
    var lineSpacing: CGFloat? {
        return values.3
    }

    private var values: (Font, Color?, CGFloat?, CGFloat?) {
        switch self {
            case .title:
                (Font.titleRegular, nil, nil, nil)
            case .title2:
                (Font.title2Regular, nil, nil, nil)
            case .authTitle:
                (Font.titleBold, nil, -0.4, nil)
            case .body:
                (Font.bodyRegular, nil, nil, nil)
            case .bodySemibold:
                (Font.bodySemibold, nil, nil, nil)
            case .bodyWarning:
                (Font.bodyBold, Color.warning, nil, nil)
            case .bodyError:
                (Font.bodyBold, Color.destructive, nil, nil)
            case .bodyInfo:
                (Font.bodyBold, Color.info, nil, nil)
            case .subheadline:
                (Font.subheadlineRegular, nil, nil, nil)
            case .caption:
                (Font.captionRegular, nil, nil, nil)
            case .caption2:
                (Font.caption2Regular, nil, nil, nil)
            case .placeholder:
                (Font.calloutRegular, Color.textSecondary, nil, nil)
            case .fieldPlaceholder:
                (Font.bodyRegular, Color.textTertiary, nil, nil)
            case .link:
                (Font.subheadlineSemibold, Color.dropinSecondary, nil, nil)
            case .mainButton:
                (Font.bodySemibold, Color.dropinPrimary, nil, nil)
            case .secondaryButton:
                (Font.bodySemibold, Color.dropinPrimary, nil, nil)
            case .smallButton:
                (Font.subheadlineSemibold, Color.dropinPrimary, nil, nil)
            case .xSmallButton:
                (Font.captionSemibold, Color.dropinPrimary, nil, nil)
            case .stringFieldTitle:
                (Font.subheadlineRegular, Color.textSecondary, nil, nil)
            case .stringFieldContent:
                (Font.bodyRegular, nil, nil, nil)
            case .cellTitle:
                (Font.bodyMedium, nil, nil, nil)
            case .cellSubtitle:
                (Font.captionRegular, Color.textSecondary, nil, nil)
            case .cellDetail:
                (Font.captionRegular, nil, nil, nil)
            case .tagSticker:
                (Font.footnoteBold, Color.backgroundPrimary, nil, nil)
            case .groupStickerBig:
                (Font.bodySemibold, nil, nil, nil)
            case .groupSticker:
                (Font.bodyMedium, nil, nil, nil)
            case .groupStickerSmall:
                (Font.captionMedium, nil, nil, nil)
            case .formSectionTitle:
                (Font.bodySemibold, Color.textTertiary, nil, nil)
            case .formSectionTitle2:
                (Font.captionMedium, Color.textTertiary, nil, nil)
            case .avatarLarge:
                (Font._32Semibold, nil, nil, nil)
            case .avatarSmall:
                (Font.calloutSemibold, nil, nil, nil)
            case .profileName:
                (Font.title2Bold, nil, nil, nil)
            case .sidebarTitle:
                (Font.title3Bold, nil, nil, nil)
            case .sidebarSubtitle:
                (Font.bodyLight, nil, nil, nil)
            case .tabBarTxt:
                (Font.caption2Semibold, nil, nil, nil)
            case .tabBarImg:
                (Font.calloutSemibold, nil, nil, nil)
            case .formFieldError:
                (Font.captionRegular, Color.destructive, nil, nil)
            case .keyboardToolbarAction:
                (Font.bodySemibold, Color.dropinPrimary, nil, nil)
            case .cardAction:
                (Font.calloutSemibold, Color.dropinPrimary, nil, nil)
            case .cardPlaceholder:
                (Font.calloutRegular, Color.textTertiary, nil, nil)
            case .cardDescription:
                (Font.caption2Regular, Color.textTertiary, nil, nil)
            case .settingTitle:
                (Font.subheadlineRegular, Color.textPrimary, nil, nil)
            case .settingTitleAction:
                (Font.subheadlineSemibold, Color.dropinPrimary, nil, nil)
            case .settingValue:
                (Font.footnoteRegular, Color.textTertiary, nil, nil)
        }
    }
}

struct TextStyleModifier: ViewModifier {
    
    var style: TextStyle
    var colorOverride: Color? = nil
    var trackingOverride: CGFloat? = nil
    var lineSpacingOverride: CGFloat? = nil

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .foregroundStyle(colorOverride ?? style.color)
            .tracking((trackingOverride ?? style.tracking) ?? 0)
            .lineSpacing((lineSpacingOverride ?? style.lineSpacing) ?? 0)
    }
}

/*
// MARK: - View helper
//
// NOTE: Replace your existing `extension View { func textStyle(...) }` with this
// one. It adds an optional `color:` override so you can keep a semantic style's
// font while swapping only its colour — no more dropping down to raw `.font(...)`:
//
//   Text(verbatim: viewModel.headerSubtitle)
//       .textStyle(.cellSubtitle, color: .textSecondary.opacity(0.75))
//
extension View {
    func textStyle(_ style: TextStyle,
                   color: Color? = nil,
                   tracking: CGFloat = 0,
                   lineSpacing: CGFloat = 0) -> some View {
        modifier(TextStyleModifier(style: style,
                                   colorOverride: color,
                                   trackingOverride: tracking,
                                   lineSpacingOverride: lineSpacing))
    }
}
 */

#if DEBUG

#Preview {
    HStack(alignment: .top) {
        VStack(spacing: 10) {
            Text("- fonts -")
            Divider()

            Text("large title")
                .font(.largeTitleRegular)

            Text("title bold")
                .font(.titleBold)
            Text("title")
                .font(.titleRegular)

            Text("title3")
                .font(.title3Regular)

            Text("body bold")
                .font(.bodyBold)
            Text("body semibold")
                .font(.bodySemibold)
            Text("body medium")
                .font(.bodyMedium)
            Text("body")
                .font(.bodyRegular)
            Text("body light")
                .font(.bodyLight)
            Text("body thin")
                .font(.bodyThin)
            
            Text("callout regular")
                .font(.calloutRegular)
            
            Text("subheadline regular")
                .font(.subheadlineRegular)

            Text("footnote bold")
                .font(.footnoteBold)
            Text("footnote regular")
                .font(.footnoteRegular)
            
            Text("caption medium")
                .font(.captionMedium)
            Text("caption regular")
                .font(.captionRegular)
            
            Text("caption2 regular")
                .font(.caption2Regular)
            Text("caption2 light")
                .font(.caption2Light)
            
        }
        VStack(spacing: 10) {
            Text("- styles -")
            Divider()

            Text("body")
                .textStyle(.body)
            Text("body warning")
                .textStyle(.bodyWarning)
            Text("body error")
                .textStyle(.bodyError)
            Text("caption2")
                .textStyle(.caption2)
            Text("placeholder")
                .textStyle(.placeholder)
            Text("mainButton")
                .textStyle(.mainButton)
                .background(.dropinPrimary)
            Text("secondaryButton")
                .textStyle(.secondaryButton)

            Text("stringFieldTitle")
                .textStyle(.stringFieldTitle)
            Text("stringFieldContent")
                .textStyle(.stringFieldContent)

            Text("cellTitle")
                .textStyle(.cellTitle)
            Text("cellSubTitle")
                .textStyle(.cellSubtitle)
//            Text("cellSubTitle2")
//                .textStyle(.cellSubtitle2)
            Text("cellDetail")
                .textStyle(.cellDetail)
            Text("tagSticker")
                .textStyle(.tagSticker)
                .padding(5)
                .background(.purple)
            Text("groupSticker")
                .textStyle(.groupSticker)
                .padding(5)
                .border(.purple, width: 2)
            Text("formSectionTitle")
                .textStyle(.formSectionTitle)
            Text("formSectionTitle2")
                .textStyle(.formSectionTitle2)
            Spacer()
        }
    }
}

/*
 
 SwiftUI Style    UIKit Style    Size (pt)    Weight    Line Height (pt)
 .largeTitle    .largeTitle    34    Regular    ~41
 .title    .title1    28    Regular    ~34
 .title2    .title2    22    Regular    ~28
 .title3    .title3    20    Regular    ~25
 .headline    .headline    17    Semibold    ~22
 .subheadline    .subheadline    15    Regular    ~20
 .body    .body    17    Regular    ~22
 .callout    .callout    16    Regular    ~21
 .footnote    .footnote    13    Regular    ~18
 .caption    .caption1    12    Regular    ~16
 .caption2    .caption2    11    Regular    ~14
 
 */


#endif

