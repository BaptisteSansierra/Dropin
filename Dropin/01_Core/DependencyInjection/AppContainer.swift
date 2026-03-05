//
//  AppContainer.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/10/25.
//

import Foundation
import SwiftData
import SwiftUI
import MapKit

@MainActor
final class AppContainer {
    
    // Repositories
    private let placeRepository: PlaceRepository
    private let tagRepository: TagRepository
    private let groupRepository: GroupRepository
    // Coordinators
    private let mainCoordinator: MainCoordinator
    private let tagCoordinator: TagCoordinator
    private let groupCoordinator: GroupCoordinator
    // Services
    private let locationManager: LocationManager
    private let addressLookupService: AddressLookupService
    private let reachabilityService: ReachabilityService

    init(modelContext: ModelContext) {
        // Repos
        placeRepository = PlaceRepositoryImpl(modelContext: modelContext)
        tagRepository = TagRepositoryImpl(modelContext: modelContext)
        groupRepository = GroupRepositoryImpl(modelContext: modelContext)
        // Coordinators
        mainCoordinator = MainCoordinator()
        tagCoordinator = TagCoordinator()
        groupCoordinator = GroupCoordinator()
        // Services
        locationManager = LocationManager()
        addressLookupService = AddressLookupService(locationManager: locationManager)
        reachabilityService = ReachabilityService()
    }
    
    /// Used by mock container which owns the services for convenience purpose
    init(modelContext: ModelContext,
         locationManager: LocationManager,
         addressLookupService: AddressLookupService,
         reachabilityService: ReachabilityService) {
        // Repos
        placeRepository = PlaceRepositoryImpl(modelContext: modelContext)
        tagRepository = TagRepositoryImpl(modelContext: modelContext)
        groupRepository = GroupRepositoryImpl(modelContext: modelContext)
        // Coordinators
        mainCoordinator = MainCoordinator()
        tagCoordinator = TagCoordinator()
        groupCoordinator = GroupCoordinator()
        // Services
        self.locationManager = locationManager
        self.addressLookupService = addressLookupService
        self.reachabilityService = reachabilityService
    }
    
    func startLocationManager() {
        locationManager.start()
    }

    // MARK: - create views
    func createRootView() -> RootView {
        let vm = RootViewModel(self)
        return RootView(viewModel: vm)
    }
    
    func createMainView(showingSideMenu: Binding<Bool>) -> MainView {
        let vm = MainViewModel(self,
                               coordinator: mainCoordinator,
                               getPlaces: GetPlaces(repository: placeRepository))
        return MainView(viewModel: vm, showingSideMenu: showingSideMenu)
    }

    func createPlacesMapView(places: Binding<[PlaceUI]>, showingCreatePlaceMenu: Binding<Bool>) -> PlacesMapView {
        let vm = PlacesMapViewModel(self,
                                    coordinator: mainCoordinator,
                                    locationManager: locationManager,
                                    getPlaces: GetPlaces(repository: placeRepository),
                                    createPlace: CreatePlace(repository: placeRepository))
        return PlacesMapView(viewModel: vm,
                             places: places,
                             showingCreatePlaceMenu: showingCreatePlaceMenu)
    }
    
    func createPlacesListView(places: Binding<[PlaceUI]>) -> PlacesListView {
        let vm = PlacesListViewModel(self,
                                     coordinator: mainCoordinator,
                                     locationManager: locationManager,
                                     getPlaces: GetPlaces(repository: placeRepository),
                                     createPlace: CreatePlace(repository: placeRepository))
        return PlacesListView(viewModel: vm, places: places)
    }
    
//    func createCreatePlaceView(place: PlaceUI) -> CreatePlaceView {
//        let vm = CreatePlaceViewModel(self,
//                                      createPlace: CreatePlace(repository: placeRepository))
//        return CreatePlaceView(viewModel: vm, place: place)
//    }

    func createCreatePlaceQuickView(place: PlaceUI) -> CreatePlaceQuickView {
        let vm = CreatePlaceQuickViewModel(self,
                                           coordinator: mainCoordinator,
                                           createPlace: CreatePlace(repository: placeRepository))
        return CreatePlaceQuickView(viewModel: vm, place: place)
    }

/*
    func createCreatePlaceFullView(coordinates: CLLocationCoordinate2D,
                                   address: String,
                                   name: String,
                                   marker: String?,
                                   tags: [String],
                                   group: String?) -> CreatePlaceFullView {
        let vm = CreatePlaceFullViewModel(self,
                                          coordinator: mainCoordinator,
                                          createPlace: CreatePlace(repository: placeRepository),
                                          getTag: GetTag(repository: tagRepository),
                                          getGroup: GetGroup(repository: groupRepository))
        return CreatePlaceFullView(viewModel: vm,
                                   coordinates: coordinates,
                                   address: address,
                                   name: name,
                                   marker: marker,
                                   tags: tags,
                                   group: group)
    }
*/
    
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
    
