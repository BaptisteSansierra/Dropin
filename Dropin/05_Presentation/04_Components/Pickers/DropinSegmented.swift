//
//  DropinSegmented.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/10/26.
//

import SwiftUI

struct DropinSegmented<T: Hashable>: View {
    @Binding var selection: T
    let options: [(T, LocalizedStringKey)]
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.0) { value, label in
                let isOn = value == selection
                Button { withAnimation(.snappy(duration: 0.25)) { selection = value } } label: {
                    Text(label)
                        .textStyle(isOn ? .footnoteSemibold : .footnoteMedium,
                                   color: isOn ? .textPrimary : .textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background {
                            if isOn {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.surface1)
                                    .shadow(color: .black.opacity(0.12), radius: 1.5, y: 1)
                                    .matchedGeometryEffect(id: "thumb", in: ns)
                            }
                        }
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(.backgroundPrimary, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.fieldBorder, lineWidth: 1))
        .sensoryFeedback(.selection, trigger: selection)
    }
}

#Preview {
    @Previewable @State var selected: Int = 1
    DropinSegmented(selection: $selected,
                    options: [(0, "red"), (1, "green"), (2, "blue")])
}
