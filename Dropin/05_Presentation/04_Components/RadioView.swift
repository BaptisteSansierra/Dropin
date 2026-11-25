//
//  RadioView.swift
//  Dropin
//
//  Created by baptiste sansierra on 11/11/26.
//

import SwiftUI

struct RadioView: View {
    
    var selected: Bool
    
    var body: some View {
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
                ZStack {
                    Circle()
                        .fill(.clear)
                        .frame(width: 25, height: 25)
                    Circle()
                        .fill(.clear)
                        .stroke(.textTertiary.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
        }
    }
}

#Preview {
    @Previewable @State var selectedId: Int = 0
    
    VStack(spacing: 10) {
        RadioView(selected: selectedId == 0)
            .onTapGesture {
                selectedId = 0
            }
        RadioView(selected: selectedId == 1)
            .onTapGesture {
                selectedId = 1
            }
        RadioView(selected: selectedId == 2)
            .onTapGesture {
                selectedId = 2
            }
    }
}
