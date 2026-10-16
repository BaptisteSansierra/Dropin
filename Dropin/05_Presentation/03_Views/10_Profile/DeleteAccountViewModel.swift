//
//  DeleteAccountViewModel.swift
//  Dropin
//

import Foundation

@MainActor
@Observable class DeleteAccountViewModel {

    struct Counts {
        var places: Int = 0
        var categoriesAndTags: Int = 0
        var photos: Int = 0
    }

    var counts = Counts()

    var isExporting: Bool = false
    var exportedTemporaryFile: IdentifiableURL?

    var showConfirmationSheet: Bool = false
    var agreementText: String = ""
    var isDeleting: Bool = false
    var deleteError: String?

    @ObservationIgnored private let appContainer: AppContainer
    @ObservationIgnored private let coordinator: ProfileCoordinator
    @ObservationIgnored private let fetchPlaces: FetchPlaces
    @ObservationIgnored private let fetchCategories: FetchCategories
    @ObservationIgnored private let fetchTags: FetchTags
    @ObservationIgnored private let imageRepository: any PlaceImageRepository

    init(appContainer: AppContainer,
         coordinator: ProfileCoordinator,
         fetchPlaces: FetchPlaces,
         fetchCategories: FetchCategories,
         fetchTags: FetchTags,
         imageRepository: any PlaceImageRepository) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.fetchPlaces = fetchPlaces
        self.fetchCategories = fetchCategories
        self.fetchTags = fetchTags
        self.imageRepository = imageRepository
    }

    /// The exact, localized phrase the user must type to confirm
    /// compared  case-sensitively against a translated string, never a hardcoded "I AGREE".
    var confirmToken: String { String(localized: "delete_account.gate.token") }
    var isAgreementValid: Bool { agreementText == confirmToken }

    // MARK: - Consequences card

    func loadCounts() async {
        do {
            let places = try await fetchPlaces()
                .filter({ $0.isActive })
            let categories = try await fetchCategories()
                .filter({ $0.isActive })
            let tags = try await fetchTags()
                .filter({ $0.isActive })
            var photos = 0
            for place in places {
                let thumbs = try await imageRepository.fetchThumbnails(placeId: place.id)
                photos += thumbs.count
            }
            counts = Counts(places: places.count,
                            categoriesAndTags: categories.count + tags.count,
                            photos: photos)
        } catch {
            Log.error("DeleteAccountViewModel: loadCounts failed: \(error)")
        }
    }

    // MARK: - Export

    func export() async {
        isExporting = true
        do {
            let url = try await ExportService(fetchPlaces: fetchPlaces,
                                              fetchCategories: fetchCategories,
                                              fetchTags: fetchTags)
                .execute()
            exportedTemporaryFile = IdentifiableURL(url: url)
        } catch {
            Log.error("DeleteAccountViewModel: export failed: \(error)")
            isExporting = false
        }
    }

    func exportSheetDismissed() {
        isExporting = false
        exportedTemporaryFile = nil
    }

    // MARK: - Deletion

    func confirmDelete() async {
        guard isAgreementValid else { return }
        deleteError = nil
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await appContainer.deleteAccount()
            // Success flips authStatus — the app routes back to Sign in on its
            // own, nothing else to do here.
        } catch {
            Log.error("DeleteAccountViewModel: deleteAccount failed: \(error)")
            deleteError = String(localized: "delete_account.error.generic")
        }
    }

    // MARK: - Navigation
    func pop() {
        coordinator.pop()
    }
}
