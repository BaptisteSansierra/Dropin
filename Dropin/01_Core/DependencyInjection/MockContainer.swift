//
//  MockContainer.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

#if DEBUG

import Foundation
import SwiftData

@MainActor
final class MockContainer {
    
    var mockModelContainer: ModelContainer
    var mockModelContext: ModelContext
    var appContainer: AppContainer

    let locationManager: LocationManager = LocationManager()
    let addressLookupService: AddressLookupService
    let reachabilityService: any ReachabilityServiceProtocol = StubReachabilityService()
    let profileService: StubProfileService = StubProfileService()

    init() {
        addressLookupService = AddressLookupService(locationManager: locationManager)

        do {
            // Create a mock database
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let mockModelContainer = try ModelContainer(for: PlaceRecord.self, TagRecord.self, CategoryRecord.self, PlaceImageRecord.self, ProfileRecord.self,
                                                        configurations: modelConfiguration)
            let mockModelContext = mockModelContainer.mainContext
            mockModelContext.autosaveEnabled = false
            
            self.mockModelContainer = mockModelContainer
            self.mockModelContext = mockModelContext
            self.appContainer = AppContainer(modelContext: mockModelContext,
                                             appContext: AppContext(),
                                             locationManager: locationManager,
                                             addressLookupService: addressLookupService,
                                             reachabilityService: reachabilityService,
                                             profileService: profileService)
            
            try AppContainer.insertMockData(modelContext: mockModelContext)
            
        } catch {
            fatalError("couldn't create mock data \(error)")
        }
    }
    
    func updateReachability(_ v: Bool) {
        (reachabilityService as? StubReachabilityService)?.isConnected = v
    }
    
    func loadProfile() {
        Task {
            await profileService.load()
        }
    }

    func getAllPlaceUIModel() -> [PlaceUIModel] {
        do {
            let sorts = [SortDescriptor(\PlaceRecord.name), SortDescriptor(\PlaceRecord.createdAt)]
            let sdArray = try mockModelContext.fetch(FetchDescriptor<PlaceRecord>(sortBy: sorts)) as [PlaceRecord]
            let domainItems = sdArray.map { PlaceMapper.toDomain($0) }
            return domainItems.map { PlaceMapper.toUI($0) }
        } catch {
            fatalError("couldn't retrieve place mock data \(error)")
        }
    }

    func getAllCategoryUIModel() -> [CategoryUIModel] {
        do {
            let sorts = [SortDescriptor(\CategoryRecord.name), SortDescriptor(\CategoryRecord.createdAt)]
            let sdArray = try mockModelContext.fetch(FetchDescriptor<CategoryRecord>(sortBy: sorts)) as [CategoryRecord]
            let domainItems = sdArray.map { CategoryMapper.toDomain($0) }
            return domainItems.map { CategoryMapper.toUI($0) }
        } catch {
            fatalError("couldn't retrieve place mock data \(error)")
        }
    }

    func getAllTagUI() -> [TagUIModel] {
        do {
            let sorts = [SortDescriptor(\TagRecord.name), SortDescriptor(\TagRecord.createdAt)]
            let sdArray = try mockModelContext.fetch(FetchDescriptor<TagRecord>(sortBy: sorts)) as [TagRecord]
            let domainItems = sdArray.map { TagMapper.toDomain($0) }
            return domainItems.map { TagMapper.toUI($0) }
        } catch {
            fatalError("couldn't retrieve place mock data \(error)")
        }
    }
    
    func getPlaceUIModel(_ index: Int = 0) -> PlaceUIModel {
        do {
            let sorts = [SortDescriptor(\PlaceRecord.name), SortDescriptor(\PlaceRecord.createdAt)]
            let sdArray = try mockModelContext.fetch(FetchDescriptor<PlaceRecord>(sortBy: sorts)) as [PlaceRecord]
            let domainItem = PlaceMapper.toDomain(sdArray[index])
            return PlaceMapper.toUI(domainItem)
        } catch {
            fatalError("couldn't retrieve place mock data \(error)")
        }
    }
    
    func getNoAddressPlaceUIModel() -> PlaceUIModel {
        guard let place = getAllPlaceUIModel().first(where: { $0.hasNoAddress }) else {
            fatalError("no mock place without address")
        }
        return place
    }
    
    func getTagUIModel(_ index: Int = 0) -> TagUIModel {
        do {
            let sorts = [SortDescriptor(\TagRecord.name), SortDescriptor(\TagRecord.createdAt)]
            let sdArray = try mockModelContext.fetch(FetchDescriptor<TagRecord>(sortBy: sorts))
            let domainItem = TagMapper.toDomain(sdArray[index])
            return TagMapper.toUI(domainItem)
        } catch {
            fatalError("couldn't retrieve tag mock data \(error)")
        }
    }
    
    func getCategoryUIModel(_ index: Int = 0) -> CategoryUIModel {
        do {
            let sorts = [SortDescriptor(\CategoryRecord.name), SortDescriptor(\CategoryRecord.createdAt)]
            let sdArray = try mockModelContext.fetch(FetchDescriptor<CategoryRecord>(sortBy: sorts))
            let domainItem = CategoryMapper.toDomain(sdArray[index])
            return CategoryMapper.toUI(domainItem)
        } catch {
            fatalError("couldn't retrieve category mock data \(error)")
        }
    }
}

#endif
