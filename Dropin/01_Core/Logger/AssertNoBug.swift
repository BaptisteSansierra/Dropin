//
//  AssertNoBug.swift
//  Dropin
//
//  Loud-fail in DEBUG on errors that are *definitely bugs* rather than
//  transient runtime issues. Release builds are unaffected — callers still
//  log + recover normally. Use from catch blocks before Log.error:
//
//      catch {
//          assertNoBug(error)
//          Log.error("...")
//      }
//

import Foundation
import Supabase

/// Asserts in DEBUG when `error` matches a class of failure that points to a
/// programming/wiring bug rather than a recoverable runtime condition:
///   - `DecodingError` / `EncodingError` — DTO ↔ schema mismatch
///   - `AuthError.notAuthenticated` — code path expected a signed-in user but didn't have one
///   - PostgREST 42501 (insufficient privilege / RLS rejection) — missing grant or RLS misconfig
///
/// Add categories here as more "should never happen in prod" errors surface.
@inline(__always)
func assertNoBug(_ error: Error,
                 file: StaticString = #fileID,
                 line: UInt = #line) {
    #if DEBUG
    if let decoding = error as? DecodingError {
        assertionFailure("DecodingError — DTO out of sync with schema: \(decoding)", file: file, line: line)
        return
    }
    if let encoding = error as? EncodingError {
        assertionFailure("EncodingError: \(encoding)", file: file, line: line)
        return
    }
    if case AuthError.notAuthenticated = error {
        assertionFailure("AuthError.notAuthenticated — caller expected a signed-in session", file: file, line: line)
        return
    }
    if let pg = error as? PostgrestError, pg.code == "42501" {
        assertionFailure("PostgREST 42501 — missing GRANT / RLS rejection: \(pg.message)", file: file, line: line)
        return
    }
    #endif
}
