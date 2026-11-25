//
//  ImportChoiceRowView.swift
//  Dropin
//
//  Created by baptiste sansierra on 11/11/26.
//

import SwiftUI

struct ImportChoiceRowView: View {
    
    var source: ImportSource
    var title: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    var selected: Bool

    // MARK: Body
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Checkbox
            RadioView(selected: selected)
                .padding(.trailing)
            // Icon
            ImportTileView(source: source)
            // Title
            VStack(spacing: 0) {
                Text(title)
                    .textStyle(.cellTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .textStyle(.cellSubtitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
            }
            .padding(.leading, 15)
            .padding(.trailing)
        }
        .contentShape(Rectangle())
    }
    
    // MARK: Subviews
    @ViewBuilder
    private func radioView(_ selected: Bool) -> some View {
        switch selected {
            case true:
                ZStack {
                    Circle()
                        .fill(.dropinPrimary)
                        //.stroke(.hairline)
                        .frame(width: 25, height: 25)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                        .foregroundStyle(.surface1)
                }
            case false:
                Circle()
                    .fill(.clear)
                    .stroke(.hairline)
                    .frame(width: 25, height: 25)
        }
    }
}
