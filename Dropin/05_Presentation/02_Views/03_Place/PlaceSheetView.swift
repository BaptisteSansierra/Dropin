//
//  PlaceSheetView.swift
//  Dropin
//
//  Created by baptiste sansierra on 23/2/26.
//

import SwiftUI
import ContactFieldKit
import MapKit

struct PlaceSheetView: View {
    
    // MARK: - States & Bindings
    @State private var viewModel: PlaceSheetViewModel
    @Binding private var place: PlaceUIModel
    @Binding private var currentDetent: PresentationDetent
    @Environment(\.dismiss) private var dismiss
    @Namespace private var menuNamespace

    private var menuGeomId = "menuGeomId"
    private var mapAction: (() -> Void)?
    private let headerActionsViewHeight: CGFloat = 55
    private var isPresentingError: Binding<Bool> {
        Binding {
            viewModel.presentedPOIError != nil
        } set: { v in
            if v == false { viewModel.presentedPOIError = nil }
        }
    }
    private var shareErrorPresented: Binding<Bool> {
        Binding(get: {
            viewModel.shareErrorMsg != nil
        }, set: { v in
            if !v {
                viewModel.shareErrorMsg = nil
            }
        })
    }
    private var allPhones: Binding<[ContactItem]> {
        Binding {
            var phones = place.phone
            if let applePhone = viewModel.applePhoneContactItem(place) {
                phones.append(applePhone)
            }
            return phones
        } set: { _ in
            // read-only
        }
    }
    private var allUrls: Binding<[ContactItem]> {
        Binding {
            var urls = place.url
            if let appleUrl = viewModel.appleUrlContactItem(place) {
                urls.append(appleUrl)
            }
            return urls
        } set: { _ in
            // read-only
        }
    }

