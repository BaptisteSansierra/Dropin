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
    @ObservationIgnored private let getGroups: FetchGroups
    @ObservationIgnored private let getTags: FetchTags

    init(_ appContainer: AppContainer,
         getGroups: FetchGroups,
         getTags: FetchTags,
         filter: Binding<PlaceFilter?>) {
        self.appContainer = appContainer
        self.getGroups = getGroups
        self.getTags = getTags
        self.filter = filter
    }
    
    func loadData() async throws {
        groups = try await getGroups.execute()
            .map { GroupMapper.toUI($0) }
        tags = try await getTags.execute()
            .map { TagMapper.toUI($0) }
    }
}
