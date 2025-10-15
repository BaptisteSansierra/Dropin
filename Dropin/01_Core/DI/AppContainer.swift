//
//  AppContainer.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/10/25.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

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
    
    func createCreatePlaceView(place: PlaceUI) -> CreatePlaceView {
        let vm = CreatePlaceViewModel(self,
                                      createPlace: CreatePlace(repository: placeRepository))
        return CreatePlaceView(viewModel: vm, place: place)
    }
    
    func createTagSelectorView(place: Binding<PlaceUI>) -> TagSelectorView {
        let vm = TagSelectorViewModel(self,
                                      getTags: GetTags(repository: tagRepository),
                                      createTags: CreateTag(repository: tagRepository))
        return TagSelectorView(viewModel: vm, place: place)
    }
    
    func createGroupSelectorView(place: Binding<PlaceUI>) -> GroupSelectorView {
        let vm = GroupSelectorViewModel(self,
                                        getGroups: GetGroups(repository: groupRepository),
                                        createGroup: CreateGroup(repository: groupRepository))
        return GroupSelectorView(viewModel: vm, place: place)
    }
    
    func createPlaceDetailsSheetView(place: Binding<PlaceUI>) -> PlaceDetailsSheetView {
        let vm = PlaceDetailsSheetViewModel(self,
                                            updatePlace: UpdatePlace(repository: placeRepository),
                                            deletePlace: DeletePlace(repository: placeRepository),
                                            getTags: GetTags(repository: tagRepository),
                                            createTags: CreateTag(repository: tagRepository),
                                            getGroups: GetGroups(repository: groupRepository),
                                            createGroup: CreateGroup(repository: groupRepository))
        return PlaceDetailsSheetView(viewModel: vm, place: place)
    }

    func createPlaceDetailsView(place: Binding<PlaceUI>, editMode: PlaceEditMode) -> PlaceDetailsView {
        let vm = PlaceDetailsViewModel(self,
                                       updatePlace: UpdatePlace(repository: placeRepository),
                                       deletePlace: DeletePlace(repository: placeRepository),
                                       getTags: GetTags(repository: tagRepository),
                                       createTags: CreateTag(repository: tagRepository),
                                       getGroups: GetGroups(repository: groupRepository),
                                       createGroup: CreateGroup(repository: groupRepository))
        return PlaceDetailsView(viewModel: vm, place: place, editMode: editMode)
    }
    
    func createPlaceDetailsContentView(place: Binding<PlaceUI>, editMode: Binding<PlaceEditMode>) -> PlaceDetailsContentView {
        let vm = PlaceDetailsContentViewModel(self,
                                              updatePlace: UpdatePlace(repository: placeRepository),
                                              deletePlace: DeletePlace(repository: placeRepository),
                                              getTags: GetTags(repository: tagRepository),
                                              createTags: CreateTag(repository: tagRepository),
                                              getGroups: GetGroups(repository: groupRepository),
                                              createGroup: CreateGroup(repository: groupRepository))
        return PlaceDetailsContentView(viewModel: vm, place: place, editMode: editMode)
    }
}

#if DEBUG
extension AppContainer {  // Mock extension
    
    static var mockModelContainer: ModelContainer?
    static private var mockModelContext: ModelContext?
    static private var mockAppContainer: AppContainer?

    static func mock() -> AppContainer {
        if let mockAppContainer = mockAppContainer {
            return mockAppContainer
        }
        do {
            // Create a mock database
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            mockModelContainer = try ModelContainer(for: SDPlace.self, SDTag.self, SDGroup.self,
                                                    configurations: modelConfiguration)
            mockModelContext = mockModelContainer!.mainContext
            mockModelContext!.autosaveEnabled = false
            try insertMockData(modelContext: mockModelContext!)
            mockAppContainer = AppContainer(modelContext: mockModelContext!)
            return mockAppContainer!
        } catch {
            fatalError("couldn't create mock data \(error)")
        }
    }
    
    static func insertMockData(modelContext: ModelContext) throws {
        print("POPULATING MOCK")
        let mockGroups = SDGroup.mockGroups()
        let mockTags = SDTag.mockTags()
        let mockPlaces = SDPlace.mockPlaces()
        for item in mockGroups {
            print(" GROUP -> \(item.name)")
            modelContext.insert(item)
        }
        for item in mockTags {
            print(" TAG -> \(item.name)")
            modelContext.insert(item)
        }
        for item in mockPlaces {
            print(" PLACE -> \(item.name)")
            modelContext.insert(item)
        }
        
        mockPlaces[0].group = mockGroups[0]
        mockPlaces[0].tags = [mockTags[8], mockTags[10], mockTags[13]]

        mockPlaces[1].group = mockGroups[0]
        mockPlaces[1].tags = [mockTags[8], mockTags[9], mockTags[13]]

        mockPlaces[2].group = mockGroups[4]
        mockPlaces[2].tags = [mockTags[6], mockTags[7]]

        mockPlaces[3].group = mockGroups[5]
        mockPlaces[3].tags = [mockTags[1]]

        mockPlaces[4].group = mockGroups[5]
        mockPlaces[4].tags = [mockTags[1]]

        mockPlaces[5].group = mockGroups[5]
        mockPlaces[5].tags = [mockTags[11], mockTags[12]]

        mockPlaces[6].group = mockGroups[7]
        mockPlaces[6].tags = [mockTags[9], mockTags[12]]

        mockPlaces[7].group = mockGroups[8]
        mockPlaces[7].tags = [mockTags[9]]

        mockPlaces[6].group = mockGroups[8]
        mockPlaces[6].tags = [mockTags[12], mockTags[14], mockTags[15]]

        try modelContext.save()
    }
    
    static func mockPlaceExample() -> SDPlace {
        do {
            guard let mockModelContext = mock().mockModelContext else {
                print("error getting mock context")
                return SDPlace(identifier: "...", name: "null", latitude: 0, longitude: 0, address: "N/A")
            }
            let places = try mockModelContext.fetch(FetchDescriptor<SDPlace>())
            print("\(places.count) mock places found")
            return places.first!
        } catch {
            print("error getting mock place \(error)")
            return SDPlace(identifier: "...", name: "null", latitude: 0, longitude: 0, address: "N/A")
        }
    }

    static func mockDomainPlaceExample() -> PlaceEntity {
        return PlaceMapper.toDomain(mockPlaceExample())
    }

    static func mockTagExample() -> SDTag {
        return try! mock().mockModelContext!.fetch(FetchDescriptor<SDTag>()).first!
    }
    
    static func mockGroupExample() -> SDGroup {
        return try! mock().mockModelContext!.fetch(FetchDescriptor<SDGroup>()).first!
    }
}
#endif
