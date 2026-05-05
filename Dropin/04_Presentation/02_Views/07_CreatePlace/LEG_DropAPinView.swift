//
//  DropAPinView.swift
//  Dropin
//
//  Created by baptiste sansierra on 6/3/26.
//

#if false
import SwiftUI
import MapKit
//import Combine

struct DropAPinView: View {
    
    // MARK: - States & Bindings
    @State private var viewModel: DropAPinViewModel
    
    // Apple do not allow more than 50 geoloc requests in 60secs
    @State private var limiter = RateLimiter(maxRequests: 50, window: 60)
    
    // MARK: - init
    init(viewModel: DropAPinViewModel) {
        self.viewModel = viewModel
    }
 
    // MARK: - Body
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                mapView
                // Navigation bar background
                navigationBarView(proxy: proxy)
            }
        }
        .navigationTitle(String("Drop a pin"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews
    var mapView: some View {
        GeometryReader { proxy in
            let mapHeight = proxy.size.height - 250
            
            VStack(spacing: 0) {

                ZStack(alignment: .center) {
                    Map(position: $viewModel.camera) {
                        Marker(String("pipo"), coordinate: viewModel.centerPosition)
                    }
                    .onMapCameraChange(frequency: .continuous) { ctx in
                        viewModel.didUpdateCamera(ctx)
                    }
                    .onMapCameraChange(frequency: .onEnd) { ctx in
                        viewModel.didUpdateCamera(ctx)
                        updateAddress()
                        //cameraStream.continuation.yield(ctx.camera.centerCoordinate)
                    }
                    
                    // Zoom buttons
                    HStack {
                        Spacer()
                        VStack(spacing: 0){
                            Spacer()
                            MapIcoButton(systemImage: "plus",
                                         imageFrame: CGSize(width: 15, height: 15),
                                         color: viewModel.cameraDistance < 125 ? .disabled : .dropinPrimary,
                                         action: { viewModel.zoomIn() })
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 15, trailing: 10))
                            MapIcoButton(systemImage: "minus",
                                         imageFrame: CGSize(width: 15, height: 15),
                                         color: viewModel.cameraDistance >= 32_768_000 ? .disabled : .dropinPrimary,
                                         action: { viewModel.zoomOut() })
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 15, trailing: 10))
                        }
                    }
                    
                    // Centered pin
                    /*
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 35, height: 35)
                            .offset(x: 0, y: -19)
                            .opacity(0.5)
                        Circle()
                            .fill(.red)
                            .frame(width: 32, height: 32)
                            .offset(x: 0, y: -19)
                            .opacity(0.5)
                        
                        Image(systemName: "pin")
                            .font(.system(size: 25))
                            .shadow(radius: 4)
                            .offset(x: 0, y: -15)
                    }
                     */
                }
                .frame(height: mapHeight)

                
                
                VStack {
                    HStack {
                        Text("common.address")
                            .textStyle(.formSectionTitle)
                            .padding(.top)
                            .padding(.leading)
                        Spacer()
                    }
                    HStack {
                        Text(viewModel.address)
                            .textStyle(.formSectionTitle2)
                            .padding(.top, 5)
                            .padding(.leading)
                        Spacer()
                    }
                    Spacer()
                }

                Spacer()
                
                MainButton(text: String("Create")) {
                }
                .padding(.bottom)

                
                
            }

        }
                
                /*
                
                 */
//            }
//            .border(.red)
//            .padding(.bottom, 150)

    }
    
    func navigationBarView(proxy: GeometryProxy) -> some View {
        VStack {
            Color.backgroundPrimary
                .frame(height: viewModel.navBarHeight)
                .onChange(of: proxy.frame(in: .global)) { oldValue, newValue in
                    viewModel.navBarHeight = proxy.safeAreaInsets.top
                }
                .onAppear {
                    viewModel.navBarHeight = proxy.safeAreaInsets.top
                }
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - private methods
//    private func updateCamera(_ context : MapCameraUpdateContext) {
//        centerPosition = context.camera.centerCoordinate
////        self.latitude  = String(format: "%.6f", viewModel.centerPosition.latitude)
////        self.longitude = String(format: "%.6f", viewModel.centerPosition.longitude)
//    }
    
    private func updateAddress() {
        Task {
            await limiter.waitIfNeeded()
            do {
                let address = try await LocationManager.lookUpAddress(coords: viewModel.centerPosition)
                viewModel.address = address
            } catch {
                viewModel.address = String(localized: "common.na")
            }
        }
    }
}

#Preview {
    NavigationStack {
        MockContainer().appContainer.createDropAPinView()
    }
}

actor RateLimiter {

    private var timestamps: [Date] = []
    private var maxRequests = 50
    private var window: TimeInterval = 60

    init(maxRequests: Int, window: Double) {
        self.maxRequests = maxRequests
        self.window = window
    }
    
    func waitIfNeeded() async {
        let now = Date()

        // Remove old timestamps
        timestamps.removeAll { now.timeIntervalSince($0) > window }

        if timestamps.count >= maxRequests {
            if let earliest = timestamps.first {
                let delay = window - now.timeIntervalSince(earliest)
                if delay > 0 {
                    Log.debug("Sleep for \(delay)")
                    try? await Task.sleep(for: .seconds(delay))
                }
            }
        }

        timestamps.append(Date())
    }
}

#endif
