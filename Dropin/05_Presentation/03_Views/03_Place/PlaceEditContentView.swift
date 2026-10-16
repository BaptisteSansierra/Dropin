//
//  PlaceEditContentView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/3/26.
//

import SwiftUI
import ContactFieldKit
import NoFlyZone
import UIKit

struct PlaceEditContentView: View {
    
    // MARK: - States & Bindings
    @State private var viewModel: PlaceEditContentViewModel
    @State private var keyboardObserver = KeyboardObserver()
    @Binding private var place: PlaceUIModel
    @Binding private var showMissingName: Bool
    @FocusState private var isNameFocused
    @Environment(AppSettings.self) private var appSettings
    @Environment(RootView.ActionBus.self) private var actionBus

    //private var isNameFocused: FocusState<Bool>.Binding

    // To be moved in VM
//    @State private var confirmCancel: Bool = false
//    @State private var edited: Bool = false // true if contains some edits
    @State private var scrollY: CGFloat = 0
    //@State private var headerOpacity: CGFloat = 0
    @State private var headerBackgroundOffsetY: CGFloat = 0
    @State private var annotationSize: CGFloat = 50
    @State private var annotationBottomPading: CGFloat = 40
    @State private var headerNameOpacity: CGFloat = 0
    @State private var showingCategorySelector: Bool = false
    @State private var showingTagSelector: Bool = false
    @State private var showingMarkerList: Bool = false
    @State private var showEditAddressMenu: Bool = false
    // We use UI models for contact presentation
    @State private var phones: [ContactItemUI] = []
    @State private var emails: [ContactItemUI] = []
    @State private var urls: [ContactItemUI] = []
    @State private var showingImagePicker: Bool = false
    @State private var showingCamera: Bool = false
    @State private var showingImageSourceMenu: Bool = false
    @State private var selectedImageId: UUID? = nil
    // NoFlyZone states
    @State private var noFlyZoneEnabled: Bool = false
    @State private var noFlyAuthorizedZones: [NoFlyZoneData] = []
    @State private var noFlyZoneCompletionStatus: NoFlyZoneCompletionStatus = .undefined
    @State private var showDeleteWarning = false

    private let scrollCoordinateSpace = "scroll"
    private let topLayerHeight: CGFloat = 200
    private let nameFieldKey = "nameField"
    
    private let inCardTopMargin: CGFloat = 15
    private let inCardBottomMargin: CGFloat = 15
    private let cardSubtitleBottomMarginToTf: CGFloat = -5  // If texfield below title
    private let cardSubtitleBottomMargin: CGFloat = 5

    private let phoneFieldId = 1
    private let emailFieldId = 2
    private let urlFieldId = 3

