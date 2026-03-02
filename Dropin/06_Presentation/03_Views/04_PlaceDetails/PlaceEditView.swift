//
//  PlaceEditView.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/2/26.
//

import SwiftUI
import ContactFieldKit
import NoFlyZone

struct PlaceEditView: View {
    
    // MARK: - States & Bindings
    @State private var viewModel: PlaceEditViewModel
    @Binding private var srcPlace: PlaceUI
    
    // To be moved in VM
    @State private var editedPlace: PlaceUI
    @State private var confirmCancel: Bool = false
    @State private var edited: Bool = false // true if contains some edits
    @State private var scrollY: CGFloat = 0
    //@State private var headerOpacity: CGFloat = 0
    @State private var headerBackgroundOffsetY: CGFloat = 0
    @State private var annotationSize: CGFloat = 50
    @State private var annotationBottomPading: CGFloat = 40
    @State private var headerNameOpacity: CGFloat = 0
    @State private var showingGroupSelector: Bool = false
    @State private var showingTagSelector: Bool = false
    @State private var showingMarkerList: Bool = false
    // We use UI models for contact presentation
    @State private var phones: [ContactItemUI] = []
    @State private var emails: [ContactItemUI] = []
    @State private var urls: [ContactItemUI] = []
    // NoFlyZone states
    @State private var noFlyZoneEnabled: Bool = false
    @State private var noFlyAuthorizedZones: [NoFlyZoneData] = []
    @State private var noFlyZoneCompletionStatus: NoFlyZoneCompletionStatus = .undefined
    @State private var showDeleteWarning = false
    
    private let scrollCoordinateSpace = "scroll"
    private let topLayerHeight: CGFloat = 200
    
