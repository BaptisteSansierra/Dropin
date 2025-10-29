//
//  CatOpenData.swift
//  Dropin
//
//  Created by baptiste sansierra on 27/10/25.
//

#if DEBUG

import Foundation
import CoreLocation
import Combine
import SwiftUI
import SwiftData

@MainActor
final class CatOpenData {
    
    private var url: URL
    private var cancellables = Set<AnyCancellable>()
    private var items = [OpenDataItem]()
    private let placeRepository: PlaceRepository
    private let tagRepository: TagRepository
    private let groupRepository: GroupRepository
    
    init(modelContext: ModelContext) throws {
        guard let url = URL(string: "https://opendata.amb.cat/equipaments/search") else {
            throw URLError(.unknown)
        }
        self.url = url
        placeRepository = PlaceRepositoryImpl(modelContext: modelContext)
        tagRepository = TagRepositoryImpl(modelContext: modelContext)
        groupRepository = GroupRepositoryImpl(modelContext: modelContext)
    }
    
    func load() async throws {
        try await fetchData()
    }
    
    private func fetchData() async throws {
        print("Fetch Cat OpenData")
        Task.detached(priority: .background) {
            let (data, response) = try await URLSession.shared.data(from: self.url)
            guard let response = response as? HTTPURLResponse,
            response.statusCode >= 200 && response.statusCode <= 300 else {
                throw URLError(.badServerResponse)
            }
            do {
                let decoded = try JSONDecoder().decode(OpenData.self, from: data)
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.items = decoded.items
                    //print("\(self.items.count) items decoded")
                    
//                    for item in items {
//                        print("ITEM: \(item.titol)")
//                        let coords = item.localitzacio.localitzacio_geolocalitzacio.first!
//                        print("   \(coords.first!) - \(coords.last!)")
//                    }
                    
                    print("\(items.count) Cat OpenData items fetched")

                    Task {
                        do {
                            try await self.convertToDropinData()
                        } catch {
                            print("Zut zut zut \(error)")
                        }
                    }

                }
            } catch {
                print("Decoding error: \(error)")
            }
        }
    }
    
    private func fetchDataCombine() {
        URLSession.shared.dataTaskPublisher(for: url)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse,
                      response.statusCode >= 200 && response.statusCode <= 300 else {
                    
                    print("ERROR: \(output.response)")
                    
                    throw URLError(.badServerResponse)
                }
                
                print("decoding str debug")
                
                let str = String(data: output.data, encoding: .utf8)
                
                print("READ: \(str!)")
                
                return output.data
            }
            .decode(type: OpenData.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        ()
                    case .failure(_):
                        ()
                }
            }, receiveValue: { [weak self] openData in
                guard let self = self else { return }
                self.items = openData.items
            })
            .store(in: &cancellables)
    }
    
    private func convertToDropinData() async throws {
        print("Convert data to dropin...")
        var tags = [TagEntity]()
        var groups = [GroupEntity]()
        var places = [PlaceEntity]()
        for item in items {
            print("   process item : \(item.titol)")

            // Create group
            var group: GroupEntity? = nil
            if item.tipusEntitat.count > 0 {
                if let idx = groups.firstIndex(where: { $0.name == item.tipusEntitat }) {
                    group = groups[idx]
                } else {
                    let g = GroupEntity(name: item.tipusEntitat, color: Color.random().hex)
                    groups.append(g)
                    group = g
                }
            }
            // Create tags
            var placeTags = [TagEntity]()
            if item.ambit.count > 0 {
                if let idx = tags.firstIndex(where: { $0.name == item.ambit }) {
                    placeTags.append(tags[idx])
                } else {
                    let t = TagEntity(name: item.ambit, color: Color.random().hex)
                    tags.append(t)
                    placeTags.append(t)
                }
            }
            if item.subambit.count > 0 {
                if let idx = tags.firstIndex(where: { $0.name == item.subambit }) {
                    placeTags.append(tags[idx])
                } else {
                    let t = TagEntity(name: item.subambit, color: Color.random().hex)
                    tags.append(t)
                    placeTags.append(t)
                }
            }
            // Create place
            let place = PlaceEntity(id: UUID().uuidString,
                                    name: item.titol,
                                    coordinates: item.coords,
                                    address: item.address,
                                    systemImage: "lock.open.fill",
                                    tags: placeTags,
                                    group: group,
                                    creationDate: Date())
            places.append(place)
        }
        
        do {
            for group in groups {
                try await groupRepository.create(group)
            }
            for tag in tags {
                try await tagRepository.create(tag)
            }
            for place in places {
                try await placeRepository.create(place)
            }
            print("\(groups.count) Groups created")
            print("\(tags.count) Tags created")
            print("\(places.count) Places created")
            
            
            
            let backPlaces = try await placeRepository.getAll()
            print("Places from database = \(backPlaces.count)")
        } catch {
            print("Couldn't populate database: \(error)")
        }
    }
}

#endif
