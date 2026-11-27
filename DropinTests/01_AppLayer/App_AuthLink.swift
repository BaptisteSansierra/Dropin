//
//  App_AuthLink.swift
//  DropinTests
//
//  Created by baptiste sansierra on 18/11/26.
//

import Foundation
import Testing
@testable import Dropin

/// Auth email links (Universal Links) recognized by the app
@MainActor
struct App_AuthLink {

    private func link(_ string: String) -> AuthLink? {
        AuthLink(url: URL(string: string)!)
    }

    @Test func passwordRecovery() {
        let parsed = link("https://dropin.lat/reset-password.html?token_hash=abc&type=recovery")
        #expect(parsed?.kind == .passwordRecovery)
        #expect(parsed?.tokenHash == "abc")
    }

    @Test func emailConfirmation() {
        let parsed = link("https://dropin.lat/email-confirmed.html?token_hash=abc&type=signup")
        #expect(parsed?.kind == .emailConfirmation)
        #expect(parsed?.tokenHash == "abc")
    }

    @Test func pathWithoutExtension() {
        // Cloudflare Pages serves its pages without ".html"
        #expect(link("https://dropin.lat/reset-password?token_hash=abc")?.kind == .passwordRecovery)
        #expect(link("https://dropin.lat/email-confirmed?token_hash=abc")?.kind == .emailConfirmation)
    }

    @Test func missingTokenIsUnusable() {
        // Supabase error redirect: still an auth link, but nothing to verify
        let recovery = link("https://dropin.lat/reset-password.html?error=access_denied&error_code=otp_expired")
        #expect(recovery?.kind == .passwordRecovery)
        #expect(recovery?.tokenHash == nil)
        #expect(link("https://dropin.lat/email-confirmed.html?token_hash=")?.tokenHash == nil)
    }

    @Test func openAppPage() {
        // "Open Dropin" in the welcome email: not an auth link, matched with or without ".html"
        #expect(link("https://dropin.lat/app?lang=fr") == nil)
        #expect(AuthLink.isPage(DropinApp.urls.openAppURL, URL(string: "https://dropin.lat/app?lang=fr")!))
        #expect(AuthLink.isPage(DropinApp.urls.openAppURL, URL(string: "https://dropin.lat/app.html")!))
        #expect(!AuthLink.isPage(DropinApp.urls.openAppURL, URL(string: "https://dropin.lat/apps")!))
        #expect(!AuthLink.isPage(DropinApp.urls.openAppURL, URL(string: "https://example.com/app")!))
    }

    @Test func otherURLsAreIgnored() {
        #expect(link("https://dropin.lat/p.html?id=abc") == nil)
        #expect(link("https://dropin.lat/") == nil)
        #expect(link("https://example.com/reset-password.html?token_hash=abc") == nil)
        #expect(link("https://dropin.lat/reset-password.html.bak?token_hash=abc") == nil)
    }
}
