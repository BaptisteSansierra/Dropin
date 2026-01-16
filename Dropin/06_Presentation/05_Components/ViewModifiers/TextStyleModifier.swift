//
//  TextStyleModifier.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/1/26.
//

import SwiftUI

struct TextStyleModifier: ViewModifier {
    
    enum Style: String, CaseIterable {
        case title
        case body
        case bodyError
        case caption2
        case placeholder
        case mainButton
        case secondaryButton
        case stringFieldTitle
        case stringFieldContent
        case cellTitle
        case cellSubtitle
        case cellSubtitle2
        case cellDetail
        case tagSticker
        case groupSticker
        case formSectionTitle
        case formSectionTitle2
    }
    
    var style: Style
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(color)
    }
    
    // MARK: - private
    private var font: Font {
        switch style {
            case .title:
                .titleRegular
            case .body:
                .bodyRegular
            case .bodyError:
                .bodyBold
            case .caption2:
                .caption2Regular
            case .placeholder:
                .calloutRegular
            case .mainButton:
                .bodySemibold
            case .secondaryButton:
                .bodySemibold
            case .stringFieldTitle:
                .title3Regular
            case .stringFieldContent:
                .bodyRegular
            case .cellTitle:
                .bodyMedium
            case .cellSubtitle:
                .captionRegular
            case .cellSubtitle2:
                .caption2Regular
            case .cellDetail:
                .captionRegular
            case .tagSticker:
                .footnoteBold
            case .groupSticker:
                .bodySemibold
            case .formSectionTitle:
                .bodySemibold
            case .formSectionTitle2:
                .captionMedium
        }
    }
    
    private var color: Color {
        switch style {
            case .title:
                .black
            case .body:
                .black
            case .bodyError:
                .red
            case .caption2:
                .black
            case .placeholder:
                .gray
            case .mainButton:
                .white
            case .secondaryButton:
                .dropinPrimary
            case .stringFieldTitle:
                .gray
            case .stringFieldContent:
                .black
            case .cellTitle:
                .black
            case .cellSubtitle:
                .gray
            case .cellSubtitle2:
                .gray
            case .cellDetail:
                .black
            case .tagSticker:
                .white
            case .groupSticker:
                .black
            case .formSectionTitle:
                .gray
            case .formSectionTitle2:
                .gray
        }
    }
}

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
            Text("cellTitle")
                .textStyle(.cellTitle)
            Text("cellSubTitle")
                .textStyle(.cellSubtitle)
            Text("cellSubTitle2")
                .textStyle(.cellSubtitle2)
            Text("cellDetail")
                .textStyle(.cellDetail)
            Text("tagSticker")
                .textStyle(.tagSticker)
                .padding(5)
                .background(.red)
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