    // MARK: - Init
    init(viewModel: PlaceEditContentViewModel,
         place: Binding<PlaceUIModel>,
         showMissingName: Binding<Bool>) {

        self.viewModel = viewModel
        self._place = place
        self._showMissingName = showMissingName

        // Create UI models from Domain models
        let phones = place.wrappedValue.phone.map { ContactItemUI(contactItem: $0) }
        self._phones = State(initialValue: phones)
        
        let emails = place.wrappedValue.email.map { ContactItemUI(contactItem: $0) }
        self._emails = State(initialValue: emails)
        
        let urls = place.wrappedValue.url.map { ContactItemUI(contactItem: $0) }
        self._urls = State(initialValue: urls)
        
        // local ContactFieldKit config override
        ContactFieldUIConfig.backgroundPrimary = .surface1
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color.backgroundSecondary
                    .ignoresSafeArea()
                ScrollViewReader { proxy in
                    scrollView
                        .onChange(of: showMissingName, { oldValue, newValue in
                            guard newValue else { return }
                            withAnimation {
                                proxy.scrollTo(nameFieldKey, anchor: .center)
                            }
                        })
                }
                headerView
            }
        }
        .noFlyZone(enabled: noFlyZoneEnabled,
                   authorizedZones: noFlyAuthorizedZones,
                   onAllowed: noFlyZoneOnAllowed,
                   onBlocked: noFlyZoneOnBlocked,
                   coloredDebugOverlay: false)
        .onChange(of: phones) {
            applyContactUpdate()
        }
        .onChange(of: emails) {
            applyContactUpdate()
        }
        .onChange(of: urls) {
            applyContactUpdate()
        }
        .alertOk(isPresented: $showMissingName,
                 title: "alert.missing_name.title",
                 body: "alert.missing_name.body",
                 action: { isNameFocused = true })
        .onAppear {
            viewModel.loadThumbnails(for: place)
        }
        .sheet(isPresented: $showingImagePicker) {
            PHPickerRepresentable { image in
                viewModel.addImage(to: place, image: image)
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPickerRepresentable { image in
                viewModel.addImage(to: place, image: image)
            }
        }
        .fullScreenCover(isPresented: Binding(get: {
            selectedImageId != nil
        }, set: { v in
            if !v { selectedImageId = nil }
        })) {
            let displayThumbnails: [(id: UUID, state: ImageLoadState)] = place.images.compactMap { img in
                guard let thumb = img.thumbnail else { return nil }
                return (id: img.id, state: .cached(thumb))
            }
            ImageFullscreenOverlay(
                thumbnails: displayThumbnails,
                initialIndex: displayThumbnails.firstIndex(where: { $0.id == selectedImageId }) ?? 0,
                loadFull: { localId in
                    guard let img = place.images.first(where: { $0.id == localId }) else { return nil }
                    if let uiImage = img.fullImage { return uiImage.jpegData(compressionQuality: 0.9) }
                    guard let dbId = img.dbId else { return nil }
                    return await viewModel.getFullImage(dbId: dbId, placeId: place.id)
                },
                onDismiss: { selectedImageId = nil }
            )
        }
    }
    
    // MARK: - Subviews
    private var headerView: some View {
        ZStack {
//            let gradient = Gradient(colors: [.dropinPrimary.lighten(factor: 0.3),
//                                             .shade5])
//            Rectangle()
//                .fill(LinearGradient(gradient: gradient,
//                                     startPoint: .top,
//                                     endPoint: .bottomTrailing))
//                .frame(height: topLayerHeight)
            Rectangle()
                .fill(.backgroundSecondary)
                .frame(height: topLayerHeight)
            
            VStack {
                Spacer()
                Rectangle()
                    .fill(.red)
                    .fill(.backgroundTertiary)
                    .frame(height: 1)
            }
            .frame(height: topLayerHeight)

            VStack {
                Spacer()
                switch appSettings.mapSettings.pinStyle {
                    case .rect:
                        PlaceRectAnnotationView(color: place.categoryColor,
                                                icon: place.category?.icon,
                                                iconExtra: place.icon,
                                                size: annotationSize)
                    case .rounded:
                        PlacePinAnnotationView(color: place.categoryColor,
                                               icon: place.category?.icon,
                                               iconExtra: place.icon,
                                               size: annotationSize,
                                               shadow: false)
                }
            }
            .padding(.bottom, annotationBottomPading)
            
            VStack {
                Spacer()
                Text(place.name)
                    .font(.captionMedium)
                    .foregroundStyle(Color(light: .textSecondary, dark: .textPrimary))
                    .opacity(headerNameOpacity)
                    .padding(.bottom, 10)
            }
        }
        .frame(height: topLayerHeight)
        .offset(x: 0, y: headerBackgroundOffsetY)
        .ignoresSafeArea()
    }
    
    private var scrollView: some View {
        ScrollView {
            let cardVSpacing: CGFloat = 30
            VStack(alignment: .leading, spacing: 0) {
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.frame(in: .named(scrollCoordinateSpace)), { _, _ in
                            didUpdateScroll(proxy)
                        })
                }
                .frame(height: 0)

                Spacer()
                    .frame(height: topLayerHeight + 10)

                placeCardView
                    .padding(.top, 20)
                groupCardView
                    .padding(.top, cardVSpacing)
                tagCardView
                    .padding(.top, cardVSpacing)
                iconCardView
                    .padding(.top, cardVSpacing)
                imagesCardView
                    .padding(.top, cardVSpacing)
                ratingCardView
                    .padding(.top, cardVSpacing)
                phoneCardView
                    .padding(.top, cardVSpacing)
                emailCardView
                    .padding(.top, cardVSpacing)
                urlCardView
                    .padding(.top, cardVSpacing)
                applePOICardView
                    .padding(.top, cardVSpacing)
                noteCardView
                    //.padding(.top, viewModel.mode == .edit ? 50 : 30)
                    .padding(.top, cardVSpacing)
                if viewModel.mode == .edit {
                    deleteButton
                        .padding(.top, 50)
                }
            }
            .padding(.bottom, 50)
            .padding(.horizontal, 20)
        }
        .task {
            await viewModel.fetchAppleDataIfNeeded(for: place)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: keyboardObserver.height)
        }
        .coordinateSpace(name: scrollCoordinateSpace)
        .ignoresSafeArea()
    }
    
    private func cardView<Content: View>(title: LocalizedStringKey,
                                         headerActionTitle: LocalizedStringKey? = nil,
                                         headerAction: (() -> Void)? = nil,
                                         //actionTitle: LocalizedStringKey? = nil,
                                         //action: (() -> Void)? = nil,
                                         contentHPadding: CGFloat = 15,
                                         @ViewBuilder content: () -> Content) -> some View {

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Text(title)
                    .textCase(.uppercase)
                    .textStyle(.formSectionTitle)
                Spacer()
                if let headerActionTitle = headerActionTitle {
                    Button {
                        headerAction?()
                    } label: {
                        Text(headerActionTitle)
                    }
                    .textStyle(.cardAction)
                }
            }
            .padding(.bottom, 10)
            
            /* Inner actions are removed
            ZStack {
                if let actionTitle = actionTitle {
                    HStack(spacing: 0) {
                        Spacer()
                        Button {
                            action?()
                        } label: {
                            Text(actionTitle)
                        }
                        .textStyle(.cardAction)
                    }
                }
                VStack {
                    content()
                }
            }
             */
            VStack {
                content()
            }
            .padding(.horizontal, contentHPadding)
            .clipShape(cardShape)
            .background { cardBackgroundView.clipped() }
        }
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 15)
    }

    private var cardBackgroundView: some View {
        cardShape
            .fill(.surface1)
            .stroke(.backgroundSecondary)
    }

    private var inCardDivider: some View {
        Rectangle()
            .fill(.backgroundSecondary)
            .frame(height: 1)
            .padding(.top, 5)
    }

    private var deleteButton: some View {
        DestructiveButton(text: "common.delete_place",
                          style: .bordered,
                          systemImage: "trash",
                          action: onPressDelete)
        .padding(.bottom, 15)
        .alert("alert.delete_place_title_\(place.name)",
               isPresented: $showDeleteWarning,
               actions: {
            
            // TODO: add a 'turn the wheel to delete' popup
            
            Button(role: .destructive) {
                performDelete()
            } label: {
                Text("common.delete")
            }
            Button("common.cancel", role: .cancel) { }
        }, message: {
            Text("alert.delete_place_msg")
        })
    }
    
    // MARK: - Private methods
    @ViewBuilder
    private func editAddressActionsView() -> some View {
        Button("common.edit_address") {
            viewModel.pushLookupPlacesView(placeId: place.id)
        }
        // TODO: DRO-19 Edit place: edit address options
        Button("common.edit_coordinates") {
        }
        .disabled(true)
        Button("common.edit_on_map") {
        }
        .disabled(true)
    }

    private func didUpdateScroll(_ proxy: GeometryProxy) {
        scrollY = proxy.frame(in: .named(scrollCoordinateSpace)).minY
        // Update header offset
        let headerOffsetLimit: CGFloat = 70
        headerBackgroundOffsetY = min(max(scrollY, -headerOffsetLimit), 0)
        // Update annotation size
        let annotationBottomPadingMin: CGFloat = 30
        let annotationBottomPadingMax: CGFloat = 40
        let annotationSizeMin: CGFloat = 36
        let annotationSizeMax: CGFloat = 50
        if scrollY < -headerOffsetLimit {
            annotationSize = annotationSizeMin
            annotationBottomPading = annotationBottomPadingMin
            headerNameOpacity = 1
        } else if scrollY > 0 {
            annotationSize = annotationSizeMax
            annotationBottomPading = annotationBottomPadingMax
            headerNameOpacity = 0
        } else {
            let lerp = abs(abs(scrollY) - headerOffsetLimit) / headerOffsetLimit
            annotationSize = lerp * annotationSizeMax + (1 - lerp) * annotationSizeMin
            annotationBottomPading = lerp * annotationBottomPadingMax + (1 - lerp) * annotationBottomPadingMin
            headerNameOpacity = 0
        }
    }
    
    func applyContactUpdate() {
        let phoneItems: [ContactItem] = phones.map { $0.contactItem }
        let emailItems: [ContactItem] = emails.map { $0.contactItem }
        let urlItems: [ContactItem] = urls.map { $0.contactItem }

        place.phone = phoneItems
        place.email = emailItems
        place.url = urlItems
    }

    private func noFlyZoneOnBlocked() {
        noFlyZoneEnabled = false
        noFlyZoneCompletionStatus = .blocked
    }
    
    private func noFlyZoneOnAllowed(tappedZones: [NoFlyZoneData]) {
        noFlyZoneEnabled = false
        noFlyZoneCompletionStatus = .allowed
        
        // FIXME:
        // 1- add some phones
        // 2- remove the phones
        // 3- add url
        // 4- remove url
        // => Receive tappedZones(count:1) with viewId == 1 (SHOULD BE 3) ==> CRASH
        
        for z in tappedZones {
            if z.viewId == phoneFieldId {
                guard z.itemId < phones.count else {
                    assertionFailure("Trying to remove phone[\(z.itemId)] when count is \(phones.count)")
                    return
                }
                phones[z.itemId].toBeDeleted = true
            }
            else if z.viewId == emailFieldId {
                guard z.itemId < emails.count else {
                    assertionFailure("Trying to remove email[\(z.itemId)] when count is \(emails.count)")
                    return
                }
                emails[z.itemId].toBeDeleted = true
            }
            else if z.viewId == urlFieldId {
                guard z.itemId < urls.count else {
                    assertionFailure("Trying to remove url[\(z.itemId)] when count is \(urls.count)")
                    return
                }
                urls[z.itemId].toBeDeleted = true
            }
        }
    }
    
    private func onPressDelete() {
        showDeleteWarning.toggle()
    }
    
    private func performDelete() {
        
        // Delay the hard deletion so the parentview navigation path does not contain a stale model
        // Parent view needs to be able to 'resolveNavigationDestination' til child is not fully dismissed
        // soft deleted meanwhile
        place.deletedAt = Date()
        viewModel.popView()


        Task {
            do {
                // Push the modification to DB
                try await viewModel.updatePlace(place)

                // Update main places list
                actionBus.send(.reloadMainPlaces)

                // TODO: DRO-24 implement delete stategy
                // Some database cleaner should remove all deleted items older than x
            }
        }
    }
}

