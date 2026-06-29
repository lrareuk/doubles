//
//  Config.swift
//  Runtime endpoints. The anon (publishable) key is safe in the client; the
//  service-role and Anthropic keys NEVER ship here — they live server-side only.
//
//  Overridable via Info.plist keys (DOUBLES_API_BASE_URL / SUPABASE_URL /
//  SUPABASE_ANON_KEY) for device builds; the defaults below target the local API
//  on the simulator.
//

import Foundation

enum Config {
    /// The Doubles API. On the iOS simulator, localhost reaches the Mac running
    /// `pnpm --filter @doubles/api dev`. On a physical device, set
    /// DOUBLES_API_BASE_URL in Info.plist to your Mac's LAN IP (e.g. http://192.168.x.x:3000).
    static var apiBaseURL: URL {
        if let s = plist("DOUBLES_API_BASE_URL"), let u = URL(string: s) { return u }
        return URL(string: "http://localhost:3000")!
    }

    static var supabaseURL: URL {
        if let s = plist("SUPABASE_URL"), let u = URL(string: s) { return u }
        return URL(string: "https://ctouykgmzmqoabhmlzcq.supabase.co")!
    }

    /// Publishable anon key — safe to embed in a client (RLS still applies).
    static var supabaseAnonKey: String {
        plist("SUPABASE_ANON_KEY") ??
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0b3V5a2dtem1xb2FiaG1semNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI2NDE2MjksImV4cCI6MjA5ODIxNzYyOX0.wb4ywOqJW9PgNfO13PPrwf6A5hp7QOKwirrwM96XuS4"
    }

    /// Convenience demo credentials (seed user) so the live demo is one tap.
    static let demoEmail = "aria@doubles.dev"
    static let demoPassword = "doubles-seed-password-123"

    /// When YES (Info.plist `DOUBLES_USE_MOCK`), run fully offline on bundled
    /// demo data — no Supabase, no API, no network. Reliable for on-device demos.
    static var useMock: Bool { (plist("DOUBLES_USE_MOCK") ?? "").uppercased() == "YES" }

    private static func plist(_ key: String) -> String? {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String)?.trimmingCharacters(in: .whitespaces).nilIfEmpty
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
