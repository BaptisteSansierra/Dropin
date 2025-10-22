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
    var locationManager: LocationManager = LocationManager()
    
    init() {
        do {
            // Create a mock database
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let mockModelContainer = try ModelContainer(for: SDPlace.self, SDTag.self, SDGroup.self,
                                                        configurations: modelConfiguration)
            let mockModelContext = mockModelContainer.mainContext
            mockModelContext.autosaveEnabled = false
            
            self.mockModelContainer = mockModelContainer
            self.mockModelContext = mockModelContext
            self.appContainer = AppContainer(modelContext: mockModelContext, locationManager: locationManager)
            
            try AppContainer.insertMockData(modelContext: mockModelContext)
            
        } catch {
            fatalError("couldn't create mock data \(error)")
        }
    }

    func getAllPlaceUI() -> [PlaceUI] {
        do {
            let sorts = [SortDescriptor(\SDPlace.name), SortDescriptor(\SDPlace.creationDate)]
            let sdArray = try mockModelContext.fetch(FetchDescriptor<SDPlace>(sortBy: sorts)) as [SDPlace]
            let domainItems = sdArray.map { PlaceMapper.toDomain($0) }
            return domainItems.map { PlaceMapper.toUI($0) }
        } catch {
            fatalError("couldn't retrieve place mock data \(error)")
        }
    }

    func getAllGroupUI() -> [GroupUI] {
        do {
            let sorts = [SortDescriptor(\SDGroup.name), SortDescriptor(\SDGroup.creationDate)]
            let sdArray = try mockModelContext.fetch(FetchDescriptor<SDGroup>(sortBy: sorts)) as [SDGroup]
            let domainItems = sdArray.map { GroupMapper.toDomain($0) }
            return domainItems.map { GroupMapper.toUI($0) }
        } catch {
            fatalError("couldn't retrieve place mock data \(error)")
        }
    }

    func getAllTagUI() -> [TagUI] {
        do {
            let sorts = [SortDescriptor(\SDTag.name), SortDescriptor(\SDTag.creationDate)]
            let sdArray = try mockModelContext.fetch(FetchDescriptor<SDTag>(sortBy: sorts)) as [SDTag]
            let domainItems = sdArray.map { TagMapper.toDomain($0) }
            return domainItems.map { TagMapper.toUI($0) }
        } catch {
            fatalError("couldn't retrieve place mock data \(error)")
        }
    }
    
    func getPlaceUI(_ index: Int = 0) -> PlaceUI {
        do {
            let sorts = [SortDescriptor(\SDPlace.name), SortDescriptor(\SDPlace.creationDate)]
            let sdArray = try mockModelContext.fetch(FetchDescriptor<SDPlace>(sortBy: sorts)) as [SDPlace]
            let domainItem = PlaceMapper.toDomain(sdArray[index])
            return PlaceMapper.toUI(domainItem)
        } catch {
            fatalError("couldn't retrieve place mock data \(error)")
        }
    }
    
    func getTagUI(_ index: Int = 0) -> TagUI {
        do {
            let sorts = [SortDescriptor(\SDTag.name), SortDescriptor(\SDTag.creationDate)]
            let sdArray = try mockModelContext.fetch(FetchDescriptor<SDTag>(sortBy: sorts))
            let domainItem = TagMapper.toDomain(sdArray[index])
            return TagMapper.toUI(domainItem)
        } catch {
            fatalError("couldn't retrieve tag mock data \(error)")
        }
    }
    
    func getGroupUI(_ index: Int = 0) -> GroupUI {
        do {
            let sorts = [SortDescriptor(\SDGroup.name), SortDescriptor(\SDGroup.creationDate)]
            let sdArray = try mockModelContext.fetch(FetchDescriptor<SDGroup>(sortBy: sorts))
            let domainItem = GroupMapper.toDomain(sdArray[index])
            return GroupMapper.toUI(domainItem)
        } catch {
            fatalError("couldn't retrieve group mock data \(error)")
        }
    }
}

#endif
