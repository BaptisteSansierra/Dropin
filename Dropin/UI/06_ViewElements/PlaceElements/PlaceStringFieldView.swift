//
//  PlaceStringFieldView.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/8/25.
//

import SwiftUI

struct PlaceStringFieldView: View {
    
    // MARK: - State & Bindings
    @Binding private var field: String
    @Binding private var showField: Bool

    // MARK: - private vars
    private var name: String
    private var keyboardType: UIKeyboardType
    private var editEnabled: Bool

    // MARK: - Body
    var body: some View {
        VStack {
            HStack {
                Text(name)
                    .font(.title3)
                    .foregroundStyle(.gray)
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                TextField("", text: $field)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .keyboardType(keyboardType)
                    .disabled(!editEnabled)
            }
            Divider()
                .padding(.horizontal)
        }
        .padding(0)
        .frame(height: showField ? 40 : 0 )
        .opacity(showField ? 1 : 0)
    }
    
    // MARK: - init
    init(field: Binding<String>,
         showField: Binding<Bool>,
         name: String,
         keyboardType: UIKeyboardType,
         editEnabled: Bool) {
        self._field = field
        self._showField = showField
        self.name = name
        self.keyboardType = keyboardType
        self.editEnabled = editEnabled
    }
}