    // MARK: - init
    init(viewModel: PlaceSheetViewModel,
         place: Binding<PlaceUIModel>,
         mapAction: (() -> Void)?,
         detent: Binding<PresentationDetent>) {
        self._viewModel = State(initialValue: viewModel)
        self._place = place
        self.mapAction = mapAction
        self._currentDetent = detent
        
        // local ContactFieldKit config override
        ContactFieldUIConfig.backgroundPrimary = .backgroundPrimary
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            if let category = place.category {
                groupLayerView(category)
            }
            ZStack {
                Color.surface1
                placeContentView
            }
            .if( place.category != nil , action: { view in
                view
                    .cornerRadius(20)
                    .padding(.top, 55)
                    .shadow(radius: 5)
            })
            .ignoresSafeArea()
        }
        .task {
            await viewModel.fetchAppleDataIfNeeded(for: place)
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
        .sheet(item: $viewModel.shareURL) { shareURL in
            ShareSheet(url: shareURL.url, message: viewModel.shareMessage, subject: viewModel.shareSubject)
        }
        .alertOk(isPresented: shareErrorPresented,
                 title: "place_sheet.share.error.title",
                 body: LocalizedStringKey(viewModel.shareErrorMsg ?? ""))
        .alertOk(isPresented: isPresentingError,
                 title: errorTitle(),
                 body: errorBody())
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func groupLayerView(_ category: CategoryUIModel) -> some View {
        place.categoryColor
            .ignoresSafeArea()
        VStack {
            HStack(spacing: 0) {
                IconView(icon: category.icon)
                    .sizeBody()
                    .foregroundStyle(place.categoryColor.isDark() ? .backgroundPrimary : .textPrimary)
                Text(category.name)
                    .font(.bodySemibold)
                    .foregroundStyle(place.categoryColor.isDark() ? .backgroundPrimary : .textPrimary)
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
                        .frame(height: headerActionsViewHeight)
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
            // Edit button
            Button {
                viewModel.pushPlaceEditView(placeRef: PlaceUIModelRef(place: place))
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
            #if false
            // Share button
            Button {
                share()
            } label: {
                ZStack {
                    Circle()
                        .fill(.backgroundSecondary)
                        .frame(width: 35, height: 35)
                    Image(systemName: "square.and.arrow.up")
                        .textStyle(.body)
                }
                .padding(.trailing)
            }
            #endif
            // Close button
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
        
        if let applePlaceID = place.applePlaceID {
            ApplePOIViewFactory.applePOINativeBtView {
                presentApplePOIDetails(applePlaceID)
            }
            .padding(.leading)
            .padding(.top, 5)
            .padding(.bottom, 0)
            .mapItemDetailSheet(item: $viewModel.presentedMapItem, displaysMap: true)
        }
        
        // Rating + Distance
        HStack(alignment: .center, spacing: 0) {
            if let rating = place.rating {
                StarRatingView(rating: rating)
            //} else {
            //    StarRatingView()
            }
            if let rating = place.rating,
               let dist = viewModel.distanceStringTo(place.coordinates) {
                Text(verbatim: "·")
                    .padding(.horizontal, 5)
                    .font(.caption2)
            }
            if let dist = viewModel.distanceStringTo(place.coordinates) {
                Text(dist)
                    .font(.caption2)
            }
            Spacer()
        }
        .padding(.leading)
        .padding(.top, 10)
        .frame(maxWidth: .infinity)
        
        // Address
        Text(place.address ?? place.coordinates.formatted())
            .textStyle(.placeholder)
            .padding(.horizontal)
            .padding(.top, 10)
            .contextMenu {
                if let _ = place.address {
                    Button(action: { viewModel.copyAddressToClipboard(place: place) } ){
                        Text("common.copy_address")
                    }
                }
                Button(action: { viewModel.copyCoordinatesToClipboard(place: place) } ){
                    Text("common.copy_coordinates")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        
        // Address Line 2
        if let address2 = place.address2, !address2.isEmpty {
            Text(address2)
                .foregroundStyle(.textTertiary)
                .font(.footnoteRegular)
                .padding(.horizontal)
                .padding(.top, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func directionsButton(_ nbButtons: Int) -> some View {
        Button {
            viewModel.showingNavigationDialog.toggle()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.dropinPrimary)
                    .frame(height: 55)
                if nbButtons <= 4 {
                    HStack(alignment: .center, spacing: 0) {
                        Image(systemName: "arrow.trianglehead.turn.up.right.diamond.fill")
                            .font(.body)
                            .foregroundStyle(.surface1)
                            .padding(.trailing, 10)
                        Text("common.directions")
                            .font(.body)
                            .foregroundStyle(.surface1)
                    }
                } else {
                    VStack(spacing: 0) {
                        Image(systemName: "arrow.trianglehead.turn.up.right.diamond.fill")
                            .font(.body)
                            .foregroundStyle(.surface1)
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, 15)
                    VStack(spacing: 0) {
                        Spacer()
                        Text("common.directions")
                            .font(.caption2)
                            .foregroundStyle(.surface1)
                            .padding(.bottom, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
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
    }
    
    private func nbActions() -> Int {
        var count = 2 // directions + share buttons are always visible
        if phoneItemCount() > 0 { count += 1 }
        if urlItemCount() > 0 { count += 1 }
        if let _ = mapAction { count += 1 }
        return count
    }

    private var headerActionsView: some View {
        HStack(spacing: 0) {
            let spacing: CGFloat = 10
            let nbButtons: Int = nbActions()
            directionsButton(nbButtons)
                .padding(.horizontal, spacing)
            if phoneItemCount() > 0 {
                squareButton(systemImage: "phone",
                             label: "common.call",
                             height: headerActionsViewHeight,
                             width: headerActionsViewHeight + 10,
                             action: call)
                .padding(.trailing, spacing)
            }
            if urlItemCount() > 0 {
                squareButton(systemImage: "globe.europe.africa.fill",
                             label: "common.website",
                             height: headerActionsViewHeight,
                             width: headerActionsViewHeight + 10,
                             action: openWebLink)
                .padding(.trailing, spacing)
            }
            if let mapAction = mapAction {
                squareButton(systemImage: "map",
                             label: "common.map",
                             height: headerActionsViewHeight,
                             width: headerActionsViewHeight + 10,
                             action: mapAction)
                .padding(.trailing, spacing)
            }
            squareButton(systemImage: "square.and.arrow.up",
                         label: "common.share",
                         height: headerActionsViewHeight,
                         width: headerActionsViewHeight + 10,
                         action: share)
            .padding(.trailing, spacing)
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
                if contactItemCount() == 0 {
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

    private var overviewView: some View {
        VStack(spacing: 0) {
            overviewTagsView
            overviewNotesView
        }
    }
    
    @ViewBuilder
    private var overviewTagsView: some View {
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
            HStack(spacing: 0) {
                Image(systemName: "tag")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.textTertiary)
                    .frame(width: 25, height: 25)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.backgroundTertiary.opacity(0.4))
                    }
                (Text("placeholder.no_tags") +
                Text(verbatim: " - ") +
                Text("placeholder.no_tags_plus"))
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    @ViewBuilder
    private var overviewNotesView: some View {
        if let notes = place.notes {
            Text(notes)
                .textStyle(.cardPlaceholder)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.backgroundPrimary)
                        .stroke(.backgroundTertiary)
                }
                .padding(.horizontal)

        } else {
            HStack(spacing: 0) {
                Image(systemName: "text.page")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.textTertiary)
                    .frame(width: 25, height: 25)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.backgroundTertiary.opacity(0.4))
                    }
                (Text("placeholder.no_notes") +
                Text(verbatim: " - ") +
                Text("placeholder.no_notes_plus"))
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
            }
            .padding(.horizontal)
        }
    }
    
    private var contactPlaceholderView: some View {
        VStack {
            ContentUnavailableView("placeholder.no_contact.title",
                                   systemImage: "iphone.gen2.slash",
                                   description: Text("placeholder.no_contact.body"))
            .opacity(0.5)
            //MainButton(text: "common.edit", action: edit)
        }
        .padding(.horizontal)
    }
    
    private var picturePlaceholderView: some View {
        VStack {
            ContentUnavailableView("placeholder.no_images.title",
                                   systemImage: "photo.on.rectangle",
                                   description: Text("placeholder.no_images.body"))
            .opacity(0.5)
            //MainButton(text: "common.edit", style: .bordered, action: edit)
        }
        .padding(.horizontal)
    }

    private var contactView: some View {
        VStack(alignment: .leading, spacing : 0) {
            ContactItemView(contactItems: allPhones)
                .padding(.bottom, 20)
                .scaleEffect(viewModel.phoneScale)
                .shadow(radius: 1)
                .opacity(phoneItemCount() > 0 ? 1 : 0)
            
            ContactItemView(contactItems: $place.email)
                .padding(.bottom, 20)
                .shadow(radius: 1)
                //.border(.textPrimary)
                .opacity(place.email.count > 0 ? 1 : 0)
            
            ContactItemView(contactItems: allUrls)
                .shadow(radius: 1)
                .scaleEffect(viewModel.urlScale)
                //.border(.textPrimary)
                .opacity(urlItemCount() > 0 ? 1 : 0)
        }
    }
    
    private func squareButton(systemImage: String,
                              label: LocalizedStringKey,
                              height: CGFloat,
                              width: CGFloat,
                              action: @escaping () -> Void ) -> some View {
        Button {
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.backgroundPrimary)
                    .frame(width: width,
                           height: height)
                VStack(spacing: 0) {
                    Image(systemName: systemImage)
                        .font(.body)
                        .foregroundStyle(.dropinPrimary)
                }
                .frame(maxHeight: .infinity)
                .padding(.bottom, 15)
                VStack(spacing: 0) {
                    Spacer()
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.dropinPrimary)
                        .padding(.bottom, 8)
                }
            }
            .frame(width: width,
                   height: height)
        }
        .frame(width: width)
    }
    
    // MARK: private methods
    private func phoneItemCount() -> Int {
        viewModel.applePhoneNumber == nil ? 0 : 1 + place.phone.count
    }

    private func urlItemCount() -> Int {
        viewModel.appleURL == nil ? 0 : 1 + place.url.count
    }

    private func contactItemCount() -> Int {
        phoneItemCount() + place.email.count + urlItemCount()
    }

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
        guard phoneItemCount() == 1 else {
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
        guard urlItemCount() == 1 else {
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
        viewModel.pushPlaceEditView(placeRef: PlaceUIModelRef(place: place))
        dismiss()
    }

    private func share() {
        Task {
            await viewModel.share(place: place)
        }
    }
    
    private func presentApplePOIDetails(_ applePlaceID: String) {
        if let mapItem = viewModel.resolvedMapItem {
            viewModel.presentedMapItem = mapItem
            return
        }
        if let error = viewModel.applePOIError {
            viewModel.presentedPOIError = error
        }
        // probably loading state here, it's supposed to be quick,
        // it will hardly happen
        // TODO: present a specific alert anyway
    }
    
    private func errorTitle() -> LocalizedStringKey {
        guard let error = viewModel.presentedPOIError else { return "" }
        switch error {
            case .notFound:
                return "apple_poi_fetch.error.not_found.title"
            case .notConnected:
                return "apple_poi_fetch.error.not_connected.title"
            case .corrupted:
                return "apple_poi_fetch.error.corrupted.title"
            case .mkUnknown:
                return "apple_poi_fetch.error.mk_unknown.title"
            case .unknown:
                return "apple_poi_fetch.error.unknown.title"
        }
    }

    private func errorBody() -> LocalizedStringKey {
        guard let error = viewModel.presentedPOIError else { return "" }
        switch error {
            case .notFound:
                return "apple_poi_fetch.error.not_found.body"
            case .notConnected:
                return "apple_poi_fetch.error.not_connected.body"
            case .corrupted:
                return "apple_poi_fetch.error.corrupted.body"
            case .mkUnknown(let code):
                let format = NSLocalizedString("apple_poi_fetch.error.mk_unknown.body.%d",
                                               comment: "")
                return LocalizedStringKey(String(format: format, Int(code)))
            case .unknown(let underlyingError):
                return LocalizedStringKey(underlyingError.localizedDescription)
        }
    }
}

#if DEBUG

struct MockPlaceDetailSheetView: View {
    var mock: MockContainer
    var index: Int
    @State var place: PlaceUIModel
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
                                                   mapAction: { print("go do some stuff") },
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
        //self.place = mock.getPlaceUIModel(index)
        self.place = mock.getNoAddressPlaceUIModel()
        
        // Link to an Apple POI
        //self.place.applePlaceID = UUID().uuidString
        self.place.applePlaceID = "IFDEE26634A4EFE23"
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
