//
//  Domain_AvailableTagName.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/11/26.
//

import Foundation
import Testing
@testable import Dropin

@MainActor
struct Domain_AvailableTagName {

    private let localTagRepo: MockTagRepository = MockTagRepository()

    private func availableTagName(taken names: [String], deleted deletedNames: [String] = []) async throws -> AvailableTagName {
        for name in names {
            try await UpsertTag(repository: localTagRepo)(Dropin.Tag(name: name, color: String.randomColor()))
        }
        for name in deletedNames {
            let tag = Dropin.Tag(name: name, color: String.randomColor()).deleted(deletedAt: Date())
            try await UpsertTag(repository: localTagRepo)(tag)
        }
        return AvailableTagName(repository: localTagRepo)
    }

    // MARK: - Proposal

    @Test func baseIsFree() async throws {
        let availableTagName = try await availableTagName(taken: ["Other"])
        #expect(try await availableTagName(base: "Mapstr") == "Mapstr")
    }

    @Test func baseIsTaken() async throws {
        let availableTagName = try await availableTagName(taken: ["Mapstr"])
        #expect(try await availableTagName(base: "Mapstr") == "Mapstr_01")
    }

    @Test func baseAndFirstSuffixAreTaken() async throws {
        let availableTagName = try await availableTagName(taken: ["Mapstr", "Mapstr_01"])
        #expect(try await availableTagName(base: "Mapstr") == "Mapstr_02")
    }

    // MARK: - Case

    @Test func caseInsensitive() async throws {
        let availableTagName = try await availableTagName(taken: ["mapstr", "MAPSTR_01"])
        #expect(try await availableTagName(base: "Mapstr") == "Mapstr_02")
        #expect(try await availableTagName.isAvailable("Mapstr") == false)
        #expect(try await availableTagName.isAvailable("mapstr_01") == false)
    }

    // MARK: - Soft deleted

    @Test func softDeletedDoesNotCount() async throws {
        let availableTagName = try await availableTagName(taken: [], deleted: ["Mapstr"])
        #expect(try await availableTagName(base: "Mapstr") == "Mapstr")
        #expect(try await availableTagName.isAvailable("Mapstr"))
    }

    // MARK: - isAvailable

    @Test func isAvailable() async throws {
        let availableTagName = try await availableTagName(taken: ["Mapstr"])
        #expect(try await availableTagName.isAvailable("Mapstr") == false)
        #expect(try await availableTagName.isAvailable("Mapstr_01"))
        #expect(try await availableTagName.isAvailable("Dropin"))
    }

    // MARK: - Surrounding whitespaces

    @Test func surroundingWhitespacesAreIgnored() async throws {
        let availableTagName = try await availableTagName(taken: ["Mapstr"])
        #expect(try await availableTagName.isAvailable("Mapstr ") == false)
        #expect(try await availableTagName.isAvailable(" Mapstr") == false)
        #expect(try await availableTagName.isAvailable("  mapstr  ") == false)
        // The proposal is built on the trimmed base
        #expect(try await availableTagName(base: "Mapstr ") == "Mapstr_01")
    }

    @Test func proposalIsTrimmed() async throws {
        let availableTagName = try await availableTagName(taken: [])
        #expect(try await availableTagName(base: " Mapstr ") == "Mapstr")
    }
}
