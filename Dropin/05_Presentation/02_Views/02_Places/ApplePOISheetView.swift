//
//  ApplePOISheetView.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/10/26.
//

import SwiftUI
import MapKit
import ContactFieldKit

struct ApplePOISheetView: View {
    
    // MARK: States & Bindings
    @State private var viewModel: ApplePOISheetViewModel
    @Binding private var draftPlace: PlaceUIModel?
    @Binding private var draftPlacePoiCategory: MKPointOfInterestCategory?
    @Binding private var draftPlacePoiColor: Color?
    @Environment(\.dismiss) private var dismiss

    // MARK: init
    init(viewModel: ApplePOISheetViewModel,
         draftPlace: Binding<PlaceUIModel?>,
         draftPlacePoiCategory: Binding<MKPointOfInterestCategory?>,
         draftPlacePoiColor: Binding<Color?>) {
        self.viewModel = viewModel
        self._draftPlace = draftPlace
        self._draftPlacePoiCategory = draftPlacePoiCategory
        self._draftPlacePoiColor = draftPlacePoiColor
    }

    // MARK: Body
    var body: some View {
        contentView
        .task {
            await viewModel.load()
        }
        .mapItemDetailSheet(item: $viewModel.presentedMapItem, displaysMap: true)
    }
    
    // MARK: Subviews
    @ViewBuilder
    private var contentView: some View {
        if let mapItem = viewModel.mapItem {
            resultView(mapItem)
        } else if let error = viewModel.error {
            errorView(error)
        } else {
            loadingView
        }
    }

