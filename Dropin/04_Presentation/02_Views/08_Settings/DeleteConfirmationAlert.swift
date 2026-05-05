//
//  DeleteConfirmationAlert.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/4/26.
//

import SwiftUI

struct DeleteConfirmationAlert: View {
    
    @Binding var isPresented: Bool
    let onConfirm: () -> Void

    @State private var typed = ""
    private let required = String(localized: "common.delete_key_word")

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Image(systemName: "trash.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.red)
                }

                // Text
                VStack(spacing: 6) {
                    Text("alert.reset_database.title")
                        .font(.system(size: 17, weight: .semibold))
                    Text("alert.reset_database.body")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Confirmation input
                VStack(spacing: 6) {
                    Text("alert.reset_database.instr_\(required)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    TextField("", text: $typed)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    typed == required ? .red : Color(.systemGray4),
                                    lineWidth: typed == required ? 1.5 : 0.5
                                )
                        )
                }

                // Buttons
                VStack(spacing: 8) {
                    Button {
                        isPresented = false
                        onConfirm()
                    } label: {
                        Text("alert.reset_database.title")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(typed == required ? Color.red : Color.red.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(typed != required)
                    .animation(.easeInOut(duration: 0.15), value: typed == required)

                    Button("common.cancel", role: .cancel) {
                        isPresented = false
                    }
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    @Previewable @State var showDeleteConfirmation: Bool = false
    
    VStack {
        Button("Reset everything", role: .destructive) {
            showDeleteConfirmation.toggle()
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlay {
        if showDeleteConfirmation {
            DeleteConfirmationAlert(isPresented: $showDeleteConfirmation) {
                print("RESET")
            }
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
            .animation(.spring(response: 0.3), value: showDeleteConfirmation)
        }
    }
}
