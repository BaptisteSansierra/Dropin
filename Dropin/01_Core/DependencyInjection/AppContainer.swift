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
    private let imageRepository: ImageRepository
    private let profileRepository: ProfileRepository
    private let imageLoader: ImageLoader
    // Coordinators
    private let mainCoordinator: MainCoordinator
    private let tagCoordinator: TagCoordinator
    private let groupCoordinator: GroupCoordinator
    // Services
    private let locationManager: LocationManager
    private let addressLookupService: AddressLookupService
    private let reachabilityService: ReachabilityService
    private let supabaseService: SupabaseService?
    let authService: any AuthServiceProtocol
    let profileService: any ProfileServiceProtocol
    private let syncService: any SyncServiceProtocol & SyncServicePausableProtocol

    init(modelContext: ModelContext) {
        // Coordinators
        mainCoordinator = MainCoordinator()
        tagCoordinator = TagCoordinator()
        groupCoordinator = GroupCoordinator()
        // Services
        locationManager = LocationManager()
        addressLookupService = AddressLookupService(locationManager: locationManager)
        reachabilityService = ReachabilityService()
        // Supabase + auth
        let supabaseService = SupabaseService()
        let authService = AuthService(client: supabaseService.client)
        self.supabaseService = supabaseService
        self.authService = authService
        // Local repos (raw — used by SyncService for push)
        let localPlaceRepo = PlaceRepositoryImpl(modelContext: modelContext)
        let localGroupRepo = GroupRepositoryImpl(modelContext: modelContext)
        let localTagRepo = TagRepositoryImpl(modelContext: modelContext)
        let localImageRepo = ImageRepositoryImpl(modelContext: modelContext)
        let localProfileRepo = ProfileRepositoryImpl(modelContext: modelContext)
        // Remote repos
        let remotePlaceRepo = SupabasePlaceRepository(client: supabaseService.client, auth: authService)
        let remoteGroupRepo = SupabaseGroupRepository(client: supabaseService.client, auth: authService)
        let remoteTagRepo = SupabaseTagRepository(client: supabaseService.client, auth: authService)
        let remoteImageRepo = SupabaseImageRepository(client: supabaseService.client, auth: authService)
        let remoteProfileRepo = SupabaseProfileRepository(client: supabaseService.client, auth: authService)
        // Sync
        let syncService = SyncService(localPlaceRepo: localPlaceRepo,
                                      localGroupRepo: localGroupRepo,
                                      localTagRepo: localTagRepo,
                                      localImageRepo: localImageRepo,
                                      localProfileRepo: localProfileRepo,
                                      remotePlaceRepo: remotePlaceRepo,
                                      remoteGroupRepo: remoteGroupRepo,
                                      remoteTagRepo: remoteTagRepo,
                                      remoteImageRepo: remoteImageRepo,
                                      remoteProfileRepo: remoteProfileRepo,
                                      reachability: reachabilityService)
        self.syncService = syncService
        // Wrap local repos so mutations notify SyncService
        placeRepository = SyncingPlaceRepository(wrapped: localPlaceRepo, sync: syncService)
        groupRepository = SyncingGroupRepository(wrapped: localGroupRepo, sync: syncService)
        tagRepository = SyncingTagRepository(wrapped: localTagRepo, sync: syncService)
        imageRepository = SyncingImageRepository(wrapped: localImageRepo, sync: syncService)
        profileRepository = SyncingProfileRepository(wrapped: localProfileRepo, sync: syncService)
        imageLoader = ImageLoader(local: imageRepository, remote: remoteImageRepo)
        profileService = ProfileService(local: profileRepository, remote: remoteProfileRepo)
    }

    #if DEBUG
    /// Used by mock container (previews + tests). Skips real Supabase wiring.
    init(modelContext: ModelContext,
         locationManager: LocationManager,
         addressLookupService: AddressLookupService,
         reachabilityService: ReachabilityService) {
        // Coordinators
        mainCoordinator = MainCoordinator()
        tagCoordinator = TagCoordinator()
        groupCoordinator = GroupCoordinator()
        // Services
        self.locationManager = locationManager
        self.addressLookupService = addressLookupService
        self.reachabilityService = reachabilityService
        // Stub auth + sync
        self.supabaseService = nil
        let authService = StubAuthService()
        let syncService = StubSyncService()
        self.authService = authService
        self.syncService = syncService
        // Repos — no syncing wrapper needed (stub would no-op anyway)
        placeRepository = PlaceRepositoryImpl(modelContext: modelContext)
        tagRepository = TagRepositoryImpl(modelContext: modelContext)
        groupRepository = GroupRepositoryImpl(modelContext: modelContext)
        imageRepository = ImageRepositoryImpl(modelContext: modelContext)
        profileRepository = ProfileRepositoryImpl(modelContext: modelContext)
        imageLoader = ImageLoader(local: imageRepository, remote: StubRemoteImageRepository())
        profileService = StubProfileService()
    }
    #endif

    func startLocationManager() {
        locationManager.start()
    }

    func syncAll() async {
        await syncService.syncAll()
    }

    func restoreSession() async {
        await authService.restoreSession()
    }

    // MARK: - create views
    func createRootView() -> RootView {
        let vm = RootViewModel(self)
        return RootView(viewModel: vm)
    }
    
    func createMainView(showingSideMenu: Binding<Bool>) -> MainView {
        let vm = MainViewModel(self,
                               coordinator: mainCoordinator,
                               locationManager: locationManager,
                               fetchPlaces: FetchPlaces(repository: placeRepository),
                               syncStatus: syncService.syncStatus)
        return MainView(viewModel: vm, showingSideMenu: showingSideMenu)
    }

    func createPlacesMapView(places: [PlaceUI],
                             selectedPlaceId: Binding<UUID?>,
                             isParentPresenting: Binding<Bool>,
                             showingCreatePlaceMenu: Binding<Bool>,
                             mapReloadGen: Int,
                             navBarHeight: CGFloat) -> PlacesMapView {
        let vm = PlacesMapViewModel(self,
                                    coordinator: mainCoordinator,
                                    locationManager: locationManager)
        return PlacesMapView(viewModel: vm,
                             places: places,
                             selectedPlaceId: selectedPlaceId,
                             isParentPresenting: isParentPresenting,
                             showingCreatePlaceMenu: showingCreatePlaceMenu,
                             mapReloadGen: mapReloadGen,
                             navBarHeight: navBarHeight)
    }
    
    func createPlacesListView(places: [PlaceUI],
                              selectedPlaceId: Binding<UUID?>) -> PlacesListView {
        let vm = PlacesListViewModel(self,
                                     coordinator: mainCoordinator,
                                     locationManager: locationManager)
        return PlacesListView(viewModel: vm, places: places, selectedPlaceId: selectedPlaceId)
    }
    
    func createPlaceCreateQuickView(place: PlaceUI) -> PlaceCreateQuickView {
        let vm = PlaceCreateQuickViewModel(self,
                                           coordinator: mainCoordinator,
                                           createPlace: CreatePlace(repository: placeRepository))
        return PlaceCreateQuickView(viewModel: vm, place: place)
    }
    
    func createTagSelectorView(place: Binding<PlaceUI>) -> TagSelectorView {
        let vm = TagSelectorViewModel(self,
                                      fetchTags: FetchTags(repository: tagRepository),
                                      createTags: CreateTag(repository: tagRepository))
        return TagSelectorView(viewModel: vm, place: place)
    }
    
    func createGroupSelectorView(place: Binding<PlaceUI>) -> GroupSelectorView {
        let vm = GroupSelectorViewModel(self,
                                        fetchGroups: FetchGroups(repository: groupRepository),
                                        createGroup: CreateGroup(repository: groupRepository))
        return GroupSelectorView(viewModel: vm, place: place)
    }

    func createPlaceSheetView(place: Binding<PlaceUI>, detent: Binding<PresentationDetent>) -> PlaceSheetView {
        let vm = PlaceSheetViewModel(self,
                                     coordinator: mainCoordinator,
                                     locationManager: locationManager,
                                     getPlaceThumbnails: GetPlaceThumbnails(loader: imageLoader),
                                     getPlaceImage: GetPlaceImage(loader: imageLoader))
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
                                           getPlaceThumbnails: GetPlaceThumbnails(loader: imageLoader),
                                           getPlaceImage: GetPlaceImage(loader: imageLoader),
                                           mode: mode)
        return PlaceEditContentView(viewModel: vm, place: place, showMissingName: showMissingName)
    }

    func createPlaceEditView(place: Binding<PlaceUI>) -> PlaceEditView {
        let vm = PlaceEditViewModel(self,
                                    coordinator: mainCoordinator,
                                    updatePlace: UpdatePlace(repository: placeRepository),
                                    addPlaceImage: AddPlaceImage(repository: imageRepository),
                                    removePlaceImage: RemovePlaceImage(repository: imageRepository))
        return PlaceEditView(viewModel: vm, place: place)
    }

    func createPlaceCreateView(coordinates: CLLocationCoordinate2D,
                               address: String,
                               name: String,
                               marker: String?,
                               tags: [UUID],
                               group: UUID?) -> PlaceCreateView {
        let vm = PlaceCreateViewModel(self,
                                      coordinator: mainCoordinator,
                                      createPlace: CreatePlace(repository: placeRepository),
                                      getTag: FetchTag(repository: tagRepository),
                                      getGroup: FetchGroup(repository: groupRepository),
                                      addPlaceImage: AddPlaceImage(repository: imageRepository))
        return PlaceCreateView(viewModel: vm,
                               coordinates: coordinates,
                               address: address,
                               name: name,
                               marker: marker,
                               tags: tags,
                               group: group)
    }
    
    func createTagListView(showingSideMenu: Binding<Bool>) -> TagListView {
        let vm = TagListViewModel(self,
                                  coordinator: tagCoordinator,
                                  fetchTagsWithCount: FetchTagsWithCount(repository: tagRepository),
                                  deleteTag: DeleteTag(repository: tagRepository),
                                  syncStatus: syncService.syncStatus)
        return TagListView(viewModel: vm, showingSideMenu: showingSideMenu)
    }
    
    func createTagDetailsView(tag: Binding<TagUI>) -> TagDetailsView {
        let vm = TagDetailsViewModel(self,
                                     locationManager: locationManager,
                                     updateTag: UpdateTag(repository: tagRepository),
                                     deleteTag: DeleteTag(repository: tagRepository),
                                     fetchTagPlaces: FetchTagPlaces(repository: placeRepository),
                                     updatePlace: UpdatePlace(repository: placeRepository))
        return TagDetailsView(viewModel: vm, tag: tag)
    }

    func createGroupListView(showingSideMenu: Binding<Bool>) -> GroupListView {
        let vm = GroupListViewModel(self,
                                    coordinator: groupCoordinator,
                                    fetchGroupsWithCount: FetchGroupsWithCount(repository: groupRepository),
                                    deleteGroup: DeleteGroup(repository: groupRepository),
                                    syncStatus: syncService.syncStatus)
        return GroupListView(viewModel: vm, showingSideMenu: showingSideMenu)
    }
    
    func createGroupDetailsView(group: Binding<GroupUI>) -> GroupDetailsView {
        let vm = GroupDetailsViewModel(self,
                                       locationManager: locationManager,
                                       updateGroup: UpdateGroup(repository: groupRepository),
                                       deleteGroup: DeleteGroup(repository: groupRepository),
                                       fetchGroupPlaces: FetchGroupPlaces(repository: placeRepository),
                                       updatePlace: UpdatePlace(repository: placeRepository))
        return GroupDetailsView(viewModel: vm, group: group)
    }
    
    func createLookupPlacesView() -> LookupPlacesView {
        let vm = LookupPlacesViewModel(self,
                                       coordinator: mainCoordinator,
                                       addressLookupService: addressLookupService,
                                       locationManager: locationManager,
                                       reachabilityService: reachabilityService,
                                       updatePlace: UpdatePlace(repository: placeRepository))
        return LookupPlacesView(viewModel: vm)
    }

    func createLookupPlacesView(place: Binding<PlaceUI>) -> LookupPlacesView {
        let vm = LookupPlacesViewModel(self,
                                       coordinator: mainCoordinator,
                                       addressLookupService: addressLookupService,
                                       locationManager: locationManager,
                                       reachabilityService: reachabilityService,
                                       updatePlace: UpdatePlace(repository: placeRepository))
        return LookupPlacesView(viewModel: vm, place: place)
    }

    func createLookupPlaceView(lookupResolvedItem: LookupResolvedItem,
                               place: Binding<PlaceUI?> = .constant(nil),
                               status: Binding<LookupPlaceView.PresentationStatus>) -> LookupPlaceView {
        let vm = LookupPlaceViewModel(self,
                                      coordinator: mainCoordinator,
                                      createPlace: CreatePlace(repository: placeRepository),
                                      lookupResolvedItem: lookupResolvedItem)
        return LookupPlaceView(viewModel: vm, place: place, status: status)
    }

    #if false
    func createDropAPinView() -> DropAPinView {
        let vm = DropAPinViewModel(self,
                                   coordinator: mainCoordinator,
                                   locationManager: locationManager,
                                   createPlace: CreatePlace(repository: placeRepository))
        return DropAPinView(viewModel: vm)
    }
    #endif
    
    func createPlaceFilterView(filter: Binding<PlaceFilter?>) -> PlaceFilterView {
        let vm = PlaceFilterViewModel(self,
                                      fetchGroups: FetchGroups(repository: groupRepository),
                                      fetchTags: FetchTags(repository: tagRepository),
                                      filter: filter)
        return PlaceFilterView(viewModel: vm)
    }
    
    
    // MARK: - settings views
    func createSettingsView(showingSideMenu: Binding<Bool>) -> SettingsView {
        let vm = SettingsViewModel(self,
                                   coordinator: mainCoordinator,
                                   fetchPlaces: FetchPlaces(repository: placeRepository),
                                   fetchGroups: FetchGroups(repository: groupRepository),
                                   fetchTags: FetchTags(repository: tagRepository),
                                   upsertPlace: UpsertPlace(repository: placeRepository),
                                   upsertGroup: UpsertGroup(repository: groupRepository),
                                   upsertTag: UpsertTag(repository: tagRepository),
                                   deleteLibrary: DeleteLibrary(placeRepository: placeRepository,
                                                                groupRepository: groupRepository,
                                                                tagRepository: tagRepository),
                                   sync: syncService)
        return SettingsView(viewModel: vm, showingSideMenu: showingSideMenu)
    }

}

#if DEBUG

extension AppContainer {
    
    static func insertMockData(modelContext: ModelContext) throws {
        let mockGroups = SDGroup.mockGroups()
        let mockTags = SDTag.mockTags()
        let mockPlaces = SDPlace.mockPlaces()
        for item in mockGroups {
            modelContext.insert(item)
        }
        for item in mockTags {
            modelContext.insert(item)
        }
        for item in mockPlaces {
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