// MARK: - PLACE Card
extension PlaceEditContentView {
    
    private var placeCardView: some View {
        cardView(title: "common.place") {
            Text("common.name")
                .textStyle(.formSectionTitle2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, inCardTopMargin)
                .padding(.bottom, cardSubtitleBottomMarginToTf)

            ZStack(alignment: .topLeading) {
                if place.name.isEmpty {
                    Text("common.name")
                        .textStyle(.cardPlaceholder)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 3)
                        .allowsHitTesting(false)
                }
                TextField("", text: $place.name)
                    .textStyle(.body)
                    .background(.clear)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($isNameFocused)
                    .onSubmit {
                        //updateCategory()
                    }
            }

            inCardDivider
            addressView
        }
    }

    @ViewBuilder
    private var addressView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("common.address")
                .textStyle(.formSectionTitle2)
                //.padding(.leading)
                .padding(.bottom, cardSubtitleBottomMargin)
                .padding(.top, 10)

            Group {
                if let address = place.address {
                    Text(address)
                        .textStyle(.body)
                } else {
                    Text("placeholder.address_missing")
                        .textStyle(.placeholder, color: .textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .confirmationDialog(String(""),
                                isPresented: $showEditAddressMenu,
                                actions: editAddressActionsView)
        }
        .onTapGesture {
            showEditAddressMenu.toggle()
        }
        
        inCardDivider

        ZStack(alignment: .topLeading) {
            if place.address2 == nil {
                Text("placeholder.address2")
                    .textStyle(.cardPlaceholder)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 5)
                    .padding(.bottom, inCardBottomMargin)
                    .allowsHitTesting(false)
            }
            TextField("", text: Binding(
                get: { place.address2 ?? "" },
                set: { place.address2 = $0 }
            ), axis: .vertical)
                .textStyle(.body)
                .padding(.top, -5)
                .background(.clear)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .padding(.top, 10)
                .padding(.bottom, inCardBottomMargin)
        }
    }
}

