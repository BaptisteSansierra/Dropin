//
//  CategoryCreateView.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/10/26.
//

import SwiftUI

struct CategoryCreateView: View {
    
    enum DisplayMode {
        case inline
        case vertical
    }
    
    // MARK: - States & Bindings
    @State private var showingMarkerPicker = false
    @State private var isShowingNameWarn = false
    @State private var isShowingVerticalWarn = false
    @State private var verticalWarn: LocalizedStringKey?
    @State private var presentExistsAlert = false

    @State private var createdCategoryColor: Color
    @State private var createdCategoryName: String = ""
    @State private var createdCategoryIcon: Icon? = nil

    @FocusState var isNameFieldFocused: Bool
    //@State private var markerCircleOpacity: CGFloat = 1

    @State private var markerPlaceholderOpacity: CGFloat
    @State private var markerPlaceholderColor: Color
    @State private var markerPlaceholderFont: Font
    @State private var presentColorPicker: Bool = false
    
    @Binding private var actionTrigger: Bool

    // MARK: - Private properties
    private let displayMode: DisplayMode
    private let markerPlaceholderOpacityDefault: CGFloat = 0.3
    private let markerPlaceholderColorDefault: Color = .textPrimary
    private let markerPlaceholderFontDefault: Font = .system(size: 15)
    private let onCreate: (String, String, Icon) -> Void
    private let existing: [String]

    init(displayMode: DisplayMode = .inline,
         existing: [String],
         actionTrigger: Binding<Bool> = .constant(false),
         onCreate: @escaping (String, String, Icon) -> Void) {
        self.displayMode = displayMode
        self.existing = existing
        self.onCreate = onCreate
        self._actionTrigger = actionTrigger
        _createdCategoryColor = State(initialValue: Color.random())
        markerPlaceholderOpacity = markerPlaceholderOpacityDefault
        markerPlaceholderColor = markerPlaceholderColorDefault
        markerPlaceholderFont = markerPlaceholderFontDefault
    }
    
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
            createCategory()
            actionTrigger = false
        })
        .fullScreenCover(isPresented: $showingMarkerPicker) {
            MarkerListView(selected: $createdCategoryIcon)
        }
        .onAppear {
            if displayMode == .vertical {
                isNameFieldFocused = true
                createdCategoryIcon = Icon(rawValue: "sf:folder")!
            }
        }
        .alertOk(isPresented: $presentExistsAlert,
                 title: "category_form.error.name_duplicate")
    }

    // MARK: - Subviews
    private var inlineView: some View {
        HStack(spacing: 10) {
            // Color picker
            VStack {
                SpectrumColorPicker(color: $createdCategoryColor)
                    .frame(width: 27, height: 27)
            }
            .frame(width: 38, height: 38)
            .overlay {
                RoundedRectangle(cornerRadius: 10).stroke(.hairline, lineWidth: 1)
            }
            // Marker picker
            markerView
                .overlay {
                    RoundedRectangle(cornerRadius: 10).stroke(.hairline, lineWidth: 1)
                }
                .onTapGesture {
                    showingMarkerPicker.toggle()
                }
            // Category name
            nameInputView(placeholder: "category_selector.new")
            // Action
            MainSmallButton(text: "common.add", action: createCategory)
                .disabled(createdCategoryName.isTrimmedEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.surface2)
        .overlay(alignment: .top) {
            Rectangle().fill(.hairline).frame(height: 1)
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
                        .stroke(.hairline)
                }
                .padding(.bottom, 15)
            // Color & Icon
            VStack(spacing: 0) {
                HStack {
                    Text("common.color")
                        .textStyle(.stringFieldContent)
                    Spacer()
                    VStack {
                        SpectrumColorPicker(color: $createdCategoryColor,
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
                Rectangle()
                    .fill(.hairline)
                    .frame(height: 1)
                    .padding(.leading, 10)
                HStack {
                    Text("common.icon")
                        .textStyle(.stringFieldContent)
                    Spacer()
                    if let icon = createdCategoryIcon {
                        IconView(icon: icon)
                            .sizeBody()
                            .foregroundStyle(.textPrimary)
                    }
                    Image(systemName: "chevron.right")
                        .textStyle(.stringFieldContent)
                }
                .padding(.horizontal, 10)
                .frame(height: 45)
                .contentShape(Rectangle())
                .onTapGesture {
                    showingMarkerPicker.toggle()
                }
            }
            .frame(height: 90)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.surface1)
                    .stroke(.hairline)
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
        TextField(placeholder, text: $createdCategoryName)
            .textStyle(.body)
            .autocorrectionDisabled()
            .focused($isNameFieldFocused)
            .overlay {
                if isShowingNameWarn {
                    ZStack(alignment: .leading) {
                        Rectangle().fill(.surface2)
                        Text("placeholder.category_name")
                            .textStyle(.bodyError)
                    }
                }
            }
    }
    
    private var markerView: some View {
        ZStack {
            if let icon = createdCategoryIcon {
                IconView(icon: icon)
                    .sizeCallout()
                    .foregroundStyle(.dropinPrimary)
            } else {
                Image(systemName: "folder")
                    .foregroundStyle(markerPlaceholderColor)
                    .font(markerPlaceholderFont)
                    .opacity(markerPlaceholderOpacity)
            }
        }
        .frame(width: 38, height: 38)
        .background(.surface1, in: RoundedRectangle(cornerRadius: 10))
        //.opacity(markerCircleOpacity)
    }
    
    
    // MARK: - private methods
    private func createCategory() {
        guard sanityCheck() else { return }
        onCreate(createdCategoryName,
                 createdCategoryColor.hex,
                 createdCategoryIcon ?? Icon(rawValue: "sf:folder")!)
        createdCategoryName = ""
        createdCategoryColor = Color.random()
        createdCategoryIcon = nil
    }
    
    private func sanityCheck() -> Bool {
        guard displayMode == .inline else {
            var showWarn = false
            if createdCategoryName.isTrimmedEmpty {
                verticalWarn = "error.name_needed"
                showWarn = true
            } else if createdCategoryIcon == nil {
                verticalWarn = "error.icon_needed"
                showWarn = true
            } else if alreadyExists() {
                verticalWarn = "category_form.error.name_duplicate"
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
        guard let _ = createdCategoryIcon else {
            withAnimation(.linear(duration: 0.25)) {
                //markerCircleOpacity = 0
                markerPlaceholderColor = .warning
                markerPlaceholderFont = .system(size: 22)
                markerPlaceholderOpacity = 1
            } completion: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        //markerCircleOpacity = 1
                        markerPlaceholderOpacity = markerPlaceholderOpacityDefault
                        markerPlaceholderColor = markerPlaceholderColorDefault
                        markerPlaceholderFont = markerPlaceholderFontDefault
                    }
                }
            }
            return false
        }
        guard !createdCategoryName.isTrimmedEmpty else {
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
        guard !createdCategoryName.isTrimmedEmpty else { return false }
        let low = createdCategoryName.lowercased()
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
        CategoryCreateView(displayMode: .inline, existing: ex) { _, _, _ in }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .fill(.purple.opacity(0.33))
                    .stroke(.purple)
            }
            .padding(.horizontal, 10)
            .padding(.vertical)

        VStack {
            CategoryCreateView(displayMode: .vertical,
                               existing: ex,
                               actionTrigger: $createTrigger) { n, c, i in
                print("CREATED GROUP \(n) \(c) \(i.rawValue)")
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
