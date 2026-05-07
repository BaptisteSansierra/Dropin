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
    @Binding private var place: PlaceUI
    @Binding private var showMissingName: Bool
    @FocusState private var isNameFocused
    @Environment(AppSettings.self) private var appSettings

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
    @State private var showingGroupSelector: Bool = false
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

    private let phoneFieldId = 1
    private let emailFieldId = 2
    private let urlFieldId = 3

    // MARK: - Init
    init(viewModel: PlaceEditContentViewModel,
         place: Binding<PlaceUI>,
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
            let displayThumbnails = place.images.compactMap { img -> (id: UUID, thumbnail: Data)? in
                guard let thumb = img.thumbnail else { return nil }
                return (id: img.id, thumbnail: thumb)
            }
            ImageFullscreenOverlay(
                thumbnails: displayThumbnails,
                initialIndex: displayThumbnails.firstIndex(where: { $0.id == selectedImageId }) ?? 0,
                loadFull: { localId in
                    guard let img = place.images.first(where: { $0.id == localId }) else { return nil }
                    if let uiImage = img.fullImage { return uiImage.jpegData(compressionQuality: 0.9) }
                    guard let dbId = img.dbId else { return nil }
                    return await viewModel.getFullImage(dbId: dbId)
                },
                onDismiss: { selectedImageId = nil }
            )
        }
    }
    
    // MARK: - Subviews
    private var headerView: some View {
        ZStack {
            let gradient = Gradient(colors: [.dropinPrimary.lighten(factor: 0.3),
                                             .shade5])
            Rectangle()
                .fill(LinearGradient(gradient: gradient,
                                     startPoint: .top,
                                     endPoint: .bottomTrailing))
                .frame(height: topLayerHeight)
            
            VStack {
                Spacer()
                switch appSettings.pinStyle {
                    case .rect:
                        PlaceRectAnnotationView(color: place.groupColor,
                                                icon: place.group?.icon,
                                                iconExtra: place.icon,
                                                size: annotationSize)
                    case .rounded:
                        PlacePinAnnotationView(color: place.groupColor,
                                               icon: place.group?.icon,
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
            VStack(alignment: .leading, spacing: 0) {
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.frame(in: .named(scrollCoordinateSpace)), { _, _ in
                            didUpdateScroll(proxy)
                        })
                }
                .frame(height: 0)
                nameView
                    .padding(.top, topLayerHeight)
                    .padding(.top, 30)
                    .id(nameFieldKey)
                addressView
                    .padding(.top, 20)
                groupView
                    .padding(.top, 20)
                tagView
                    .padding(.top, 20)
                iconView
                    .padding(.top, 20)
                imagesView
                    .padding(.top, 20)
                ratingView
                    .padding(.top, 20)
                phoneView
                    .padding(.top, 20)
                emailView
                    .padding(.top, 20)
                urlView
                    .padding(.top, 20)
                noteView
                    .padding(.top, viewModel.mode == .edit ? 50 : 20)
                if viewModel.mode == .edit {
                    deleteButton
                        .padding(.top, 50)
                }
            }
            .padding(.bottom, 50)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: keyboardObserver.height)
        }
        .coordinateSpace(name: scrollCoordinateSpace)
        .ignoresSafeArea()
    }
    
    private var nameView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("common.name")
                .textStyle(.formSectionTitle2)
                .padding(.leading)
                .padding(.bottom, 10)
            ZStack {
                Rectangle()
                    .frame(height: 45)
                    .foregroundStyle(.backgroundPrimary)
                TextField("common.name", text: $place.name)
                    .textStyle(.body)
                    .background(.clear)
                    .padding(.vertical, 0)
                    .padding(.horizontal)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($isNameFocused)
                    .onSubmit {
                        //updateGroup()
                    }
            }
        }
    }
    
    @ViewBuilder
    private var addressView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("common.address")
                .textStyle(.formSectionTitle2)
                .padding(.leading)
                .padding(.bottom, 10)
            
            let address = place.address
            Text(place.address.isEmpty ? "" : address)
                .textStyle(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(.backgroundPrimary)
                .confirmationDialog(String(""),
                                    isPresented: $showEditAddressMenu,
                                    actions: editAddressActionsView)
        }
        .onTapGesture {
            showEditAddressMenu.toggle()
        }

        VStack(alignment: .leading, spacing: 0) {
            Text("common.address2")
                .textStyle(.formSectionTitle2)
                .padding(.leading)
                .padding(.bottom, 10)
            
            ZStack {
                Rectangle()
                    .frame(height: 45)
                    .foregroundStyle(.backgroundPrimary)
                TextField("placeholder.address2", text: $place.address2)
                    .textStyle(.body)
                    .background(.clear)
                    .padding(.vertical, 0)
                    .padding(.horizontal)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
            }

            
//            TextField("placeholder.address2", text: $place.address2)
//                .textStyle(.body)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(.vertical, 10)
//                .padding(.horizontal)
//                .background(.backgroundPrimary)
        }
    }
    
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
    
    private var groupView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("common.group")
                .textStyle(.formSectionTitle2)
                .padding(.leading)
                .padding(.bottom, 10)
            
            ZStack {
                
                // TODO: PlaceUI should be a struct
                // else our binding is failing here, pointing to old editedPlace after cancel...
                
                PlaceGroupView(place: $place,
                               showingGroupSelector: $showingGroupSelector,
                               editEnabled: true,
                               presentationMode: .form)
                .background(.backgroundPrimary)
                if place.group == nil {
                    Text("placeholder.no_group")
                        .foregroundStyle(.disabled)
                        .textStyle(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            
        }
        .sheet(isPresented: $showingGroupSelector) {
            viewModel.createGroupSelectorView(place: $place)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var tagView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("common.tags")
                .textStyle(.formSectionTitle2)
                .padding(.leading)
                .padding(.bottom, 10)
            ZStack {
                PlaceTagsView(place: $place,
                              showingTagsSelector: $showingTagSelector,
                              editEnabled: true,
                              presentationMode: .form)
                if place.tags.count == 0 {
                    Text("placeholder.no_tags")
                        .foregroundStyle(.disabled)
                        .textStyle(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            .background(.backgroundPrimary)
            
        }
        .sheet(isPresented: $showingTagSelector) {
            viewModel.createTagSelectorView(place: $place)
                .padding(.top, 20)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var iconView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("common.additional_icon")
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
    
    private var imagesView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("common.photos")
                .textStyle(.formSectionTitle2)
                .padding(.leading)
                .padding(.bottom, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if place.images.count < 5 {
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
                                    .foregroundStyle(.disabled)
                            }
                        }
                        .confirmationDialog("", isPresented: $showingImageSourceMenu) {
                            Button("common.photo_library") { showingImagePicker = true }
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                Button("common.camera") { showingCamera = true }
                            }
                        }
                    }

                    ForEach(place.images) { item in
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
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(.backgroundPrimary)
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
    
    private var phoneView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("common.phone")
                .textStyle(.formSectionTitle2)
                .padding(.leading)
                .padding(.bottom, 10)
            
            ContactItemEditView(viewIdentifier: phoneFieldId,
                                kind: .phone,
                                values: $phones,
                                noFlyZoneEnabled: $noFlyZoneEnabled,
                                noFlyZoneCompletionStatus: $noFlyZoneCompletionStatus,
                                noFlyAuthorizedZones: $noFlyAuthorizedZones)
        }
    }
    
    private var emailView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("common.email")
                .textStyle(.formSectionTitle2)
                .padding(.leading)
                .padding(.bottom, 10)
            
            ContactItemEditView(viewIdentifier: emailFieldId,
                                kind: .email,
                                values: $emails,
                                noFlyZoneEnabled: $noFlyZoneEnabled,
                                noFlyZoneCompletionStatus: $noFlyZoneCompletionStatus,
                                noFlyAuthorizedZones: $noFlyAuthorizedZones)
        }
    }
    
    private var urlView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("common.url")
                .textStyle(.formSectionTitle2)
                .padding(.leading)
                .padding(.bottom, 10)
            
            ContactItemEditView(viewIdentifier: urlFieldId,
                                kind: .url,
                                values: $urls,
                                noFlyZoneEnabled: $noFlyZoneEnabled,
                                noFlyZoneCompletionStatus: $noFlyZoneCompletionStatus,
                                noFlyAuthorizedZones: $noFlyAuthorizedZones)
        }
    }
    
    private var noteView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("common.notes")
                .textStyle(.formSectionTitle2)
                .padding(.leading)
                .padding(.bottom, 10)
            
            ZStack {
                Rectangle()
                    .frame(height: 150)
                    .foregroundStyle(.backgroundPrimary)
                VStack {
                    TextField("common.notes",
                              text: Binding<String>(get: {
                        place.notes ?? ""
                    }, set: { value in
                        place.notes = value
                    }))
                    .lineLimit(0)
                    .padding()
                    Spacer()
                }
            }
        }
        .fullScreenCover(isPresented: $showingMarkerList) {
            MarkerListView(selected: $place.icon)
        }
    }
    
    private var deleteButton: some View {
        HStack() {
            Spacer()
            DestructiveButton(text: "common.delete_place",
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
            Spacer()
        }
    }
    
    // MARK: - Private methods
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
        Task {
            do {
                // Delay the deletion so the parentview navigation path does not contain a stale model
                // Parent view needs to be able to 'resolveNavigationDestination' til child is not fully dismissed
                // Mark the place as deleted meanwhile
                place.deletedAt = Date()
                try await viewModel.updatePlace(place)
                viewModel.popView()
                // TODO: implement a database cleaner
                // it should remove all items older than x
                try await Task.sleep(for: .seconds(1.5))
                try await viewModel.deletePlace(place)
            } catch {
                assertionFailure("Failed to delete place '\(place.name)' error: \(error)")
            }
        }
    }
}


#if DEBUG

struct MockPlaceEditContentView: View {
    var mock: MockContainer
    var index: Int
    @State var place: PlaceUI
    @State var showMissingName: Bool = false

    var body: some View {
        mock.appContainer.createPlaceEditContentView(place: $place,
                                                     mode: .edit,
                                                     showMissingName: $showMissingName)
    }
    
    init(_ index: Int) {
        self.index = index
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUI(index)
        
        Log.debug("PLACE \(place.name) has GROUP \(place.group?.name)")
        
        //self.place = mock.getPlaceUI(1) // No group
    }
}

#Preview {
    NavigationStack {
        MockPlaceEditContentView(5)
    }
    .environment(AppSettings())
}

#endif