// MARK: - GROUP Card
extension PlaceEditContentView {
    
    @ViewBuilder
    private var groupCardView: some View {
        Group {
            if let category = place.category {
                cardView(title: "common.category",
                         headerActionTitle: "common.change",
                         headerAction: {
                    showingCategorySelector.toggle()
                }) {
                    HStack {
                        CategoryView(category: category,
                                  action: { place.category = nil })
                        .padding(.vertical, 20)
                        .padding(.leading, 0)
                        Spacer()
                    }
                }
            } else {
                emptyCategoryContentView
            }
        }
        .sheet(isPresented: $showingCategorySelector) {
            viewModel.createCategorySelectorView(place: $place)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.backgroundPrimary)
        }
    }

    private var emptyCategoryContentView: some View {
        cardView(title: "common.category",
                 headerActionTitle: "common.choose",
                 headerAction: {
            showingCategorySelector.toggle()
        }) {
            HStack {
                Text("placeholder.no_category")
                    .textStyle(.cardPlaceholder)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, inCardTopMargin)
                    .padding(.bottom, inCardBottomMargin)
                Spacer()
            }
        }
    }
}

// MARK: - TAG Card
extension PlaceEditContentView {
    
    private var tagCardView: some View {
        Group {
            if place.tags.count > 0 {
                tagCardContentView
            } else {
                noTagsCardContentView
            }
        }
        .sheet(isPresented: $showingTagSelector) {
            viewModel.createTagSelectorView(place: $place)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.backgroundPrimary)
        }
    }
        
    private var tagCardContentView: some View {
        cardView(title: "common.tags",
                 headerActionTitle: "common.edit",
                 headerAction: {
            showingTagSelector.toggle()
        }) {
            PlaceTagsView(place: $place,
                          showingTagsSelector: $showingTagSelector,
                          editEnabled: false,
                          presentationMode: .form)
            .padding(.top, inCardTopMargin)
            .padding(.bottom, inCardBottomMargin)
        }
    }
        
    private var noTagsCardContentView: some View {
        cardView(title: "common.tags",
                 headerActionTitle: "common.add",
                 headerAction: {
            showingTagSelector.toggle()
        }) {
            HStack {
                Text("placeholder.no_tags")
                    .textStyle(.cardPlaceholder)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, inCardTopMargin)
                    .padding(.bottom, inCardBottomMargin)
                Spacer()
            }
        }
    }
}

// MARK: - ICON Card
extension PlaceEditContentView {
    
    private var iconCardView: some View {
        Group {
            if let icon = place.icon {
                iconCardContentView(icon)
            } else {
                noIconCardContentView
            }
        }
        .fullScreenCover(isPresented: $showingMarkerList) {
            MarkerListView(selected: $place.icon)
        }
    }
    
