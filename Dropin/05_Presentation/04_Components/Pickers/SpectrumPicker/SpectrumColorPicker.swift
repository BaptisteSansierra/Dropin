//
//  SpectrumColorPicker.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/26.
//

import SwiftUI

struct SpectrumColorPicker: View {

    @Binding var color: Color
    @State private var presentSheet = false
    private var didEnd: (() -> Void)? = nil
    
    init(color: Binding<Color>, didEnd: (() -> Void)? = nil) {
        self._color = color
        self.didEnd = didEnd
    }

    var body: some View {
        GeometryReader { geoProxy in
            ZStack {
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red],
                            center: .center
                        ),
                        lineWidth: size(geoProxy) * 0.11
                    )
                    .frame(width: size(geoProxy))
                Circle()
                    .fill(color)
                    .frame(width: size(geoProxy) * 0.6)
            }
            .frame(width: size(geoProxy), height: size(geoProxy))
        }
        .onTapGesture {
            presentSheet.toggle()
        }
        .sheet(isPresented: $presentSheet, onDismiss: {
            didEnd?()
        }) {
            SpectrumColorPickerSheetView(color: $color)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(.surface1)
        }
    }
    
    private func size(_ geoProxy: GeometryProxy) -> CGFloat {
        min(geoProxy.size.width, geoProxy.size.height)
    }
}

#Preview {
    @Previewable @State var color: Color = .random()
    
    VStack(spacing: 20) {
        HStack {
            SpectrumColorPicker(color: $color)
                .frame(width: 40)
            SpectrumColorPicker(color: $color)
                .frame(width: 75)
            SpectrumColorPicker(color: $color)
                .frame(width: 100)
        }
        .padding(.top, 100)
        Spacer()
    }
}
