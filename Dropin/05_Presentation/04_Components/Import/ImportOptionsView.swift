//
//  ImportOptionsView.swift
//  Dropin
//
//  Created by baptiste sansierra on 11/11/26.
//

import SwiftUI

struct ImportOptionsView: View {
    
    @Binding var tagImport: Bool
    @Binding var tagName: String
    let errorMessage: LocalizedStringKey?
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("import_selector.options")
                .textStyle(.formSectionTitle)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Image(systemName: "tag")
                        .textStyle(.subheadline)
                        .padding(.trailing, 10)
                    Text("import_selector.option.tag")
                        .textStyle(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .padding(.trailing, 10)
                    Toggle(String(), isOn: $tagImport)
                        .labelsHidden()
                        .frame(minWidth: 0)
                }
                .frame(height: 50)
                if tagImport {
                    Rectangle()
                        .fill(.hairline)
                        .frame(height: 1)
                    HStack(spacing: 0) {
                        Text("common.tag")
                            .textStyle(.subheadline, color: .textSecondary)
                        Spacer()
                        TextField(String(), text: $tagName)
                            .labelsHidden()
                            .multilineTextAlignment(.trailing)
                            .lineLimit(1)
                            .textStyle(.subheadline)
                            .autocorrectionDisabled()
                            .onSubmit {
                                tagName = tagName.trimmedName
                                onSubmit()
                            }
                    }
                    .frame(height: 50)
                }
            }
            .padding(.horizontal, 15)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.surface1)
                    .stroke(.hairline)
            }
            if let errorMessage {
                Text(errorMessage)
                    .textStyle(.cardFooter, color: .destructive)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 5)
            } else {
                Text("import_selector.option.tag.desc")
                    .textStyle(.cardFooter)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 5)
            }
        }
    }
}

#Preview {
    @Previewable @State var tagImport = true
    @Previewable @State var tagName = "import_03"
    
    ZStack {
        Color.backgroundPrimary.ignoresSafeArea()
        VStack {
            ImportOptionsView(tagImport: $tagImport,
                              tagName: $tagName,
                              errorMessage: nil,
                              onSubmit: {})

            ImportOptionsView(tagImport: $tagImport,
                              tagName: $tagName,
                              errorMessage: "import.missing_import_tag",
                              onSubmit: {})
        }
        .padding()
    }
}
