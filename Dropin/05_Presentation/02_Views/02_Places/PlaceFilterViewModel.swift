//
//  PlaceFilterViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/4/26.
//

import SwiftUI

@MainActor
@Observable class PlaceFilterViewModel {
    
    var categories: [CategoryUIModel] = []
    var tags: [TagUIModel] = []
    var filter: Binding<PlaceFilter?>

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let fetchCategories: FetchCategories
    @ObservationIgnored private let fetchTags: FetchTags

    init(_ appContainer: AppContainer,
         fetchCategories: FetchCategories,
         fetchTags: FetchTags,
         filter: Binding<PlaceFilter?>) {
        self.appContainer = appContainer
        self.fetchCategories = fetchCategories
        self.fetchTags = fetchTags
        self.filter = filter
    }
    
    func loadData() async throws {
        categories = try await fetchCategories() 
            .filter { $0.isActive }
            .map { CategoryMapper.toUI($0) }
        tags = try await fetchTags()
            .filter { $0.isActive }
            .map { TagMapper.toUI($0) }
    }
}