    private func iconCardContentView(_ icon: Icon) -> some View {
        cardView(title: "common.annotation_icon",
                 headerActionTitle: "common.change",
                 headerAction: { showingMarkerList.toggle() }) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.dropinPrimary.opacity(0.2))
                        .frame(width: 40, height: 40)
                    IconView(icon: icon)
                        .sizeBody()
                        .foregroundStyle(.dropinPrimary)
                }
                .padding(.trailing, 5)
                VStack {
                    Text("place_edit.annotation_icon_desc")
                        .textStyle(.cardDescription)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, inCardTopMargin)
            .padding(.bottom, inCardBottomMargin)
        }
    }

    private var noIconCardContentView: some View {
        cardView(title: "common.annotation_icon",
                 headerActionTitle: "common.choose",
                 headerAction: { showingMarkerList.toggle() }) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.textTertiary, style: StrokeStyle(lineWidth: 1,
                                                                       dash: [2, 2]))
                        .frame(width: 40, height: 40)
                    Image(systemName: "questionmark.circle")
                        .textStyle(.cardPlaceholder)
                }
                .padding(.trailing, 5)
                VStack {
                    Text("placeholder.no_icon")
                        .textStyle(.cardPlaceholder)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("place_edit.annotation_icon_desc")
                        .textStyle(.cardDescription)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, inCardTopMargin)
            .padding(.bottom, inCardBottomMargin)
        }
    }
    
    private var iconView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("common.annotation_icon")
                .textStyle(.formSectionTitle2)
                .padding(.leading)
                .padding(.bottom, 10)
            
            ZStack {
                Rectangle()
                    .frame(height: 55)
                    .foregroundStyle(.backgroundPrimary)
                HStack(alignment: .center, spacing: 0) {
                    if let icon = place.icon {
                        ZStack(alignment: .center) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.clear)
                                .stroke(.textPrimary)
                                .frame(width: 80, height: 35)
                            IconView(icon: icon)
                                .sizeBody()
                        }
                        .padding(.leading)
                    }
                    Spacer()
                    IcoButton(systemImage: "ellipsis",
                              icoSize: 14,
                              action: { showingMarkerList.toggle() })
                    .padding(.trailing, 15)
                }
                if place.icon == nil {
                    Text("placeholder.no_icon")
                        .foregroundStyle(.disabled)
                        .textStyle(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .fullScreenCover(isPresented: $showingMarkerList) {
            MarkerListView(selected: $place.icon)
        }
    }
}

// MARK: - PHOTOS Card
extension PlaceEditContentView {
    
    private var imagesCardView: some View {
        cardView(title: "common.photos") {
            if place.images.count == 0 {
                noImagesCardView
            } else {
                imagesContentCardView
            }
        }
    }

    private var noImagesCardView: some View {
        HStack {
            imagesAddView
                .padding(.trailing, 5)
            VStack {
                Text("place_edit.images_placeholder1")
                    .textStyle(.cardPlaceholder)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("place_edit.images_placeholder2")
                    .textStyle(.cardDescription)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, inCardTopMargin)
        .padding(.bottom, inCardBottomMargin)
    }
    
    private var imagesContentCardView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(place.images) { item in
                    imageContentView(item)
                }
                if place.images.count < 5 {
                    imagesAddView
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.top, inCardTopMargin - 8)
        .padding(.bottom, inCardBottomMargin - 8)
    }
    
    private func imageContentView(_ item: PlaceImageUIModel) -> some View {
        ZStack(alignment: .topTrailing) {
            Button {
                if item.thumbnail != nil { selectedImageId = item.id }
            } label: {
                if let thumb = item.thumbnail, let image = UIImage(data: thumb) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 75, height: 75)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.backgroundSecondary)
                            .frame(width: 75, height: 75)
                        if item.isThumbnailLoading {
                            ProgressView()
                        }
                    }
                }
            }
            .disabled(item.thumbnail == nil)
            Button {
                viewModel.removeImage(withId: item.id, from: place)
            } label: {
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.6))
                        .frame(width: 20, height: 20)
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .offset(x: 5, y: -5)
        }
    }

    private var imagesAddView: some View {
        Button {
            showingImageSourceMenu = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .foregroundStyle(.disabled)
                    .frame(width: 75, height: 75)
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundStyle(.dropinPrimary)
            }
        }
        .confirmationDialog("", isPresented: $showingImageSourceMenu) {
            Button("common.photo_library") { showingImagePicker = true }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("common.camera") { showingCamera = true }
            }
        }
    }
}

// MARK: - RATING Card
extension PlaceEditContentView {
    
    private var ratingCardView: some View {
        cardView(title: "common.rating",
                 headerActionTitle: "common.clear",
                 headerAction: { place.rating = nil }) {
            HStack(alignment: .center, spacing: 0) {
                StarEditRatingView(rating: Binding<Float>(get: {
                    place.rating ?? 0
                }, set: { rating in
                    place.rating = rating
                }))
                Spacer()
            }
            .padding(.top, inCardTopMargin)
            .padding(.bottom, inCardBottomMargin)
        }
    }
    
    private var ratingView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("common.rating")
                .textStyle(.formSectionTitle2)
                .padding(.leading)
                .padding(.bottom, 10)
            
