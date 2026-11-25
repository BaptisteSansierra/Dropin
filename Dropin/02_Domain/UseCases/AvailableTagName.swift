//
//  AvailableTagName.swift
//  Dropin
//

import Foundation

@MainActor
struct AvailableTagName {
    private let repository: TagRepository

    init(repository: TagRepository) {
        self.repository = repository
    }

    /// `base` if available, else the first available `base_01`, `base_02`...
    /// Case-insensitive, surrounding whitespaces ignored (`nameKey`), soft-deleted tags don't count
    func callAsFunction(base: String) async throws -> String {
        let base = base.trimmedName
        let taken = try await takenNames()
        guard taken.contains(base.nameKey) else { return base }

        var index = 1
        while true {
            let candidate = "\(base)_\(String(format: "%02d", index))"
            if !taken.contains(candidate.nameKey) { return candidate }
            index += 1
        }
    }
    
    func isAvailable(_ name: String) async throws -> Bool {
        try await !takenNames().contains(name.nameKey)
    }
    
    private func takenNames() async throws -> Set<String> {
        Set(try await repository.fetch()
            .filter { $0.isActive }
            .map { $0.name.nameKey })
    }
}
