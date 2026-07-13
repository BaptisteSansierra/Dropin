//
//  AuthTextFieldView.swift
//  Dropin
//

import SwiftUI

/// Rounded, filled text field used on auth screens (email / password / etc).
/// Filled `.backgroundSecondary` field with a leading SF Symbol, radius 14,
/// matching the auth design spec. Optional secure-entry mode with a
/// show/hide toggle instead of a trailing icon.
///
/// Generic over the caller's focus-field enum: `.focused(_:equals:)` must be
/// applied directly to the underlying `TextField`/`SecureField`, so the
/// binding is forwarded down rather than applied to this wrapper view.
struct AuthTextFieldView<Value: Hashable>: View {

    // MARK: - States & Bindings
    @Binding private var text: String
    @State private var isRevealed: Bool = false

    // MARK: - properties
    private let systemImage: String
    private let placeholder: String
    private let isSecure: Bool
    private let keyboardType: UIKeyboardType
    private let textContentType: UITextContentType?
    private let submitLabel: SubmitLabel
    private let focusedField: FocusState<Value?>.Binding
    private let fieldValue: Value
    private let onSubmit: () -> Void
    private var isTextEmpty: Bool { text.isEmpty }

    // MARK: - init
    init(systemImage: String,
         text: Binding<String>,
         placeholder: String,
         isSecure: Bool = false,
         keyboardType: UIKeyboardType = .default,
         textContentType: UITextContentType? = nil,
         submitLabel: SubmitLabel = .done,
         focusedField: FocusState<Value?>.Binding,
         equals fieldValue: Value,
         onSubmit: @escaping () -> Void = {}) {
        self.systemImage = systemImage
        self._text = text
        self.placeholder = placeholder
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.submitLabel = submitLabel
        self.focusedField = focusedField
        self.fieldValue = fieldValue
        self.onSubmit = onSubmit
    }
    
    // MARK: - body
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.textTertiary)
                .frame(width: 20)

            ZStack(alignment: .leading) {
                Text(placeholder)
                    .textStyle(.fieldPlaceholder)
                    .opacity(isTextEmpty ? 1 : 0)

                Group {
                    if isSecure && !isRevealed {
                        SecureField(String(""), text: $text)
                    } else {
                        TextField(String(""), text: $text)
                    }
                }
                .textStyle(.stringFieldContent)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .submitLabel(submitLabel)
                .focused(focusedField, equals: fieldValue)
                .onSubmit(onSubmit)
            }

            if isSecure {
                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye": "eye.slash")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.surface1)
                .stroke(.fieldBorder)
        }
        .onTapGesture { focusedField.wrappedValue = fieldValue }
    }
}

#Preview {
    @Previewable @State var email: String = ""
    @Previewable @State var password: String = "hunter2"
    @Previewable @FocusState var focusedField: PreviewField?

    ZStack {
        Color.backgroundPrimary.ignoresSafeArea()
        VStack(spacing: 12) {
            AuthTextFieldView(systemImage: "envelope",
                              text: $email,
                              placeholder: "Email",
                              keyboardType: .emailAddress,
                              textContentType: .username,
                              focusedField: $focusedField,
                              equals: .email)
            AuthTextFieldView(systemImage: "lock",
                              text: $password,
                              placeholder: "Password",
                              isSecure: true,
                              textContentType: .password,
                              focusedField: $focusedField,
                              equals: .password)
        }
        .padding()
    }
}

private enum PreviewField: Hashable {
    case email
    case password
}