    private func resultView(_ mapItem: MKMapItem) -> some View {
        VStack {
            HStack(alignment: .center) {
                poiIcon
                    .padding(.trailing, 5)
                if let name = mapItem.name {
                    VStack {
                        Text(name)
                            .textStyle(.subheadlineSemibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if let pointOfInterestCategory = viewModel.applePOIAnnotation.pointOfInterestCategory {
                            Text(verbatim: pointOfInterestCategory.displayName)
                                .textStyle(.footnote, color: .textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } else if let pointOfInterestCategory = viewModel.applePOIAnnotation.pointOfInterestCategory {
                    Text(verbatim: pointOfInterestCategory.displayName)
                        .textStyle(.subheadlineSemibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
                CloseButton {
                    dismiss()
                }
            }
            .padding(.top, 35)
            .padding(.bottom, 10)

            ApplePOIViewFactory.applePOINativeBtView {
                viewModel.presentedMapItem = mapItem
            }
            .padding(.bottom, 15)

            let address = (mapItem.resolvedAddress() ?? mapItem.resolvedArea())
            if let _ = mapItem.identifier {
                ApplePOIViewFactory.fullCardView(address: address,
                                                 phoneNumber: mapItem.phoneNumber,
                                                 url: mapItem.url)
            } else {
                ApplePOIViewFactory.missingIdView(address: address)
            }
            Spacer()
            MainButton(text: "common.create_place", systemImage: "plus") {
                createPlace(mapItem)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var poiIcon: some View {
        if let iconStyle = viewModel.applePOIAnnotation.iconStyle {
            Image(uiImage: iconStyle.image)
                .resizable()
                .frame(width: 35, height: 35)
                .padding(0)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(uiColor: iconStyle.backgroundColor))
                }
        } else {
            Image(systemName: "questionmark")
                .frame(width: 35, height: 35)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.dropinPrimary)
                }
        }
    }
    
    private var missingDataHeader: some View {
        HStack(alignment: .center) {
            poiIcon
                .padding(.trailing, 5)
            if let pointOfInterestCategory = viewModel.applePOIAnnotation.pointOfInterestCategory {
                Text(verbatim: pointOfInterestCategory.displayName)
                    .textStyle(.subheadlineSemibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
            CloseButton {
                dismiss()
            }
        }
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack {
            missingDataHeader
                .padding(.top, 30)
            RoundedRectangle(cornerRadius: 8)
                .fill(.clear)
                .stroke(.fieldBorder)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    VStack {
                        Spacer()
                        Image(systemName: "exclamationmark.icloud")
                            .frame(width: 45, height: 45)
                            .background {
                                Circle()
                                    .fill(.backgroundPrimary)
                            }
                        Text("apple_poi_sheet.error.title")
                            .multilineTextAlignment(.center)
                            .textStyle(.footnoteMedium)
                            .padding(.horizontal, 30)
                            .padding(.top, 5)
                        Text("apple_poi_sheet.error.body")
                            .multilineTextAlignment(.center)
                            .textStyle(.caption, color: .textSecondary)
                            .padding(.horizontal, 50)
                            .padding(.top, 5)
                        Spacer()
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 10)

            MainButton(text: "common.try_again", systemImage: "arrow.clockwise") {
                Task {
                    await viewModel.load()
                }
            }
        }
        .padding(.horizontal)
    }

    private var loadingView: some View {
        VStack {
            missingDataHeader
                .padding(.top, 30)
            RoundedRectangle(cornerRadius: 8)
                .fill(.clear)
                .stroke(.fieldBorder)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    VStack {
                        Spacer()
                        HStack(spacing: 0) {
                            DropinLoader(style: .inline, size: .small)
                                .padding(.trailing)
                            Text("apple_poi_sheet.loading")
                                .textStyle(.caption, color: .textTertiary)
                            Text(verbatim: "...")
                                .textStyle(.caption, color: .textTertiary)
                        }
                        Spacer()
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 10)

            MainButton(text: "common.create_place", systemImage: "plus") {}
                .disabled(true)
        }
        .padding(.horizontal)
    }
    
    // MARK: private methods
    private func createPlace(_ mapItem: MKMapItem) {
        if let appleIdentifier = mapItem.identifier?.rawValue {
            draftPlace = PlaceUIModel(name: mapItem.name,
                                      coordinates: mapItem.resolvedCoordinates(),
                                      address: mapItem.resolvedAddress(),
                                      applePlaceID: appleIdentifier)
        } else {
            draftPlace = PlaceUIModel(name: mapItem.name,
                                      coordinates: mapItem.resolvedCoordinates(),
                                      address: mapItem.resolvedAddress(),
                                      phone: [],
                                      url: [])

            // NOTE: The following code copies phone & URL from Apple to our database. It is forbidden by Apple...
            //       If user creates a place from this POI, create a simple Place
            //       without any link or data from Apple

            #if false
            // There's some reports about MKMapItems without identifiers
            // Handle this case by creating a place disconnected from Apple POI
            // but use the phoneNumber ans url anyway if provided
            var phones: [ContactItem] = []
            if let phoneNumber = mapItem.phoneNumber {
                let label = String(localized: LocalizedStringResource(stringLiteral: "common.from_apple_maps"))
                phones.append(ContactItem(value: phoneNumber,
                                          label: ContactLabel(kind: .phone, label: .custom(label))))
            }
            var urls: [ContactItem] = []
            if let url = mapItem.url {
                let label = String(localized: LocalizedStringResource(stringLiteral: "common.from_apple_maps"))
                urls.append(ContactItem(value: url.absoluteString,
                                        label: ContactLabel(kind: .url, label: .custom(label))))
            }
            draftPlace = PlaceUIModel(name: mapItem.name,
                                      coordinates: mapItem.resolvedCoordinates(),
                                      address: mapItem.resolvedAddress(),
                                      phone: phones,
                                      url: urls)
            #endif
        }
        if let poiCategory = mapItem.pointOfInterestCategory {
            draftPlacePoiCategory = poiCategory
        }
        if let poiColor = viewModel.applePOIAnnotation.iconStyle?.backgroundColor {
            draftPlacePoiColor = Color(uiColor: poiColor)
        }
        dismiss()
    }
}
