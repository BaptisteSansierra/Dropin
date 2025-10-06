//
//  AppContainer.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/10/25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class AppContainer {
    
    public let placeRepository: PlaceRepository
    private let tagRepository: TagRepository
    private let groupRepository: GroupRepository
#if DEBUG
    private var mockModelContext: ModelContext?
#endif
    
    init(modelContext: ModelContext) {
        placeRepository = PlaceRepositoryImpl(modelContext: modelContext)
        tagRepository = TagRepositoryImpl(modelContext: modelContext)
        groupRepository = GroupRepositoryImpl(modelContext: modelContext)
    }
    
    func createRootView() -> RootView {
        let vm = RootViewModel(self)
        return RootView(viewModel: vm)
    }
    
    func createMainView() -> MainView {
        let vm = MainViewModel(self)
        return MainView(viewModel: vm)
    }

    func createPlacesMapView() -> PlacesMapView {
        let vm = PlacesMapViewModel(self,
                                    getPlaces: GetPlaces(repository: placeRepository),
                                    createPlace: CreatePlace(repository: placeRepository))
        return PlacesMapView(viewModel: vm)
    }
    
    func createCreatePlaceView(place: PlaceEntity) -> CreatePlaceView {
        let vm = CreatePlaceViewModel(self,
                                      place: place,
                                      createPlace: CreatePlace(repository: placeRepository))
        return CreatePlaceView(viewModel: vm)
    }
}

#if DEBUG
extension AppContainer {  // Mock extension
    
    static var mockModelContainer: ModelContainer?
    static private var mockModelContext: ModelContext?
    
    static func mock() -> AppContainer {
        do {
            // Create a mock database
            let schema = Schema([SDPlace.self, SDTag.self, SDGroup.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            mockModelContainer = try ModelContainer(for: SDPlace.self, configurations: modelConfiguration)
            self.mockModelContext = mockModelContainer!.mainContext
            self.mockModelContext!.autosaveEnabled = false
            try insertMockData(modelContext: self.mockModelContext!)
            return AppContainer(modelContext: self.mockModelContext!)
        } catch {
            fatalError("couldn't create mock data \(error)")
        }
    }
    
    static func insertMockData(modelContext: ModelContext) throws {
        print("POPULATING MOCK")
        for item in SDGroup.mockGroups() {
            print(" -> \(item.name)")
            modelContext.insert(item)
        }
        for item in SDTag.mockTags() {
            modelContext.insert(item)
        }
        for item in SDPlace.mockPlaces() {
            modelContext.insert(item)
        }
        try modelContext.save()
    }
    
    static func mockPlaceExample() -> SDPlace {
        return try! mock().mockModelContext!.fetch(FetchDescriptor<SDPlace>()).first!
    }
    
    static func mockTagExample() -> SDPlace {
        return try! mock().mockModelContext!.fetch(FetchDescriptor<SDTag>()).first!
    }
    
    static func mockGroupExample() -> SDPlace {
        return try! mock().mockModelContext!.fetch(FetchDescriptor<SDGroup>()).first!
    }
}
#endif
