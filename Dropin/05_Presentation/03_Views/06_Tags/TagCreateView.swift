//
//  TagCreateView.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/10/26.
//

import SwiftUI

struct TagCreateView: View {
    
    enum DisplayMode {
        case inline
        case vertical
    }

    // MARK: - State & Bindings
    @State private var createdTagName: String = ""
    @State private var createdTagColor: Color
    @State private var isShowingNameWarn = false
    @State private var isShowingVerticalWarn = false
    @Binding private var actionTrigger: Bool
    @State private var verticalWarn: LocalizedStringKey?
    @FocusState var isNameFieldFocused: Bool
    @State private var presentExistsAlert = false
    @State private var presentColorPicker: Bool = false

    // MARK: - Private properties
    private let displayMode: DisplayMode
    private let onCreate: (String, String) -> Void
    private let existing: [String]

    // MARK: - Init
    init(displayMode: DisplayMode = .inline,
         existing: [String],
         actionTrigger: Binding<Bool> = .constant(false),
         onCreate: @escaping (String, String) -> Void) {
        self.displayMode = displayMode
        self.existing = existing
        self.onCreate = onCreate
        self._actionTrigger = actionTrigger
        _createdTagColor = State(initialValue: Color.random())
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            switch displayMode {
                case .inline:
                    inlineView
                case .vertical:
                    verticalView
            }
        }
        .onChange(of: actionTrigger, { oldValue, newValue in
            guard newValue == true else { return }
            createTag()
            actionTrigger = false
        })
        .onAppear {
            if displayMode == .vertical {
                isNameFieldFocused = true
            }
        }
        .alertOk(isPresented: $presentExistsAlert,
                 title: "tag_form.error.name_duplicate")
    }
    
    // MARK: - Subviews
    private var inlineView: some View {
        HStack(spacing: 10) {
            // Color picker
            VStack {
                SpectrumColorPicker(color: $createdTagColor)
                    .frame(width: 27, height: 27)
            }
            .frame(width: 38, height: 38)
            .overlay {
                RoundedRectangle(cornerRadius: 10).stroke(.fieldBorder, lineWidth: 1)
            }

            // Tag name
            nameInputView(placeholder: "tag_selector.new")
            
            MainSmallButton(text: "common.add", action: createTag)
                .disabled(createdTagName.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.surface2)
        .overlay(alignment: .top) {
            Rectangle().fill(.fieldBorder).frame(height: 1)
        }
    }
    
    private var verticalView: some View {
        VStack(spacing: 0) {
            // Name
            nameInputView(placeholder: "common.name")
                .frame(height: 45)
                .padding(.horizontal, 10)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.surface1)
                        .stroke(.fieldBorder)
                }
                .padding(.bottom, 15)
            // Color & Icon
            VStack(spacing: 0) {
                HStack {
                    Text("common.color")
                        .textStyle(.stringFieldContent)
                    Spacer()
                    VStack {
                        SpectrumColorPicker(color: $createdTagColor,
                                            externalPickerTriggger: $presentColorPicker)
                            .frame(width: 27, height: 27)
                    }
                    .frame(width: 38, height: 38)
                }
                .padding(.horizontal, 10)
                .frame(height: 45)
                .contentShape(Rectangle())
                .onTapGesture {
                    presentColorPicker.toggle()
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.surface1)
                    .stroke(.fieldBorder)
            }
            // Error
            if let verticalWarn = verticalWarn {
                HStack {
                    Text(verticalWarn)
                        .textStyle(.footnote, color: .destructive)
                        .padding(.top, 15)
                        .opacity(isShowingVerticalWarn ? 1 : 0)
                    Spacer()
                }
            }
        }
    }
    
    private func nameInputView(placeholder: LocalizedStringKey) -> some View {
        TextField(placeholder, text: $createdTagName)
            .textStyle(.body)
            .autocorrectionDisabled()
            .focused($isNameFieldFocused)
            .overlay {
                if isShowingNameWarn {
                    ZStack(alignment: .leading) {
                        Rectangle().fill(.surface2)
                        Text(placeholder)
                            .textStyle(.bodyError)
                    }
                }
            }
    }

    // MARK: - private methods
    private func createTag() {
        guard sanityCheck() else { return }
        onCreate(createdTagName,
                 createdTagColor.hex)
        createdTagName = ""
        createdTagColor = Color.random()
    }
    
    private func sanityCheck() -> Bool {
        guard displayMode == .inline else {
            var showWarn = false
            if createdTagName.isTrimmedEmpty {
                verticalWarn = "error.name_needed"
                showWarn = true
            } else if alreadyExists() {
                verticalWarn = "tag_form.error.name_duplicate"
                showWarn = true
            }
            if showWarn {
                withAnimation(.linear(duration: 0.5)) {
                    isShowingVerticalWarn.toggle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.linear(duration: 0.5)) {
                            isShowingVerticalWarn.toggle()
                        } completion: {
                            verticalWarn = nil
                        }
                    }
                }
                return false
            }
            return true
        }
        guard !createdTagName.isEmpty else {
            withAnimation(.linear(duration: 0.5)) {
                isShowingNameWarn.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.linear(duration: 0.5)) {
                        isShowingNameWarn.toggle()
                    }
                }
            }
            return false
        }
        guard !alreadyExists() else {
            presentExistsAlert = true
            return false
        }
        return true
    }
    
    private func alreadyExists() -> Bool {
        guard !createdTagName.isTrimmedEmpty else { return false }
        let low = createdTagName.lowercased()
        guard let _ = existing.firstIndex(where: { $0.lowercased() == low }) else {
            return false
        }
        return true
    }
}


#Preview {
    @Previewable @State var createTrigger = false
    let ex = ["111", "222"]
    VStack {
        TagCreateView(displayMode: .inline, existing: ex) { _, _ in }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .fill(.purple.opacity(0.33))
                    .stroke(.purple)
            }
            .padding(.horizontal, 10)
            .padding(.vertical)

        VStack {
            TagCreateView(displayMode: .vertical,
                          existing: ex,
                          actionTrigger: $createTrigger) { n, c in
                print("CREATED TAG \(n) \(c)")
            }
            .padding()
            MainButton(text: "common.create", action: { createTrigger.toggle() })
                .padding()
        }
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(.brown.opacity(0.33))
                .stroke(.brown)
        }
        .padding(.horizontal, 10)
        .padding(.vertical)
    }
}
