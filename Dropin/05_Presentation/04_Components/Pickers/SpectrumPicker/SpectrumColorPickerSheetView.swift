//
//  SpectrumColorPickerSheetView.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/26.
//

import SwiftUI

struct SpectrumColorPickerSheetView: View {
    
    @Binding var color: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }, label: {
                    ZStack {
                        Circle()
                            .fill(.backgroundPrimary)
                            .frame(width: 35)
                        Image(systemName: "multiply")
                            .textStyle(.body)
                    }
                })
            }
            .padding(.horizontal)
            SpectrumColorPickerView(color: $color)
                .frame(height: 260)
                .padding()
            SecondaryButton(text: "common.randomize") {
                color = Color.random()
            }
            .padding(.top)
            .padding(.horizontal)
        }
    }
}