            ZStack {
                Rectangle()
                    .frame(height: 55)
                    .foregroundStyle(.backgroundPrimary)
                
                if let rating = place.rating {
                    HStack(alignment: .center, spacing: 0) {
                        StarEditRatingView(rating: Binding<Float>(get: {
                            rating
                        }, set: { rating in
                            place.rating = rating
                        }))
                        .padding(.leading, 15)
                        Spacer()
                        IcoButton(systemImage: "minus",
                                  icoSize: 14,
                                  icoColor: .destructive,
                                  action: { place.rating = nil })
                        .padding(.trailing, 15)
                    }
                } else {
                    HStack(alignment: .center, spacing: 0) {
                        Text("placeholder.no_rating")
                            .foregroundStyle(.disabled)
                            .textStyle(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        Spacer()
                        IcoButton(systemImage: "plus",
                                  icoSize: 14,
                                  icoColor: .success,
                                  action: { place.rating = 3 })
                        .padding(.trailing, 15)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingMarkerList) {
            MarkerListView(selected: $place.icon)
        }
    }
}

// MARK: - PHONE Card
extension PlaceEditContentView {

    private var phoneCardView: some View {
        cardView(title: "common.phone") {
            ContactItemEditView(viewIdentifier: phoneFieldId,
                                kind: .phone,
                                values: $phones,
                                noFlyZoneEnabled: $noFlyZoneEnabled,
                                noFlyZoneCompletionStatus: $noFlyZoneCompletionStatus,
                                noFlyAuthorizedZones: $noFlyAuthorizedZones)
            .padding(.horizontal, -15)
            .accentColor(.dropinPrimary)
        }
    }
}

// MARK: - EMAIL Card
extension PlaceEditContentView {
    
    private var emailCardView: some View {
        cardView(title: "common.email") {
            ContactItemEditView(viewIdentifier: emailFieldId,
                                kind: .email,
                                values: $emails,
                                noFlyZoneEnabled: $noFlyZoneEnabled,
                                noFlyZoneCompletionStatus: $noFlyZoneCompletionStatus,
                                noFlyAuthorizedZones: $noFlyAuthorizedZones)
            .padding(.horizontal, -15)
            .accentColor(.dropinPrimary)
        }
    }
}

// MARK: - URL Card
extension PlaceEditContentView {
    private var urlCardView: some View {
        cardView(title: "common.url") {
            ContactItemEditView(viewIdentifier: urlFieldId,
                                kind: .url,
                                values: $urls,
                                noFlyZoneEnabled: $noFlyZoneEnabled,
                                noFlyZoneCompletionStatus: $noFlyZoneCompletionStatus,
                                noFlyAuthorizedZones: $noFlyAuthorizedZones)
            .padding(.horizontal, -15)
            .accentColor(.dropinPrimary)
        }
    }
}

// MARK: - Apple POI
extension PlaceEditContentView {
    @ViewBuilder
    private var applePOICardView: some View {
        if let _ = place.applePlaceID {
            cardView(title: "common.from_apple_maps", contentHPadding: 0) {
                if let applePOIError = viewModel.applePOIError {
                    poiErrorView(applePOIError)
                } else if viewModel.applePOILoading {
                    poiLoadingView
                } else {
                    if viewModel.applePhoneNumber != nil || viewModel.appleURL != nil {
                        poiResultView
                    } else {
                        poiEmptyView
                    }
                }
            }
            .onChange(of: viewModel.reachabilityService.isConnected, { oldValue, newValue in
                guard newValue == true else {
                    // Not connected, nothing to update
                    return
                }
                // If fetching poi data ended with a connectivity error, retry
                if let poiError = viewModel.applePOIError, poiError == .notConnected {
                    Task {
                        await viewModel.fetchAppleDataIfNeeded(for: place)
                    }
                }
            })
            .confirmationDialog(
                "place_edit_content_view.poi.unlink.title",
                isPresented: $viewModel.isUnlinkConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("common.unlink") {
                    viewModel.unlinkPOI(place)
                }
                Button("common.cancel", role: .cancel) { }
            } message: {
                Text("place_edit_content_view.poi.unlink.body")
            }
        }
    }
    
    @ViewBuilder
    private func poiErrorView(_ error: ApplePOIError) -> some View {
        switch error {
            case .notConnected:
                poiErrorContentView(systemImage: "wifi.slash",
                                    title: "common.not_connected",
                                    body: "place_edit_content_view.poi.not_connected_desc")
            case .notFound, .corrupted:
                VStack(spacing: 0) {
                    if error == .corrupted {
                        poiErrorContentView(systemImage: "exclamationmark.triangle",
                                            title: "place_edit_content_view.poi.invalid_id.title",
                                            body: "place_edit_content_view.poi.invalid_id.body")
                    } else {
                        poiErrorContentView(systemImage: poiNotFoundImage(),
                                            title: poiNotFoundTitle(),
                                            body: poiNotFoundBody())
                    }
                    Rectangle()
                        .fill(.fieldBorder)
                        .frame(height: 1)
                    HStack {
                        TextButton(text: "common.unlink", preSystemImage: "personalhotspot.slash") {
                            viewModel.isUnlinkConfirmationPresented.toggle()
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 11)
                }
            case .mkUnknown(let code):
                poiErrorContentView(systemImage: "exclamationmark.triangle",
                                    title: "place_edit_content_view.poi.not_found_new.title",
                                    body: "place_edit_content_view.poi.mk_unknown.body.\(code)")
            case .unknown(let error):
                poiErrorContentView(systemImage: "exclamationmark.triangle",
                                    title: "place_edit_content_view.poi.not_found_new.title",
                                    body: "place_edit_content_view.poi.unknown.body.\(error.localizedDescription)")
        }
    }
    
    private func poiErrorContentView(systemImage: String,
                                     title: LocalizedStringKey,
                                     body: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Image(systemName: systemImage)
                .textStyle(.body)
                .frame(width: 50)
            VStack(spacing: 0) {
                Text(title)
                    .textStyle(.footnoteSemibold)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 5)
                    .padding(.trailing)
                Text(body)
                    .textStyle(.footnote, color: .textSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing)
            }
        }
        .padding(.vertical)
    }
    
    private func poiFetchedView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
            Rectangle()
                .fill(.fieldBorder)
                .frame(height: 1)
            HStack {
                Image(systemName: "map")
                    .textStyle(.footnote, color: .textSecondary)
                    .padding(.leading)
                Text("apple_poi.desc")
                    .textStyle(.footnote, color: .textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: 40)
            .background(Color.backgroundPrimary)
        }
    }

