//
//  SuggestCategoryForAppleCategory.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/10/26.
//

import Foundation
import NaturalLanguage

/// Suggests an existing local Category whose name plausibly matches an Apple POI category's (already-localized) display name
/// e.g. "Restaurant" / "Restaurants" /"restaurant" should all match a POI category displaying as "Restaurant"
///
/// Matching is lemma-based (reduces each word to its dictionary/base form, so singular/plural variants match without hand-rolled per-language suffix rules),
/// then case and diacritic-folded. Lemmatization runs on the original text first, folding case/diacritics beforehand risks breaking the tagger's dictionary lookup
/// for accented languages, folding only happens on the lemmatized result.
///
@MainActor
struct SuggestCategoryForAppleCategory {
    private let repository: CategoryRepository

    init(repository: CategoryRepository) {
        self.repository = repository
    }

    func callAsFunction(appleCategoryDisplayName: String) async throws -> Category? {
        let target = Self.normalized(appleCategoryDisplayName)
        guard !target.isEmpty else { return nil }
        let categories = try await repository.fetch()
        return categories.first { Self.normalized($0.name) == target }
    }

    // MARK: - private
    private static func normalized(_ string: String) -> String {
        lemmatized(string)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    /// Falls back to the original word whenever the tagger has no lemma for it (unsupported language, or just no match), so this degrades to a plain
    /// case/diacritic-insensitive compare rather than ever dropping input.
    private static func lemmatized(_ string: String) -> String {
        guard !string.isEmpty else { return string }
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = string
        let range = string.startIndex..<string.endIndex
        // Both sides of the comparison are already in the app's current display language,
        // so set it explicitly rather than letting the tagger guess, automatic detection is unreliable on short 1-2 word strings.
        if let languageCode = Locale.current.language.languageCode?.identifier {
            tagger.setLanguage(NLLanguage(languageCode), range: range)
        }
        var words: [String] = []
        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma,
                             options: [.omitPunctuation, .omitWhitespace]) { tag, tokenRange in
            words.append(tag?.rawValue ?? String(string[tokenRange]))
            return true
        }
        return words.isEmpty ? string : words.joined(separator: " ")
    }
}
