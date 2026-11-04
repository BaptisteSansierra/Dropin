//
//  TagCreateSheetView.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/10/26.
//

import SwiftUI

struct TagCreateSheetView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var createTrigger = false
    
    private let existing: [String]
    private let onCreate: (String, String) -> Void
    static let sheetHeight: CGFloat = 240

    init(existing: [String],
         onCreate: @escaping (String, String) -> Void) {
        self.existing = existing
        self.onCreate = onCreate
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    TextButton(text: "common.cancel", action: { dismiss() })
                    Spacer()
                    TextButton(text: "common.add", action: { createTrigger = true })
                }
                Text("tag_selector.new")
                    .textStyle(.subheadlineSemibold)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal)
            .padding(.top, 35)
            .padding(.bottom, 30)
            TagCreateView(displayMode: .vertical,
                          existing: existing,
                          actionTrigger: $createTrigger) { name, color in
                onCreate(name, color)
                dismiss()
            }
            .padding(.horizontal)
            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var present = false
    let ex = ["111", "222"]
    VStack {
        Spacer()
        Button {
            present.toggle()
        } label : {
            Text(verbatim: "Go")
        }
        Spacer()
    }
    .sheet(isPresented: $present) {
        TagCreateSheetView(existing: ex) { _, _ in
        }
        .presentationBackground(.backgroundPrimary)
        .presentationDetents([.height(TagCreateSheetView.sheetHeight)])
        .presentationDragIndicator(.visible)
    }
}
