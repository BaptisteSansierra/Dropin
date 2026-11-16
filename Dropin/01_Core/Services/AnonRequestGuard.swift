//
//  AnonRequestGuard.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/11/26.
//
//  Refuses any Supabase request about to be sent as the `anon` role.
//
//  supabase-swift's `SupabaseClient.adapt(request:)` does `try? await auth.session.accessToken`:
//  when getting the session throws (refresh rate-limited, session lost…), the request silently
//  keeps its default `Authorization: Bearer <publishable key>` and reaches PostgREST as anon (→ 42501 permission denied).
//  Dropin never needs anon outside of `/auth/v1/` (sign-in/up, refresh, password reset…),
//  so reaching this guard means an error upstream was missed.
//

import Foundation

final class AnonRequestGuard: URLProtocol {

    private static let host = AppConfig.Supabase.url.host
    private static let anonAuthorization = "Bearer \(AppConfig.Supabase.anonKey)"

    /// Session configuration with the guard installed, to give to the Supabase client
    static func sessionConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [AnonRequestGuard.self] + (config.protocolClasses ?? [])
        return config
    }

    // Only claim the requests to refuse: every other request goes through the default stack untouched
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url,
              url.host == host,
              !url.path.hasPrefix("/auth/v1/") else { return false }
        return request.value(forHTTPHeaderField: "Authorization") == anonAuthorization
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let target = "\(request.httpMethod ?? "") \(request.url?.path ?? "")"
        Log.error("AnonRequestGuard: blocked request sent as anon: \(target)")
        DropinTracker.shared.capture("Blocked anon request \(target)", authFlow: .anon_request)
        client?.urlProtocol(self, didFailWithError: AuthServiceError.notAuthenticated)
    }

    override func stopLoading() {}
}
