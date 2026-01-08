//
//  LookupPlaceView.swift
//  Dropin
//
//  Created by baptiste sansierra on 27/12/25.
//

import SwiftUI
import Contacts

struct LookupPlaceView: View {
    
    // MARK: - States & Bindings
    @State private var viewModel: LookupPlaceViewModel

    // MARK: - init
    init(viewModel: LookupPlaceViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - body
    var body: some View {
        ZStack {
            Color.gray
                .opacity(0.25)
                .ignoresSafeArea()
            if let result = viewModel.resolvedResult {
                VStack {
                    Spacer()
                    if viewModel.showContent {
                        contentView(result)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        if viewModel.showContent {
                            cancelButton
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                        Spacer()
                        if viewModel.showContent {
                            confirmButton
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                        Spacer()
                    }
                    Spacer()
                }
                
            } else {
                loadingView
            }
        }
        .task {
            await viewModel.requestPlace()
        }
    }
    
    private var cancelButton: some View {
        Button {
            cancel()
        } label: {
            ZStack {
                Circle()
                    .fill(.white)
                    .stroke(.red, style: StrokeStyle(lineWidth: 2))
                    .frame(width: 60, height: 60)
                Image(systemName: "multiply")
                    .font(.system(size: 30))
                    .foregroundStyle(.red)
                    .opacity(0.2)
            }
            .padding(.trailing, 20)
        }
    }
    
    private var confirmButton: some View {
        Button {
            confirm()
        } label: {
            ZStack {
                Circle()
                    .fill(.white)
                    .stroke(.dropinPrimary, style: StrokeStyle(lineWidth: 2))
                    .frame(width: 60, height: 60)
                Image(systemName: "plus")
                    .font(.system(size: 30))
                    .foregroundStyle(.dropinPrimary)
                    .opacity(0.2)
            }
            .padding(.leading, 20)
        }
    }

    
    // MARK: - subviews
    private var loadingView: some View {
        VStack {
            Text("Loading...")
            ProgressView()
        }
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack {
            Text("Error")
            Text(error.localizedDescription)
        }
    }
    
    @ViewBuilder
    private func contentView(_ result: Result<LookupResolvedItem, Error>) -> some View {
        switch result {
            case .success(let item):
                contentView(item)
            case .failure(let error):
                errorView(error)
        }
    }
    
    private func contentView(_ item: LookupResolvedItem) -> some View {
        VStack {
            Map(position: $viewModel.camera,
                interactionModes: []) {
                markerResolvingName(for: item)
                UserAnnotation()
            }
            .overlay {
                HStack {
                    Spacer()
                    VStack(spacing: 0){
                        Spacer()
                        MapIcoButton(systemImage: "plus",
                                     imageFrame: CGSize(width: 15, height: 15),
                                     color: viewModel.cameraDistance < 125 ? .gray : .dropinPrimary )
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 15, trailing: 10))
                            .onTapGesture {
                                viewModel.zoomIn()
                            }
                        MapIcoButton(systemImage: "minus",
                                     imageFrame: CGSize(width: 15, height: 15),
                                     color: viewModel.cameraDistance >= 32_768_000 ? .gray : .dropinPrimary)
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 15, trailing: 10))
                            .onTapGesture {
                                viewModel.zoomOut()
                            }
                    }
                }
            }
            .onAppear {
                viewModel.updateCamera(coordinates: item.location)
            }
            .frame(height: 350)
            .padding(.bottom, 10)
            HStack(spacing: 0) {
                if let poiItem = item as? LookupPOIResolvedItem {
                    ZStack {
                        Circle()
                            .fill(.dropinPrimary)
                            .frame(width: 30, height: 30)
                        IconView(icon: poiItem.icon)
                            .sizeCaption2()
                            .foregroundStyle(.white)
                            .padding(.horizontal, 0)
                    }
                    .padding(.leading)
                } else {
                    ZStack {
                        Circle()
                            .fill(.dropinPrimary)
                            .frame(width: 30, height: 30)
                        Image(systemName: "signpost.right.and.left")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 0)
                    }
                    .padding(.leading)
                }
                VStack(alignment: .leading, spacing: 0) {
                    textResolvingName(for: item)
                        .cellTitleFormater()
                        .padding(.vertical, 5)
                    Text(item.address)
                        .cellSubtitleFormater()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                if let distance = item.distance {
                    Text(distance)
                        .font(.caption2)
                        .padding(.trailing)
                }
            }
            .padding(.bottom)

        }
        .cornerRadius(25)
        .background(.clear)
        .background {
            RoundedRectangle(cornerRadius: 25)
                .fill(.white)
                .shadow(color: .black.opacity(0.3), radius: 6, x: 2, y: -4)
                
        }
        .padding()
    }
    
    // MARK: - private methods
    private func textResolvingName(for item: LookupResolvedItem) -> Text {
        if let poiItem = item as? LookupPOIResolvedItem,
           let poiName = poiItem.name {
            return Text(verbatim: poiName)
        }
        return Text("common.new_place")
    }
    
    private func markerResolvingName(for item: LookupResolvedItem) -> some MapContent {
        if let poiItem = item as? LookupPOIResolvedItem,
           let poiName = poiItem.name {
            return Marker(poiName,
                          systemImage: item.mapItem.icon().name,
                          coordinate: item.location)
        }
        return Marker("common.new_place",
                      systemImage: item.mapItem.icon().name,
                      coordinate: item.location)
    }
    
    private func confirm() {
    }
    
    private func cancel() {
    }
}



#if DEBUG

import MapKit

struct MockLookupPlaceView: View {
    var mock: MockContainer
    @State private var results: [LookupResult] = []
    @State private var lookupError: Error?

    var body: some View {
        VStack {
            if let error = lookupError {
                VStack {
                    Text("Error")
                    Text(error.localizedDescription)
                }
            } else if let first = results.first {
                mock.appContainer.createLookupPlaceView(lookupResult: first)
            } else {
                VStack {
                    Text("Loading...")
                    ProgressView()
                }
            }
        }
        .task {
            await load()
        }
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
    }
    
    private func load() async {
        do {
            //self.results = try await mock.addressLookupService.search(query: "la chitarra")
            self.results = try await mock.addressLookupService.search(query: "4 rue de la passerelle")
        } catch {
            self.lookupError = error
        }
    }
}

#Preview {
    @Previewable @State var show = false
    NavigationStack {
        VStack {
//            Button {
//                show.toggle()
//            } label: {
//                Text("Showw")
//            }
//            
//            Spacer()

            MockLookupPlaceView()
                .ignoresSafeArea()
        }
    }
    .fullScreenCover(isPresented: $show) {
        ZStack {
            Color.red
                //.opacity(0.3)
            Text("Crotteeee")
        }
        .ignoresSafeArea()
        .transition(.opacity)
    }
//    .alert("Jambon", isPresented: $show) {
//        Button("Pioupiou", action: {print("Piou Piou")})
//    }
}

#endif
