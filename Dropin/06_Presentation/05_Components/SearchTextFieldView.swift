//
//  SearchTextFieldView.swift
//  Dropin
//
//  Created by baptiste sansierra on 23/12/25.
//

import SwiftUI

struct SearchTextFieldView: View {

    // MARK: - States & Bindings
    @Binding private var text: String
    @State private var clearButtonOpacity: Double
    @FocusState private var textFocused: Bool
    
    // MARK: - properties
    private let height: CGFloat = 40
    private var placeholder: String
    private var isTextEmpty: Bool {
        return text.count == 0
    }

    // MARK: - body
    var body: some View {
        ZStack {
            backgroundView
            contentView
        }
        .onChange(of: text) { oldValue, newValue in
            if (oldValue.count == 0 && newValue.count > 0) ||
                (oldValue.count > 0 && newValue.count == 0) {
                    withAnimation(.easeIn) {
                        clearButtonOpacity = newValue.count == 0 ? 0 : 1
                    }
            }
        }
    }
    
    // MARK: - subviews
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(Color(uiColor: UIColor.secondarySystemFill))
            .frame(height: height)
            .onTapGesture {
                textFocused = true
            }
    }

    private var contentView: some View {
        HStack(spacing: 0) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .frame(width: height, height: height)
            ZStack {
                Text(placeholder)
                    .textStyle(.placeholder)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                    .opacity(isTextEmpty ? 1 : 0)
                TextField(String(""), text: $text)
                    .textStyle(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .focused($textFocused)
                    .keyboardType(.default)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .submitLabel(.search)
            }
            Image(systemName: "xmark.circle.fill")
                .font(.body)
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .frame(width: height, height: height)
                .opacity(clearButtonOpacity)
                .onTapGesture {
                    text = ""
                }
        }
    }
    
    // MARK: - init
    init(text: Binding<String>, placeholder: String) {
        self._text = text
        self.placeholder = placeholder
        self.clearButtonOpacity = text.wrappedValue.count == 0 ? 0 : 1
    }
}

#Preview {
    @Previewable @State var text: String = ""
    NavigationStack {
        VStack {
            SearchTextFieldView(text: $text, placeholder: "preview placeholder")
                .padding()
            Spacer()
        }
        .navigationTitle("SearchTextFieldView")
        .navigationBarTitleDisplayMode(.inline)
    }
}
