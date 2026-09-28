//
//  SupabasePaginator.swift
//  Dropin
//
//  Supabase's hosted PostgREST caps any unbounded query at 1000 rows, silently —
//  no error, just a truncated result. Anything that can plausibly return more
//  than that (currently: the pull fetches) needs to page through `.range()`
//  instead of a single `.execute()`.
//

import Supabase

enum SupabasePaginator {
    static let pageSize = 1000

    /// Runs `makeQuery(from, to)` repeatedly, accumulating rows, until a page
    /// comes back shorter than `pageSize` (i.e. the last page). `makeQuery` must
    /// apply a stable `.order(...)` — range pagination is unreliable without one.
    static func fetchAll<T: Decodable>(
        _ makeQuery: (_ from: Int, _ to: Int) -> PostgrestTransformBuilder
    ) async throws -> [T] {
        var all: [T] = []
        var offset = 0
        while true {
            let page: [T] = try await makeQuery(offset, offset + pageSize - 1).execute().value
            all.append(contentsOf: page)
            guard page.count == pageSize else { break }
            offset += pageSize
        }
        return all
    }
}
