//
//  String+Lemma.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/10/26.
//

import Foundation
import NaturalLanguage

extension String {

    /// Lemma-based normalization: reduces each word to its dictionary/base form
    /// (so singular/plural variants match without hand-rolled per-language suffix rules),
    /// then case/diacritic-folds the result.
    /// Lemmatization runs on the original text first, folding case/diacritics beforehand risks breaking the tagger's dictionary
    /// lookup for accented languages. Falls back to the original word whenever the tagger has no lemma for it (unsupported
    /// language, or just no match), so this degrades to a plain case/diacritic-insensitive compare rather than ever dropping input.
    var lemmaNormalized: String {
        Self.lemmatized(self)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private static func lemmatized(_ string: String) -> String {
        guard !string.isEmpty else { return string }
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = string
        let range = string.startIndex..<string.endIndex
        // Both sides of any comparison are already in the app's current display language,
        // so set it explicitly rather than letting the tagger guess — automatic detection
        // is unreliable on short 1-2 word strings.
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