    private var poiEmptyView: some View {
        poiFetchedView {
            Text("place_edit_content_view.poi.empty")
                .textStyle(.footnote, color: .textSecondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical)
        }
    }

    private var poiLoadingView: some View {
        poiFetchedView {
            DropinLoader(style: .inline, size: .small, caption: "common.loading.susp")
                .padding()
        }
    }
    
    private var poiResultView: some View {
        poiFetchedView {
            ApplePOIViewFactory.dataCardContentView(phoneNumber: viewModel.applePhoneNumber,
                                                    url: viewModel.appleURL)
        }
    }
    
    private func poiNotFoundTitle() -> LocalizedStringKey {
        guard let notFoundDate = place.appleNotFoundAt else {
            return "place_edit_content_view.poi.not_found_new.title"
        }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let isOlderThan30Days = notFoundDate < thirtyDaysAgo
        if isOlderThan30Days {
            return "place_edit_content_view.poi.not_found_old.title"
        } else {
            return "place_edit_content_view.poi.not_found_new.title"
        }
    }
    
    private func poiNotFoundBody() -> LocalizedStringKey {
        guard let notFoundDate = place.appleNotFoundAt else {
            return "place_edit_content_view.poi.not_found_new.body"
        }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let isOlderThan30Days = notFoundDate < thirtyDaysAgo
        if isOlderThan30Days {
            return "place_edit_content_view.poi.not_found_old.body"
        } else {
            return "place_edit_content_view.poi.not_found_new.body"
        }
    }
    
    private func poiNotFoundImage() -> String {
        guard let notFoundDate = place.appleNotFoundAt else {
            return "exclamationmark.icloud"
        }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let isOlderThan30Days = notFoundDate < thirtyDaysAgo
        if isOlderThan30Days {
            return "mappin.slash"
        } else {
            return "exclamationmark.icloud"
        }
    }
}

// MARK: - NOTES Card
extension PlaceEditContentView {
    private var noteCardView: some View {
        cardView(title: "common.notes") {
            
            ZStack(alignment: .topLeading) {
                if place.notes == nil || place.notes!.isEmpty {
                    Text("common.notes")
                        .textStyle(.cardPlaceholder)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 15)
                        .allowsHitTesting(false)
                }
                TextField("",
                          text: Binding<String>(get: {
                    place.notes ?? ""
                }, set: { value in
                    place.notes = value
                }), axis: .vertical)
                .lineLimit(4...10)
                .multilineTextAlignment(.leading)
                .padding(.vertical)
                .frame(minHeight: 100, alignment: .top)
            }
        }
    }
}



#if DEBUG

struct MockPlaceEditContentView: View {
    var mock: MockContainer
    var index: Int
    @State var place: PlaceUIModel
    @State var showMissingName: Bool = false

    var body: some View {
        mock.appContainer.createPlaceEditContentView(place: $place,
                                                     mode: .edit,
                                                     showMissingName: $showMissingName)
        .task {
            // In case we're testing '.notConnected'
            // reconnect after a few seconds so we can also test the retry works
            Task {
                try await Task.sleep(for: .seconds(5))
                print("CONNECT TO THE WORLD NOW!")
                StubApplePOIService.behaviour = .fakeData
                mock.updateReachability(true)
            }
        }
    }
    