    /*
    func createPlaceDetailsSheetView(place: Binding<PlaceUI>) -> PlaceDetailsSheetView {
        let vm = PlaceDetailsSheetViewModel(self,
                                            coordinator: mainCoordinator,
                                            updatePlace: UpdatePlace(repository: placeRepository),
                                            deletePlace: DeletePlace(repository: placeRepository),
                                            getTags: GetTags(repository: tagRepository),
                                            createTags: CreateTag(repository: tagRepository),
                                            getGroups: GetGroups(repository: groupRepository),
                                            createGroup: CreateGroup(repository: groupRepository))
        return PlaceDetailsSheetView(viewModel: vm,
                                     place: place)
    }
     */

    func createPlaceSheetView(place: Binding<PlaceUI>, detent: Binding<PresentationDetent>) -> PlaceSheetView {
        let vm = PlaceSheetViewModel(self,
                                     coordinator: mainCoordinator,
                                     locationManager: locationManager)
        return PlaceSheetView(viewModel: vm,
                              place: place,
                              detent: detent)
    }

    func createPlaceEditContentView(place: Binding<PlaceUI>,
                                    mode: PlaceEditContentViewModel.Mode,
                                    showMissingName: Binding<Bool>) -> PlaceEditContentView {
        let vm = PlaceEditContentViewModel(self,
                                           coordinator: mainCoordinator,
                                           updatePlace: UpdatePlace(repository: placeRepository),
                                           deletePlace: DeletePlace(repository: placeRepository),
                                           mode: mode)
        return PlaceEditContentView(viewModel: vm, place: place, showMissingName: showMissingName)
    }

    func createPlaceEditView(place: Binding<PlaceUI>) -> PlaceEditView {
        let vm = PlaceEditViewModel(self,
                                    coordinator: mainCoordinator,
                                    updatePlace: UpdatePlace(repository: placeRepository))
        return PlaceEditView(viewModel: vm, place: place)
    }

    func createPlaceCreateView(coordinates: CLLocationCoordinate2D,
                               address: String,
                               name: String,
                               marker: String?,
                               tags: [String],
                               group: String?) -> PlaceCreateView {
        let vm = PlaceCreateViewModel(self,
                                      coordinator: mainCoordinator,
                                      createPlace: CreatePlace(repository: placeRepository),
                                      getTag: GetTag(repository: tagRepository),
                                      getGroup: GetGroup(repository: groupRepository))
        return PlaceCreateView(viewModel: vm,
                               coordinates: coordinates,
                               address: address,
                               name: name,
                               marker: marker,
                               tags: tags,
                               group: group)
    }
    
    

    /*
    func createPlaceDetailsView(place: Binding<PlaceUI>, editMode: PlaceEditMode) -> PlaceDetailsView {
        let vm = PlaceDetailsViewModel(self,
                                       coordinator: mainCoordinator,
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
     */
    
    func createTagListView(showingSideMenu: Binding<Bool>) -> TagListView {
        let vm = TagListViewModel(self,
                                  coordinator: tagCoordinator,
                                  getTags: GetTags(repository: tagRepository),
                                  deleteTag: DeleteTag(repository: tagRepository))
        return TagListView(viewModel: vm, showingSideMenu: showingSideMenu)
    }
    
    func createTagDetailsView(tag: Binding<TagUI>) -> TagDetailsView {
        let vm = TagDetailsViewModel(self,
                                     locationManager: locationManager,
                                     updateTag: UpdateTag(repository: tagRepository),
                                     deleteTag: DeleteTag(repository: tagRepository))
        return TagDetailsView(viewModel: vm, tag: tag)
    }

    func createGroupListView(showingSideMenu: Binding<Bool>) -> GroupListView {
        let vm = GroupListViewModel(self,
                                    coordinator: groupCoordinator,
                                    getGroups: GetGroups(repository: groupRepository),
                                    deleteGroup: DeleteGroup(repository: groupRepository))
        return GroupListView(viewModel: vm, showingSideMenu: showingSideMenu)
    }
    
    func createGroupDetailsView(group: Binding<GroupUI>) -> GroupDetailsView {
        let vm = GroupDetailsViewModel(self,
                                       locationManager: locationManager,
                                       updateGroup: UpdateGroup(repository: groupRepository),
                                       deleteGroup: DeleteGroup(repository: groupRepository))
        return GroupDetailsView(viewModel: vm, group: group)
    }
    
    func createLookupPlacesView() -> LookupPlacesView {
        let vm = LookupPlacesViewModel(self,
                                       addressLookupService: addressLookupService,
                                       locationManager: locationManager,
                                       reachabilityService: reachabilityService)
        return LookupPlacesView(viewModel: vm)
    }
    
    func createLookupPlaceView(lookupResolvedItem: LookupResolvedItem,
                               status: Binding<LookupPlaceView.PresentationStatus>) -> LookupPlaceView {
        let vm = LookupPlaceViewModel(self,
                                      coordinator: mainCoordinator,
                                      createPlace: CreatePlace(repository: placeRepository),
                                      lookupResolvedItem: lookupResolvedItem)
        return LookupPlaceView(viewModel: vm, status: status)
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
        
        mockPlaces[0].group = nil // mockGroups[0]
        mockPlaces[0].tags = [mockTags[1], mockTags[2], mockTags[3], mockTags[4],
                              mockTags[5], mockTags[6], mockTags[7], mockTags[8],
                              mockTags[10], mockTags[13], mockTags[12], mockTags[14], mockTags[15]]

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
