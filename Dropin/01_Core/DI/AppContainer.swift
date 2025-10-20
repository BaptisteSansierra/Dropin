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
    
    private let placeRepository: PlaceRepository
    private let tagRepository: TagRepository
    private let groupRepository: GroupRepository
    private let locationManager: LocationManager
    
    init(modelContext: ModelContext, locationManager: LocationManager) {
        placeRepository = PlaceRepositoryImpl(modelContext: modelContext)
        tagRepository = TagRepositoryImpl(modelContext: modelContext)
        groupRepository = GroupRepositoryImpl(modelContext: modelContext)
        self.locationManager = locationManager
    }
    
    func createRootView() -> RootView {
        let vm = RootViewModel(self)
        return RootView(viewModel: vm)
    }
    
    func createMainView() -> MainView {
        let vm = MainViewModel(self,
                               getPlaces: GetPlaces(repository: placeRepository))
        return MainView(viewModel: vm)
    }

    func createPlacesMapView(places: Binding<[PlaceUI]>) -> PlacesMapView {
        let vm = PlacesMapViewModel(self,
                                    getPlaces: GetPlaces(repository: placeRepository),
                                    createPlace: CreatePlace(repository: placeRepository))
        return PlacesMapView(viewModel: vm, places: places)
    }
    
    func createPlacesListView(places: Binding<[PlaceUI]>) -> PlacesListView {
        let vm = PlacesListViewModel(self,
                                     locationManager: locationManager,
                                     getPlaces: GetPlaces(repository: placeRepository),
                                     createPlace: CreatePlace(repository: placeRepository))
        return PlacesListView(viewModel: vm, places: places)
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
    
    func createPlaceDetailsContentView(place: Binding<PlaceUI>,
                                       editMode: Binding<PlaceEditMode>) -> PlaceDetailsContentView {
        let vm = PlaceDetailsContentViewModel(self,
                                              updatePlace: UpdatePlace(repository: placeRepository),
                                              deletePlace: DeletePlace(repository: placeRepository),
                                              getTags: GetTags(repository: tagRepository),
                                              createTags: CreateTag(repository: tagRepository),
                                              getGroups: GetGroups(repository: groupRepository),
                                              createGroup: CreateGroup(repository: groupRepository))
        return PlaceDetailsContentView(viewModel: vm,
                                       place: place,
                                       editMode: editMode)
    }
    
    func createTagListView() -> TagListView {
        let vm = TagListViewModel(self,
                                  getTags: GetTags(repository: tagRepository),
                                  deleteTag: DeleteTag(repository: tagRepository))
        return TagListView(viewModel: vm)
    }
    
    func createTagDetailsView(tag: Binding<TagUI>) -> TagDetailsView {
        let vm = TagDetailsViewModel(self,
                                     updateTag: UpdateTag(repository: tagRepository),
                                     deleteTag: DeleteTag(repository: tagRepository))
        return TagDetailsView(viewModel: vm, tag: tag)
    }

    func createGroupListView() -> GroupListView {
        let vm = GroupListViewModel(self,
                                  getGroups: GetGroups(repository: groupRepository),
                                  deleteGroup: DeleteGroup(repository: groupRepository))
        return GroupListView(viewModel: vm)
    }
    
    func createGroupDetailsView(group: Binding<GroupUI>) -> GroupDetailsView {
        let vm = GroupDetailsViewModel(self,
                                     updateGroup: UpdateGroup(repository: groupRepository),
                                     deleteGroup: DeleteGroup(repository: groupRepository))
        return GroupDetailsView(viewModel: vm, group: group)
    }
}

#if DEBUG

extension AppContainer {
    
    static func insertMockData(modelContext: ModelContext) throws {
        let mockGroups = SDGroup.mockGroups()
        let mockTags = SDTag.mockTags()
        let mockPlaces = SDPlace.mockPlaces()
        for item in mockGroups {
            //print(" GROUP -> \(item.name)")
            modelContext.insert(item)
        }
        for item in mockTags {
            //print(" TAG -> \(item.name)")
            modelContext.insert(item)
        }
        for item in mockPlaces {
            //print(" PLACE -> \(item.name)")
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
}

#endif
