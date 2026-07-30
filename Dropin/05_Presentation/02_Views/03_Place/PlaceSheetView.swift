//
//  PlaceSheetView.swift
//  Dropin
//
//  Created by baptiste sansierra on 23/2/26.
//

import SwiftUI
import ContactFieldKit

struct PlaceSheetView: View {
    
    // MARK: - States & Bindings
    @State private var viewModel: PlaceSheetViewModel
    @Binding private var place: PlaceUI
    @Binding private var currentDetent: PresentationDetent
    @Environment(\.dismiss) private var dismiss
    @Namespace private var menuNamespace
    
    private var menuGeomId = "menuGeomId"
    
    // MARK: - init
    init(viewModel: PlaceSheetViewModel,
         place: Binding<PlaceUI>,
         detent: Binding<PresentationDetent>) {
        self._viewModel = State(initialValue: viewModel)
        self._place = place
        self._currentDetent = detent
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            if let group = place.group {
                groupLayerView(group)
            }
            ZStack {
                Color.backgroundPrimary
                placeContentView
            }
            .if( place.group != nil , action: { view in
                view
                    .cornerRadius(20)
                    .padding(.top, 55)
                    .shadow(radius: 5)
            })
            .ignoresSafeArea()
        }
        .alert(viewModel.openURLAlert?.title ?? "",
               isPresented: Binding(get: {
            viewModel.openURLAlert != nil
        }, set: { v in
            viewModel.openURLAlert = v ? viewModel.openURLAlert : nil
        }), actions: {
        }) {
            Text(viewModel.openURLAlert?.body ?? "")
        }
        .onChange(of: currentDetent) { oldValue, newValue in
            // When sheet is manually moved to medium detent,
            // go back to overview menu
            if oldValue == .large && newValue == .medium {
                viewModel.selectedMenu = .overview
            }
        }
        .onAppear {
            viewModel.loadThumbnails(placeId: place.id)
        }
        .fullScreenCover(isPresented: Binding(get: {
            viewModel.selectedImageIndex != nil
        }, set: { v in
            if !v { viewModel.selectedImageIndex = nil }
        })) {
            ImageFullscreenOverlay(
                thumbnails: viewModel.thumbnails,
                initialIndex: viewModel.selectedImageIndex ?? 0,
                loadFull: { id in await viewModel.getFullImage(id: id, placeId: place.id).data },
                onDismiss: { viewModel.selectedImageIndex = nil }
            )
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func groupLayerView(_ group: GroupUI) -> some View {
        place.groupColor
            .ignoresSafeArea()
        VStack {
            HStack(spacing: 0) {
                IconView(icon: group.icon)
                    .sizeBody()
                    .foregroundStyle(place.groupColor.isDark() ? .backgroundPrimary : .textPrimary)
                Text(group.name)
                    .font(.bodySemibold)
                    .foregroundStyle(place.groupColor.isDark() ? .backgroundPrimary : .textPrimary)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
            }
            .frame(height: 45)
            .padding(.top, 7)
            Spacer()
        }
    }
    
    private var placeContentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerTopView
                .padding(.top, 25)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    subHeaderView
                    //.padding(.top, 25)
                    headerActionsView
                        .frame(height: 55)
                        .padding(.top, 15)
                    menuView
                        .frame(height:45)
                        .padding(.top, 5)
                    Divider()
                    currentMenuContentView
                        .padding(.top, 30)
                }
            }
            Spacer()
        }
    }
    
    private var headerTopView: some View {
        HStack(spacing: 0) {
            if let icon = place.icon {
                PlaceIconView(icon: icon, shadow: false)
                    .padding(.leading, 15)
            }
            Text(verbatim: place.name)
                .textStyle(.title2)
                .lineLimit(3)
                .frame(alignment: .leading)
                .padding(.leading, place.icon == nil ? 15 : 8)
            Spacer()
            Button {
                viewModel.pushPlaceEditView(placeRef: PlaceUIRef(place: place))
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(.backgroundSecondary)
                        .frame(width: 35, height: 35)
                    Image(systemName: "pencil")
                        .textStyle(.body)
                }
                .padding(.trailing, 10)
            }
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(.backgroundSecondary)
                        .frame(width: 35, height: 35)
                    Image(systemName: "multiply")
                        .textStyle(.body)
                }
                .padding(.trailing)
            }
        }
    }
    
    @ViewBuilder
    private var subHeaderView: some View {
        // Rating + Distance
        HStack(alignment: .center, spacing: 0) {
            if let rating = place.rating {
                StarRatingView(rating: rating)
            } else {
                StarRatingView()
            }
            if let dist = viewModel.distanceStringTo(place.coordinates) {
                Text(verbatim: "·")
                    .padding(.horizontal, 5)
                    .font(.caption2)
                Text(dist)
                    .font(.caption2)
            }
            Spacer()
        }
        .padding(.leading)
        .padding(.top, 10)
        .frame(maxWidth: .infinity)
        
        // Address
        Text(place.address.isEmpty ? "" : place.address)
            .textStyle(.placeholder)
            .padding(.horizontal)
            .padding(.top, 10)
            .contextMenu {
                Button(action: { viewModel.copyAddressToClipboard(place: place) } ){
                    Text("common.copy_address")
                }
                Button(action: { viewModel.copyCoordinatesToClipboard(place: place) } ){
                    Text("common.copy_coordinates")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        
        // Address Line 2
        if !place.address2.isEmpty {
            Text(place.address2)
                .foregroundStyle(.textTertiary)
                .font(.footnoteRegular)
                .padding(.horizontal)
                .padding(.top, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var headerActionsView: some View {
        GeometryReader { proxy in
            let hPadding: CGFloat = 15
            let spacing: CGFloat = 10
            //let btWidth: CGFloat = proxy.size.width
            let btWidth: CGFloat = (proxy.size.width - hPadding * 2 - spacing * 3) / 4
            //let btWidth: CGFloat = (proxy.size.width - 15 - spacing * 3) / 4
            HStack(spacing: 0) {
                squareButton(systemImage: "arrow.trianglehead.turn.up.right.diamond.fill",
                             label: "common.directions",
                             width: btWidth,
                             action: { viewModel.showingNavigationDialog.toggle() })
                .padding(.leading, 15)
                .confirmationDialog("common.navigate",
                                    isPresented: $viewModel.showingNavigationDialog,
                                    actions: {
                    Button("navigate_link_google") {
                        viewModel.routeThrowGoogle(place: place)
                    }
                    Button("navigate_link_apple") {
                        viewModel.routeThrowApple(place: place)
                    }
                    Button("navigate_link_waze") {
                        viewModel.routeThrowWaze(place: place)
                    }
                })
                squareButton(systemImage: "phone",
                             label: "common.call",
                             width: btWidth,
                             disabled: place.phone.count == 0,
                             action: call)
                .disabled(place.phone.count == 0)
                .padding(.leading, spacing)
                squareButton(systemImage: "globe.europe.africa.fill",
                             label: "common.website",
                             width: btWidth,
                             disabled: place.url.count == 0,
                             action: openWebLink)
                .padding(.leading, spacing)
                squareButton(systemImage: "square.and.arrow.up",
                             label: "common.share",
                             width: btWidth,
                             action: share)
                .padding(.leading, spacing)
            }
        }
    }
    
    private var menuView: some View {
        HStack(spacing: 0) {
            ForEach(PlaceSheetViewModel.MenuItem.allCases, id: \.self) { item in
                Button(action: {
                    updateSelectedMenu(item)
                }) {
                    Text(item.label)
                        .foregroundStyle(viewModel.selectedMenu == item ? .dropinPrimary : .textTertiary)
                        .textStyle(.bodySemibold)
                        .frame(maxHeight: .infinity)
                        .overlay {
                            if viewModel.selectedMenu == item {
                                VStack {
                                    Spacer()
                                    Rectangle()
                                        .fill(.dropinPrimary)
                                        .matchedGeometryEffect(id: menuGeomId, in: menuNamespace)
                                        .frame(height: 2)
                                }
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private var currentMenuContentView: some View {
        switch viewModel.selectedMenu {
            case .overview:
                overviewView
            case .contact:
                if place.phone.count + place.email.count + place.url.count == 0 {
                    contactPlaceholderView
                } else {
                    contactView
                }
            case .images:
                if viewModel.thumbnails.isEmpty {
                    picturePlaceholderView
                } else {
                    PlaceImagesTabView(thumbnails: viewModel.thumbnails,
                                       onTapImage: { index in
                        viewModel.selectedImageIndex = index
                    })
                }
        }
    }
    
    @ViewBuilder
    private var overviewView: some View {
        if place.tags.count > 0 {
            FlowLayout(alignment: .leading) {
                let sortedTags = place.tags.sorted(by: { $0.name < $1.name && $0.createdAt < $1.createdAt })
                ForEach(sortedTags) { tag in
                    TagView(name: tag.name, color: tag.color)
                }
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 15)
        } else {
            ZStack {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Image(systemName: "tag")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.backgroundTertiary)
                            .padding(.horizontal)
                        Text("placeholder.no_tags")
                            .font(.body)
                            .foregroundStyle(.backgroundTertiary)
                        Spacer()
                        
                        Button(action: edit) {
                            ZStack {
                                Circle()
                                    .fill(.dropinPrimary)
                                    .frame(width: 35, height: 35)
                                Image(systemName: "pencil")
                                    .font(.bodyRegular)
                                    .foregroundStyle(.backgroundPrimary)
                            }
                            .padding(.trailing)
                        }
                    }
                }
            }
        }
    }
    
    private var contactPlaceholderView: some View {
        VStack {
            ContentUnavailableView("placeholder.no_contact.title",
                                   systemImage: "iphone.gen2.slash",
                                   description: Text("placeholder.no_contact.body"))
            
            MainButton(text: "common.edit", action: edit)
        }
        .padding(.horizontal)
    }
    
    private var picturePlaceholderView: some View {
        VStack {
            ContentUnavailableView("placeholder.no_images.title",
                                   systemImage: "photo.on.rectangle",
                                   description: Text("placeholder.no_images.body"))
            MainButton(text: "common.edit", action: edit)
        }
        .padding(.horizontal)
    }

    private var contactView: some View {
        VStack(alignment: .leading, spacing : 0) {
            ContactItemView(contactItems: $place.phone)
                .padding(.bottom, 20)
                .scaleEffect(viewModel.phoneScale)
                .shadow(radius: 1)
                .opacity($place.phone.count > 0 ? 1 : 0)
            
            ContactItemView(contactItems: $place.email)
                .padding(.bottom, 20)
                .shadow(radius: 1)
                //.border(.textPrimary)
                .opacity($place.email.count > 0 ? 1 : 0)
            
            ContactItemView(contactItems: $place.url)
                .shadow(radius: 1)
                .scaleEffect(viewModel.urlScale)
                //.border(.textPrimary)
                .opacity($place.url.count > 0 ? 1 : 0)
        }
    }
    
    private func squareButton(systemImage: String,
                              label: LocalizedStringKey,
                              width: CGFloat,
                              disabled: Bool = false,
                              action: @escaping () -> Void ) -> some View {
        Button {
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(disabled ? .disabled : .dropinPrimary)
                    .frame(width: width,
                           height: 55)
                VStack(spacing: 0) {
                    Image(systemName: systemImage)
                        .font(.body)
                        .foregroundStyle(.backgroundPrimary)
                }
                .frame(maxHeight: .infinity)
                .padding(.bottom, 15)
                VStack(spacing: 0) {
                    Spacer()
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.backgroundPrimary)
                        .padding(.bottom, 8)
                }
            }
            .frame(width: width,
                   height: 55)
        }
        .disabled(disabled)
    }
    
    // MARK: private methods
    private func updateSelectedMenu(_ item: PlaceSheetViewModel.MenuItem) {
        viewModel.selectedMenu = item
        switch item {
            case .contact, .images:
                currentDetent = .large
            default:
                ()
        }
    }
    
    private func call() {
        guard place.phone.count == 1 else {
            updateSelectedMenu(.contact)
            withAnimation(.easeIn(duration: 0.3).delay(0.2), {
                viewModel.phoneScale = 1.04
            }, completion: {
                withAnimation(.easeOut(duration: 0.3).delay(0.5), {
                    viewModel.phoneScale = 1
                })
            })
            return
        }
        viewModel.call(place: place)
    }
    
    private func openWebLink() {
        guard place.url.count == 1 else {
            updateSelectedMenu(.contact)
            withAnimation(.easeIn(duration: 0.3).delay(0.2), {
                viewModel.urlScale = 1.04
            }, completion: {
                withAnimation(.easeOut(duration: 0.3).delay(0.5), {
                    viewModel.urlScale = 1
                })
            })
            return
        }
        viewModel.openWebLink(place: place)
    }
    
    private func edit() {
        viewModel.pushPlaceEditView(placeRef: PlaceUIRef(place: place))
        dismiss()
    }

    private func share() {
        Log.warning("TO BE IMPLEMENTED")
    }
}

#if DEBUG

struct MockPlaceDetailSheetView: View {
    var mock: MockContainer
    var index: Int
    @State var place: PlaceUI
    @State var detailSheetDetent: PresentationDetent = .medium
    @State var presentedSheet: Bool = false
    
    var body: some View {
        VStack {
            Text(verbatim: "content")
        }
        .onAppear {
            presentedSheet = true
        }
        .sheet(isPresented: $presentedSheet) {
            
            mock.appContainer.createPlaceSheetView(place: $place,
                                                   detent: $detailSheetDetent)
                .presentationDetents([.medium, .large], selection: $detailSheetDetent)
                .presentationCornerRadius(20)
                .presentationBackground(.backgroundPrimary)
        }
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
    // With contacts
    MockPlaceDetailSheetView(6)
}

#Preview {
    MockPlaceDetailSheetView(1)
}

#endif
