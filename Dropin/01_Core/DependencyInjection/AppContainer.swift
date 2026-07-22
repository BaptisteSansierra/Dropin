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

    // App context
    var appContext: AppContext
    // Repositories
    private let placeRepository: PlaceRepository
    private let tagRepository: TagRepository
    private let groupRepository: GroupRepository
    private let imageRepository: ImageRepository
    private let profileRepository: ProfileRepository
    private let imageLoader: ImageLoader
    // Coordinators
    private let profileCoordinator: ProfileCoordinator
    private let placeCoordinator: PlaceCoordinator
    private let tagCoordinator: TagCoordinator
    private let groupCoordinator: GroupCoordinator
    private let authCoordinator: AuthCoordinator
    // Services
    private let locationManager: LocationManager
    private let addressLookupService: AddressLookupService
    private let reachabilityService: ReachabilityService
    private let supabaseService: SupabaseService?
    private let authService: any AuthServiceProtocol
    private let authStatus: AuthStatus
    private let profileService: any ProfileServiceProtocol
    private let syncService: any SyncServiceProtocol & SyncServicePausableProtocol

    /// Narrow auth-state surface for routing (no full `AuthStatus` exposed).
    /// Reading this from a view body registers observation on both
    /// `isRestoring` and `authService.session` because both are `@Observable`.
    var authState: AuthStatus.State { authStatus.state }

    init(modelContext: ModelContext,
         appContext: AppContext) {
        self.appContext = appContext
        // Coordinators
        profileCoordinator = ProfileCoordinator()
        placeCoordinator = PlaceCoordinator()
        tagCoordinator = TagCoordinator()
        groupCoordinator = GroupCoordinator()
        authCoordinator = AuthCoordinator()
        // Services
        locationManager = LocationManager()
        addressLookupService = AddressLookupService(locationManager: locationManager)
        reachabilityService = ReachabilityService()
        // Supabase + auth
        let supabaseService = SupabaseService()
        let authService = AuthService(client: supabaseService.client)
        self.supabaseService = supabaseService
        self.authService = authService
        self.authStatus = AuthStatus(authService: authService)
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
         appContext: AppContext,
         locationManager: LocationManager,
         addressLookupService: AddressLookupService,
         reachabilityService: ReachabilityService,
         profileService: StubProfileService) {
        self.appContext = appContext
        // Coordinators
        profileCoordinator = ProfileCoordinator()
        placeCoordinator = PlaceCoordinator()
        tagCoordinator = TagCoordinator()
        groupCoordinator = GroupCoordinator()
        authCoordinator = AuthCoordinator()
        // Services
        self.locationManager = locationManager
        self.addressLookupService = addressLookupService
        self.reachabilityService = reachabilityService
        // Stub auth + sync
        self.supabaseService = nil
        let authService = StubAuthService()
        let syncService = StubSyncService()
        self.authService = authService
        self.authStatus = AuthStatus(authService: authService)
        self.syncService = syncService
        // Repos — no syncing wrapper needed (stub would no-op anyway)
        placeRepository = PlaceRepositoryImpl(modelContext: modelContext)
        tagRepository = TagRepositoryImpl(modelContext: modelContext)
        groupRepository = GroupRepositoryImpl(modelContext: modelContext)
        imageRepository = ImageRepositoryImpl(modelContext: modelContext)
        profileRepository = ProfileRepositoryImpl(modelContext: modelContext)
        imageLoader = ImageLoader(local: imageRepository, remote: StubRemoteImageRepository())
        self.profileService = profileService
    }
    #endif

    func startLocationManager() {
        locationManager.start()
    }

    func syncAll() async {
        await syncService.syncAll()
    }

    func loadProfile() async {
        await profileService.load()
    }

    func restoreSession() async {
        authStatus.isRestoring = true
        await authService.restoreSession()
        authStatus.isRestoring = false
    }

    // MARK: - sign-out

    enum SignOutError: Error, Equatable {
        case offlineWithPendingChanges(count: Int)
        case syncFailedWithPendingChanges(count: Int)
    }

    /// Signs the user out and wipes local data.
    /// - If `force == false` and there are pending changes:
    ///   - online → attempts a sync first; if it leaves changes pending, throws
    ///     `.syncFailedWithPendingChanges`.
    ///   - offline → throws `.offlineWithPendingChanges`.
    /// - If `force == true`, skips the sync check entirely. Use after the user
    ///   has accepted that unsynced changes will be lost.
    ///
    /// Cleanup order (intentional): try sync → in-memory caches → local data
    /// → session. The session flip is last so the UI only switches to the sign-in flow
    /// once everything else is clean.
    func signOut(force: Bool = false, didStartClearingSession: (() -> Void)) async throws {
        Log.debug("Signout (forced:\(force)")
        if !force {
            // User chose not to force, cancel the signout if there's some pending sync actions
            let pending = syncService.pendingChangeCount
            if pending > 0 {
                Log.debug(" -> \(pending) pending syncs")
                guard reachabilityService.isConnected else {
                    Log.debug(" -> Throw error offline with pending changes")
                    throw SignOutError.offlineWithPendingChanges(count: pending)
                }
                await syncService.syncAll()
                let stillPending = syncService.pendingChangeCount
                if stillPending > 0 {
                    Log.debug(" -> Throw error failed with pending changes")
                    throw SignOutError.syncFailedWithPendingChanges(count: stillPending)
                }
            } else {
                Log.debug(" -> no pending sync")
            }
        }
        didStartClearingSession()
        // Enable loader
        authStatus.isSigningOut = true

        // 1. In-memory caches
        profileService.clear()
        // 2. Navigation state (reset coordinators + side menu)
        profileCoordinator.popToRoot()
        placeCoordinator.popToRoot()
        tagCoordinator.path.removeAll()
        groupCoordinator.path.removeAll()
        appContext.currentSideMenuContext = .main
        // 3. Local data
        try await clearDatabase()
        syncService.reset()
        // 4. Session — last; AuthStatus flips → root switches to the sign-in flow
        try await authService.signOut()
        
        authStatus.isSigningOut = false
    }

    // MARK: - delete account

    /// Deletes the remote account first; local cleanup (mirroring `signOut`)
    /// only happens once that has actually succeeded, so a failure leaves the
    /// user's local data untouched.
    func deleteAccount() async throws {
        Log.debug("Delete account requested")
        try await authService.deleteAccount()

        authStatus.isSigningOut = true
        profileService.clear()
        profileCoordinator.popToRoot()
        placeCoordinator.popToRoot()
        tagCoordinator.path.removeAll()
        groupCoordinator.path.removeAll()
        appContext.currentSideMenuContext = .main
        try await clearDatabase()
        syncService.reset()
        try await authService.signOut()
        authStatus.isSigningOut = false
    }

    // MARK: - create views
    func createSignInView() -> SignInView {
        let vm = SignInViewModel(appContainer: self, authService: authService, coordinator: authCoordinator)
        return SignInView(viewModel: vm)
    }

    func createSignUpView() -> SignUpView {
        let vm = SignUpViewModel(authService: authService, coordinator: authCoordinator)
        return SignUpView(viewModel: vm)
    }

    func createResetPasswordView() -> ResetPasswordView {
        let vm = ResetPasswordViewModel(authService: authService, coordinator: authCoordinator)
        return ResetPasswordView(viewModel: vm)
    }

    func createVerifyEmailView(email: String, password: String, context: VerifyEmailContext) -> VerifyEmailView {
        let vm = VerifyEmailViewModel(email: email, password: password, context: context, authService: authService, coordinator: authCoordinator)
        return VerifyEmailView(viewModel: vm)
    }

    func createProfileView() -> ProfileView {
        let vm = ProfileViewModel(appContainer: self,
                                  profileService: profileService,
                                  coordinator: profileCoordinator)
        return ProfileView(viewModel: vm)
    }

    func createEditDisplayNameView() -> EditDisplayNameView {
        let vm = EditDisplayNameViewModel(profileService: profileService, coordinator: profileCoordinator)
        return EditDisplayNameView(viewModel: vm)
    }

    func createDeleteAccountView() -> DeleteAccountView {
        let vm = DeleteAccountViewModel(appContainer: self,
                                        coordinator: profileCoordinator,
                                        fetchPlaces: FetchPlaces(repository: placeRepository),
                                        fetchGroups: FetchGroups(repository: groupRepository),
                                        fetchTags: FetchTags(repository: tagRepository),
                                        imageRepository: imageRepository)
        return DeleteAccountView(viewModel: vm)
    }

    func createSideMenuView(showingSideMenu: Binding<Bool>,
                            currentSideMenuContext: Binding<SideMenuContext>,
                            showingProfile: Binding<Bool>) -> SideMenuView {
        let vm = SideMenuViewModel(profileService: profileService,
                                   showingProfile: showingProfile)
        return SideMenuView(viewModel: vm,
                            showingSideMenu: showingSideMenu,
                            currentSideMenuContext: currentSideMenuContext)
    }

    func createRootView() -> RootView {
        let vm = RootViewModel(self, appContext: appContext)
        return RootView(viewModel: vm)
    }
    
    func createPlacesView(showingSideMenu: Binding<Bool>) -> PlacesView {
        let vm = PlacesViewModel(self,
                               coordinator: placeCoordinator,
                               locationManager: locationManager,
                               fetchPlaces: FetchPlaces(repository: placeRepository),
                               syncStatus: syncService.syncStatus,
                               reachabilityService: reachabilityService)
        return PlacesView(viewModel: vm, showingSideMenu: showingSideMenu)
    }

    func createPlacesMapView(places: [PlaceUI],
                             selectedPlaceId: Binding<UUID?>,
                             isParentPresenting: Binding<Bool>,
                             showingCreatePlaceMenu: Binding<Bool>,
                             mapReloadGen: Int,
                             navBarHeight: CGFloat) -> PlacesMapView {
        let vm = PlacesMapViewModel(self,
                                    coordinator: placeCoordinator,
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
                                     coordinator: placeCoordinator,
                                     locationManager: locationManager)
        return PlacesListView(viewModel: vm, places: places, selectedPlaceId: selectedPlaceId)
    }
    
    func createPlaceCreateQuickView(place: PlaceUI) -> PlaceCreateQuickView {
        let vm = PlaceCreateQuickViewModel(self,
                                           coordinator: placeCoordinator,
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
                                     coordinator: currentPlaceCoordinator(),
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
                                           coordinator: placeCoordinator,
                                           updatePlace: UpdatePlace(repository: placeRepository),
                                           getPlaceThumbnails: GetPlaceThumbnails(loader: imageLoader),
                                           getPlaceImage: GetPlaceImage(loader: imageLoader),
                                           mode: mode)
        return PlaceEditContentView(viewModel: vm, place: place, showMissingName: showMissingName)
    }

    func createPlaceEditView(place: PlaceUI) -> PlaceEditView {
        let vm = PlaceEditViewModel(self,
                                    coordinator: currentCoordinator(),
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
                                      coordinator: placeCoordinator,
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
                                  updateTag: UpdateTag(repository: tagRepository),
                                  syncStatus: syncService.syncStatus)
        return TagListView(viewModel: vm, showingSideMenu: showingSideMenu)
    }
    
    func createTagDetailsView(tag: TagUI) -> TagDetailsView {
        let vm = TagDetailsViewModel(self,
                                     locationManager: locationManager,
                                     coordinator: tagCoordinator,
                                     tag: tag,
                                     updateTag: UpdateTag(repository: tagRepository),
                                     fetchTagPlaces: FetchTagPlaces(repository: placeRepository),
                                     updatePlace: UpdatePlace(repository: placeRepository))
        return TagDetailsView(viewModel: vm)
    }
    
    func createTagMapView(tagId: UUID) -> TagMapView {
        let vm = TagMapViewModel(self,
                                 tagId: tagId,
                                 fetchTagPlaces: FetchTagPlaces(repository: placeRepository))
        return TagMapView(viewModel: vm)
    }

    func createGroupListView(showingSideMenu: Binding<Bool>) -> GroupListView {
        let vm = GroupListViewModel(self,
                                    coordinator: groupCoordinator,
                                    fetchGroupsWithCount: FetchGroupsWithCount(repository: groupRepository),
                                    updateGroup: UpdateGroup(repository: groupRepository),
                                    syncStatus: syncService.syncStatus)
        return GroupListView(viewModel: vm, showingSideMenu: showingSideMenu)
    }
    
    func createGroupDetailsView(group: GroupUI) -> GroupDetailsView {
        let vm = GroupDetailsViewModel(self,
                                       locationManager: locationManager,
                                       coordinator: groupCoordinator,
                                       group: group,
                                       updateGroup: UpdateGroup(repository: groupRepository),
                                       fetchGroupPlaces: FetchGroupPlaces(repository: placeRepository),
                                       updatePlace: UpdatePlace(repository: placeRepository))
        return GroupDetailsView(viewModel: vm)
    }

    func createGroupMapView(groupId: UUID) -> GroupMapView {
        let vm = GroupMapViewModel(self,
                                   groupId: groupId,
                                   fetchGroupPlaces: FetchGroupPlaces(repository: placeRepository))
        return GroupMapView(viewModel: vm)
    }

    func createLookupPlacesView() -> LookupPlacesView {
        let vm = LookupPlacesViewModel(self,
                                       coordinator: placeCoordinator,
                                       addressLookupService: addressLookupService,
                                       locationManager: locationManager,
                                       reachabilityService: reachabilityService,
                                       updatePlace: UpdatePlace(repository: placeRepository))
        return LookupPlacesView(viewModel: vm)
    }

    func createLookupPlacesView(place: Binding<PlaceUI>) -> LookupPlacesView {
        let vm = LookupPlacesViewModel(self,
                                       coordinator: placeCoordinator,
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
                                      coordinator: placeCoordinator,
                                      createPlace: CreatePlace(repository: placeRepository),
                                      lookupResolvedItem: lookupResolvedItem)
        return LookupPlaceView(viewModel: vm, place: place, status: status)
    }
    
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
                                   coordinator: placeCoordinator,
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

    // MARK: - private methods
    private func currentCoordinator() -> any NavigationCoordinator {
        switch appContext.currentSideMenuContext {
            case .main:
                return placeCoordinator
            case .groups:
                return groupCoordinator
            case .tags:
                return tagCoordinator
            default:
                assertionFailure("Undefined coordinator for section \(appContext.currentSideMenuContext)")
                return placeCoordinator
        }
    }
    
    private func currentPlaceCoordinator() -> any PlaceNavigationCoordinator {
        switch appContext.currentSideMenuContext {
            case .main:
                return placeCoordinator
            case .groups:
                return groupCoordinator
            case .tags:
                return tagCoordinator
            default:
                assertionFailure("Undefined coordinator for section \(appContext.currentSideMenuContext)")
                return placeCoordinator
        }
    }
    
    private func clearDatabase() async throws {
        // Places first: cascade-deletes their images, nullifies tag/group refs
        try await placeRepository.clearTable()
        try await tagRepository.clearTable()
        try await groupRepository.clearTable()
        // Should be empty already, just in case...
        try await imageRepository.clearTable()
        // Independant from others
        try await profileRepository.clearTable()
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
