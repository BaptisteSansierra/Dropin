////
////  MockAppContainer.swift
////  Dropin
////
////  Created by baptiste sansierra on 3/10/25.
////
//
//import Foundation
//import SwiftData
//
//#if DEBUG
//@MainActor
//final class MockAppContainer: AppContainerProtocol {
//    
//    private let placeRepository: PlaceRepository
//    private let tagRepository: TagRepository
//    private let groupRepository: GroupRepository
//    
//    init() {
//        do {
//            let schema = Schema([SDPlace.self, SDTag.self, SDGroup.self])
//            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
//            let container = try ModelContainer(for: SDPlace.self, configurations: modelConfiguration)
//
//            placeRepository = PlaceRepositoryImpl(modelContext: container.mainContext)
//            tagRepository = TagRepositoryImpl(modelContext: container.mainContext)
//            groupRepository = GroupRepositoryImpl(modelContext: container.mainContext)
//        } catch {
//            fatalError("couldn't create model container")
//        }
//        for l in SDPlace.all {
//            container.mainContext.insert(l)
//        }
//    }
//    
//
//    
//    func createRootView() -> RootView {
//        let vm = RootViewModel(self)
//        return RootView(viewModel: vm)
//    }
//    
//    func createMainView() -> MainView {
//        let vm = MainViewModel(self)
//        return MainView(viewModel: vm)
//    }
//
//    func createPlacesMapView() -> PlacesMapView {
//        let vm = PlacesMapViewModel(self,
//                                    getPlaces: GetPlaces(repository: placeRepository),
//                                    createPlace: CreatePlace(repository: placeRepository))
//        return PlacesMapView(viewModel: vm)
//    }
//}
//#endif
