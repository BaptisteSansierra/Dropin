//
//  CategoryCreateSheetView.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/10/26.
//

import SwiftUI

struct CategoryCreateSheetView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var createTrigger = false
    
    private let existing: [String]
    private let onCreate: (String, String, Icon) -> Void

    init(existing: [String],
         onCreate: @escaping (String, String, Icon) -> Void) {
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
                Text("category_selector.new")
                    .textStyle(.subheadlineSemibold)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal)
            .padding(.top, 35)
            .padding(.bottom, 30)
            CategoryCreateView(displayMode: .vertical,
                               existing: existing,
                               actionTrigger: $createTrigger) { name, color, icon in
                onCreate(name, color, icon)
                dismiss()
            }
            .padding(.horizontal)
            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var present = false
    var ex = ["111", "222"]
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
        CategoryCreateSheetView(existing: ex) { _, _, _ in
        }
        .presentationBackground(.backgroundPrimary)
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
    }
}