    // MARK: - Init
    init(viewModel: PlaceEditViewModel, place: Binding<PlaceUI>) {
        self.viewModel = viewModel
        self._srcPlace = place
        self.editedPlace = place.wrappedValue.copy()
        
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
                scrollView
                headerView
            }
            .navigationBarBackButtonHidden(true)
            .toolbar { toolbar }
            .onChange(of: editedPlace.changeToken) { oldValue, newValue in
                print("Place edited !! isEqual to source = \(editedPlace.isContentEqual(srcPlace))")
                edited = !editedPlace.isContentEqual(srcPlace)
            }
        }
        .noFlyZone(enabled: noFlyZoneEnabled,
                   authorizedZones: noFlyAuthorizedZones,
                   onAllowed: noFlyZoneOnAllowed,
                   onBlocked: noFlyZoneOnBlocked,
                   coloredDebugOverlay: true)
        .onChange(of: phones) { oldValue, newValue in
            applyUpdate()
        }
        .onChange(of: emails) { oldValue, newValue in
            applyUpdate()
        }
        .onChange(of: urls) { oldValue, newValue in
            applyUpdate()
        }
    }
    
    func             applyUpdate() {
        print("TODO")
    }
    private func noFlyZoneOnBlocked() {
        noFlyZoneEnabled = false
        noFlyZoneCompletionStatus = .blocked
    }
    private func noFlyZoneOnAllowed(tappedZones: [NoFlyZoneData]) {
        noFlyZoneEnabled = false
        noFlyZoneCompletionStatus = .allowed
        
        for z in tappedZones {
            if z.viewId == 1 {
                phones[z.itemId].toBeDeleted = true
            }
            else if z.viewId == 2 {
                emails[z.itemId].toBeDeleted = true
            }
            else if z.viewId == 3 {
                urls[z.itemId].toBeDeleted = true
            }
        }
    }
    
    // MARK: - Subviews
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("common.cancel", action: cancelEdits)
                .tint(.blue)
                .confirmationDialog("Are you sure you want to discard your changes ?",
                                    isPresented: $confirmCancel,
                                    titleVisibility: .visible,
                                    actions: {
                    Button("Discard Changes", role: .destructive) {
                        editedPlace = srcPlace.copy()
                    }
                    Button("Keep Editing") {
                    }
                })
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("common.done", action: applyEdits)
                .disabled(viewModel.mode != .creation && !edited)
                .tint(.blue)
        }
    }
    
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
                PlaceAnnotationView(color: editedPlace.groupColor,
                                    icon: editedPlace.group?.icon,
                                    iconExtra: editedPlace.icon,
                                    size: annotationSize)
            }
            .padding(.bottom, annotationBottomPading)
            
            VStack {
                Spacer()
                Text(editedPlace.name)
                    .font(.captionMedium)
                    .foregroundStyle(.textSecondary)
                    .opacity(headerNameOpacity)
                    .padding(.bottom, 10)
            }
        }
        .frame(height: topLayerHeight)
        .offset(x: 0, y: headerBackgroundOffsetY)
        .ignoresSafeArea()
    }
    
    /*
     @ViewBuilder
     private func minimizedHeaderView(_ proxy: GeometryProxy) -> some View {
     let topInset = proxy.safeAreaInsets.top
     ZStack {
     Rectangle()
     .fill(.backgroundTertiary)
     .frame(height: topInset + 25)
     VStack(spacing: 0) {
     Spacer()
     PlaceAnnotationView(color: place.groupColor,
     icon: place.group?.icon,
     iconExtra: place.icon)
     .padding(.bottom, 10)
     Text(editedPlace.name)
     .textStyle(.caption)
     .padding(.bottom, 25)
     
     //Divider()
     }
     }
     .ignoresSafeArea()
     .frame(height: topInset + 25)
     .padding(.top, 0)
     .ignoresSafeArea(edges: .top)
     .opacity(headerOpacity)
     .onAppear {
     print("Top inset is \(topInset)")
     }
     }
     */
    
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
                addressView
                    .padding(.top, 20)
                groupView
                    .padding(.top, 20)
                tagView
                    .padding(.top, 20)
                iconView
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
                    .padding(.top, 20)
                deleteButton
                    .padding(.top, 50)
            }
            .padding(.bottom, 50)
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
                TextField("common.name", text: $editedPlace.name)
                    .textStyle(.body)
                    .background(.clear)
                    .padding(.vertical, 0)
                    .padding(.horizontal)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit {
                        //updateGroup()
                    }
            }
        }
    }
    
    private var addressView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("common.address")
                .textStyle(.formSectionTitle2)
                .padding(.leading)
                .padding(.bottom, 10)
            
            //let address = place.address
            let address = "3 rue du cus\nla rochelle\n16789\nfrance"
            Text(editedPlace.address.isEmpty ? "" : address)
                .textStyle(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(.backgroundPrimary)
        }
        .onTapGesture {
            print("Edit address")
        }
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
                
                PlaceGroupView(place: $editedPlace,
                               showingGroupSelector: $showingGroupSelector,
                               editEnabled: true,
                               presentationMode: .form)
                .background(.backgroundPrimary)
                if editedPlace.group == nil {
                    Text("placeholder.no_group")
                        .foregroundStyle(.disabled)
                        .textStyle(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            
        }
        .sheet(isPresented: $showingGroupSelector) {
            viewModel.createGroupSelectorView(place: $editedPlace)
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
                PlaceTagsView(place: $editedPlace,
                              showingTagsSelector: $showingTagSelector,
                              editEnabled: true,
                              presentationMode: .form)
                if editedPlace.tags.count == 0 {
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
            viewModel.createTagSelectorView(place: $editedPlace)
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
                    if let icon = editedPlace.icon {
                        ZStack(alignment: .center) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.clear)
                                .stroke(.textPrimary)
                                .frame(width: 80, height: 35)
                            IconView(icon: icon)
                        }
                        .padding(.leading)
                    }
                    Spacer()
                    IcoButton(systemImage: "ellipsis",
                              icoSize: 14,
                              action: { showingMarkerList.toggle() })
                    .padding(.trailing, 15)
                }
                if editedPlace.icon == nil {
                    Text("placeholder.no_icon")
                        .foregroundStyle(.disabled)
                        .textStyle(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .fullScreenCover(isPresented: $showingMarkerList) {
            MarkerListView(selected: $editedPlace.icon)
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
                
                if let rating = editedPlace.rating {
                    HStack(alignment: .center, spacing: 0) {
                        StarEditRatingView(rating: Binding<Float>(get: {
                            rating
                        }, set: { rating in
                            editedPlace.rating = rating
                        }))
                        .padding(.leading, 15)
                        Spacer()
                        IcoButton(systemImage: "minus",
                                  icoSize: 14,
                                  icoColor: .destructive,
                                  action: { editedPlace.rating = nil })
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
                                  action: { editedPlace.rating = 3 })
                        .padding(.trailing, 15)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingMarkerList) {
            MarkerListView(selected: $editedPlace.icon)
        }
    }
    
    private var phoneView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("common.phone")
                .textStyle(.formSectionTitle2)
                .padding(.leading)
                .padding(.bottom, 10)
            
            ContactItemEditView(viewIdentifier: 1,
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
            
            ContactItemEditView(viewIdentifier: 1,
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
            
            ContactItemEditView(viewIdentifier: 1,
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
                        editedPlace.notes ?? ""
                    }, set: { value in
                        editedPlace.notes = value
                    }))
                    .lineLimit(0)
                    .padding()
                    Spacer()
                }
            }
        }
        .fullScreenCover(isPresented: $showingMarkerList) {
            MarkerListView(selected: $editedPlace.icon)
        }
    }
    
    private var deleteButton: some View {
        HStack() {
            Spacer()
            DestructiveButton(text: "common.delete_place",
                              action: onPressDelete)
            .padding(.bottom, 15)
            .alert("alert.delete_place_title_\(editedPlace.name)",
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
        //print("Offset = \(scrollY)")
        // Update header offset
        let headerOffsetLimit: CGFloat = 70
        headerBackgroundOffsetY = min(max(scrollY, -headerOffsetLimit), 0)
        //print("headerBackgroundOffsetY = \(headerBackgroundOffsetY)")
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
        // Update minimized header visibility
        //        let step1: CGFloat = -125
        //        let step2: CGFloat = -140
        //        if scrollY < step2 {
        //            headerOpacity = 1
        //        } else if scrollY > step1 {
        //            headerOpacity = 0
        //        } else {
        //            headerOpacity = abs(scrollY - step1) / abs(step1 - step2)
        //        }
    }
    
    private func applyEdits() {
        // Apply edits
        srcPlace = editedPlace
        editedPlace = srcPlace.copy()
    }
    
    private func cancelEdits() {
        guard edited else {
            // TODO: dismiss or pop
            return
        }
        // Ask confirmation if there's some edits
        confirmCancel = true
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

                /* TODO
                place.databaseDeleted = true
                try await viewModel.updatePlace(place)
                viewModel.popView()
                try await Task.sleep(for: .seconds(0.5))
                try await viewModel.deletePlace(place)
                 */
            } catch {
                assertionFailure("Failed to delete place \(editedPlace.name)")
            }
        }
    }
}


#if DEBUG

struct MockPlaceEditView: View {
    var mock: MockContainer
    var index: Int
    @State var place: PlaceUI
    
    var body: some View {
        mock.appContainer.createPlaceEditView(place: $place, mode: .edit)
    }
    
    init(_ index: Int) {
        self.index = index
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUI(index)
        
        print("PLACE \(place.name) has GROUP \(place.group?.name)")
        
        //self.place = mock.getPlaceUI(1) // No group
    }
}

#Preview {
    NavigationStack {
        MockPlaceEditView(5)
    }
}

#endif
