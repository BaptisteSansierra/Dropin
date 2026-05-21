//
//  MapstrImportConfigView.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import SwiftUI

struct MapstrImportConfigView: View {

    @Binding var tagName: String
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("settings.mapstr_import.tag_placeholder", text: $tagName)
                        .autocorrectionDisabled()
                } header: {
                    Text("settings.mapstr_import.tag_section")
                } footer: {
                    Text("settings.mapstr_import.tag_footer")
                }
            }
            .navigationTitle("settings.mapstr_import.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.next") {
                        dismiss()
                        onConfirm()
                    }
                    .disabled(tagName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var tagName = "Mapstr"
    MapstrImportConfigView(tagName: $tagName, onConfirm: {})
}
