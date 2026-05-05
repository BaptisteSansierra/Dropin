//
//  PlaceFilterViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/4/26.
//

import SwiftUI

@MainActor
@Observable class PlaceFilterViewModel {
    
    var groups: [GroupUI] = []
    var tags: [TagUI] = []
    var filter: Binding<PlaceFilter?>

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let fetchGroups: FetchGroups
    @ObservationIgnored private let fetchTags: FetchTags

    init(_ appContainer: AppContainer,
         fetchGroups: FetchGroups,
         fetchTags: FetchTags,
         filter: Binding<PlaceFilter?>) {
        self.appContainer = appContainer
        self.fetchGroups = fetchGroups
        self.fetchTags = fetchTags
        self.filter = filter
    }
    
    func loadData() async throws {
        groups = try await fetchGroups()
            .map { GroupMapper.toUI($0) }
        tags = try await fetchTags()
            .map { TagMapper.toUI($0) }
    }
}
