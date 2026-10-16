//
//  AuthKeyboardToolbar.swift
//  Dropin
//
//  Custom keyboard accessory bar for the auth forms: prev/next field
//  navigation on the left (only when the screen has more than one field),
//  "Close" on the right — dismisses the keyboard only, doesn't confirm
//  anything, so it's deliberately not "Done". Generic over the screen's own
//  Field enum, which must be `CaseIterable` so we can compute first/last-field
//  disabled state.
//
//  No custom background: SwiftUI's `.toolbar(placement: .keyboard)` doesn't
//  give full edge-to-edge control over the accessory bar's container when the
//  screen is a pushed NavigationStack destination (Sign Up, Reset Password) —
//  a custom fill there showed up with side margins letting the system
//  background peek through. Content sits on Apple's own bar instead.
//

import SwiftUI

struct AuthKeyboardToolbar<Value: Hashable & CaseIterable>: View where Value.AllCases: RandomAccessCollection {

    let focusedField: FocusState<Value?>.Binding

    private var allCases: Value.AllCases { Value.allCases }

    private var currentIndex: Value.AllCases.Index? {
        guard let current = focusedField.wrappedValue else { return nil }
        return allCases.firstIndex(of: current)
    }

    private var canGoPrevious: Bool {
        guard let currentIndex else { return false }
        return currentIndex > allCases.startIndex
    }

    private var canGoNext: Bool {
        guard let currentIndex else { return false }
        return allCases.index(after: currentIndex) < allCases.endIndex
    }

    var body: some View {
        HStack(spacing: 0) {
            if allCases.count > 1 {
                HStack(spacing: 20) {
                    Button(action: goToPrevious) {
                        Image(systemName: "chevron.up")
                            .foregroundStyle(canGoPrevious ? .textSecondary : .textTertiary)
                    }
                    .disabled(!canGoPrevious)

                    Button(action: goToNext) {
                        Image(systemName: "chevron.down")
                            .foregroundStyle(canGoNext ? .textSecondary : .textTertiary)
                    }
                    .disabled(!canGoNext)
                }
            }

            Spacer()

            Button(action: { focusedField.wrappedValue = nil }) {
                Text("common.close")
                    .textStyle(.keyboardToolbarAction)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
    }

    // MARK: - private
    private func goToPrevious() {
        guard let currentIndex, canGoPrevious else { return }
        focusedField.wrappedValue = allCases[allCases.index(before: currentIndex)]
    }

    private func goToNext() {
        guard let currentIndex, canGoNext else { return }
        focusedField.wrappedValue = allCases[allCases.index(after: currentIndex)]
    }
}

#if DEBUG
struct MockAuthKeyboardToolbar: View {
    private enum Field: Hashable, CaseIterable {
        case email
        case password
    }
    @FocusState private var focusedField: Field?

    var body: some View {
        AuthKeyboardToolbar(focusedField: $focusedField)
    }
}

#Preview {
    MockAuthKeyboardToolbar()
}
#endif