    init(_ index: Int) {
        self.index = index
        let mock = MockContainer()
        self.mock = mock
        if index == Int.max {
            let t1 = TagRecord(identifier: UUID(),
                           name: "discoteca",
                           color: Color.random().hex)
            let t2 = TagRecord(identifier: UUID(),
                           name: "cool place",
                           color: Color.random().hex)
            let t3 = TagRecord(identifier: UUID(),
                           name: "dancing",
                           color: Color.random().hex)
            let t4 = TagRecord(identifier: UUID(),
                           name: "dscsdvsdv",
                           color: Color.random().hex)
            let g = CategoryRecord(identifier: UUID(),
                            name: "Mes places",
                            color: Color.random().hex,
                            icon: Icon.sf("cross"))
            let img1 = UIImage.random(square: 64) // UIImage(systemName: "cross")!
            let s1 = PlaceImageRecord(id: UUID(),
                             thumbnail: img1.compressedForStorage(),
                             full: img1.thumbnailData())
            let img2 = UIImage.rdGeo(square: 64)
            let s2 = PlaceImageRecord(id: UUID(),
                             thumbnail: img2.compressedForStorage(),
                             full: img2.thumbnailData())
            let p = PlaceRecord(identifier: UUID(),
                             name: "El Col·leccionista",
                             latitude: 41.40602900686343,
                             longitude: 2.160639939265184,
                             address: "Carrer del Torrent de les Flors, 46, Gràcia, 08024 Barcelona",
                             address2: "escalier D, Apt 2",
                             tags: [t1, t2, t3, t4],
                             category: g,
                            images: [s1, s2],
                             icon: .sf("figure.socialdance"))
            self.place = PlaceMapper.toUI(PlaceMapper.toDomain(p))
            self.place.images[0].dbId = self.place.images[0].id
            self.place.images[1].dbId = self.place.images[1].id
            self.place.images[0].thumbnail = s1.thumbnail
            self.place.images[1].thumbnail = s2.thumbnail

            self.place.phone = [ContactItem(value: "0765489867",
                                            label: ContactLabel(kind: .phone,
                                                                label: .custom("johnny"))),
                                ContactItem(value: "0965485867",
                                            label: ContactLabel(kind: .phone,
                                                                label: .custom("cash")))]
            self.place.url = [ContactItem(value: "www.collection.com",
                                          label: ContactLabel(kind: .url,
                                                              label: .url))]
            
            self.place.notes = """
                Great terrace
                Ask for the corner table
                Wendy is the best waitress
                """
            
            
        } else if index == Int.min {
            let p = PlaceRecord(identifier: UUID(),
                             name: "El Col·leccionista",
                             latitude: 41.40602900686343,
                             longitude: 2.160639939265184,
                             address: nil,
                             tags: [],
                             category: nil,
                             icon: nil)
            self.place = PlaceMapper.toUI(PlaceMapper.toDomain(p))
            
            //self.place.address2 = "Bat5 Porte3"
            
            // Define an applePlaceID so StubApplePOIService will be called
            // and applePhone/appleURL filled
            self.place.applePlaceID = "wert-edrf-thgd"    // fake ID
            //self.place.applePlaceID = "IFDEE26634A4EFE23" // existing Apple ID

            // Testing POI status
            if false {
                // Not connected error
                mock.updateReachability(false)
                StubApplePOIService.behaviour = .throwError(.notConnected)
                // Connection is restored by '.task' after a few seconds
                // Check: the notConnected placeholder is displayed
                //        After a few secs the data is displayed
            } else if false {
                // Not found by apple
                StubApplePOIService.behaviour = .throwError(.notFound)
                if true {
                    // since less than limit
                    self.place.appleNotFoundAt = Date()
                } else {
                    // since more than limit
                    self.place.appleNotFoundAt = Calendar.current.date(byAdding: .day, value: -32, to: Date())!
                }
                // Check: the relevant message is displayed
            } else if false {
                StubApplePOIService.behaviour = .throwError(.corrupted)
                // Check: the relevant error is displayed
            } else if false {
                StubApplePOIService.behaviour = .throwError(.mkUnknown(1))
                // Check: the relevant error is displayed
            } else if false {
                StubApplePOIService.behaviour = .throwError(.unknown(URLError(.notConnectedToInternet)))
                // Check: the relevant error is displayed
            } else if false {
                StubApplePOIService.behaviour = .onlyPhone
                // Check: only the phone is displayed
            } else if false {
                StubApplePOIService.behaviour = .onlyUrl
                // Check: only the url is displayed
            } else if false {
                StubApplePOIService.behaviour = .fakeNoData
                // Check: the no data placeholder is displayed
            } else if false {
                // Simulate the place was not found some times ago
                self.place.appleNotFoundAt = Calendar.current.date(byAdding: .day, value: -32, to: Date())!
                // Check: the `unmarkPOINotFound` is called after load
            }
            
        } else {
            self.place = mock.getPlaceUIModel(index)
        }
    }
}

#Preview {
    NavigationStack {
        MockPlaceEditContentView(Int.max)
    }
    .environment(AppSettings())
    .environment(RootView.ActionBus())
}
#Preview {
    NavigationStack {
        MockPlaceEditContentView(Int.min)
    }
    .environment(AppSettings())
    .environment(RootView.ActionBus())
    .environment(\.locale, Locale(identifier: "fr_FR"))
}

#endif
