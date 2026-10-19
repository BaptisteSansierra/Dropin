//
//  SpectrumColorPicker.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/26.
//

import SwiftUI

struct SpectrumColorPicker: View {

    @Binding var color: Color
    @Binding var externalPickerTriggger: Bool
    @State private var presentSheet = false
    private var didEnd: (() -> Void)? = nil
    private let useExternalTrigger : Bool

    private var trigger: Binding<Bool> {
        Binding {
            guard useExternalTrigger else {
                return presentSheet
            }
            return externalPickerTriggger
        } set: { v in
            guard useExternalTrigger else {
                presentSheet = v
                return
            }
            externalPickerTriggger = v
        }
    }
    
    init(color: Binding<Color>, didEnd: (() -> Void)? = nil) {
        self._color = color
        self._externalPickerTriggger = Binding.constant(false)
        self.didEnd = didEnd
        self.useExternalTrigger = false
    }
    
    init(color: Binding<Color>,
         externalPickerTriggger: Binding<Bool>,
         didEnd: (() -> Void)? = nil) {
        self._color = color
        self._externalPickerTriggger = externalPickerTriggger
        self.didEnd = didEnd
        self.useExternalTrigger = true
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
            guard useExternalTrigger else {
                presentSheet.toggle()
                return
            }
            externalPickerTriggger.toggle()
        }
        .sheet(isPresented: trigger, onDismiss: {
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
    @Previewable @State var trigger: Bool = false

    VStack(spacing: 20) {
        HStack {
            SpectrumColorPicker(color: $color)
                .frame(width: 40)
            SpectrumColorPicker(color: $color)
                .frame(width: 75)
            SpectrumColorPicker(color: $color, externalPickerTriggger: $trigger)
                .frame(width: 100)
        }
        .padding(.bottom, 50)
        Text("TRIGGGER")
            .onTapGesture {
                trigger.toggle()
            }
    }
    .padding(.top, 100)
}
