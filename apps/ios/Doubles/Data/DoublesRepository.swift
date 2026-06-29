//
//  DoublesRepository.swift
//  All data access goes through this protocol. Swap MockRepository → APIRepository
//  in one place to wire the real backend (mirrors apps/api + packages/shared).
//

import SwiftUI

protocol DoublesRepository {
    // Today / world
    func snapshot() async throws -> WorldSnapshot
    func worlds() async throws -> [World]

    // Cast
    func cast() async throws -> [Persona]
    func relationships(for doubleId: String) async throws -> [Relationship]
    func beats(for doubleId: String) async throws -> [Beat]

    // Onboarding
    /// Create or update the caller's own double. Returns the saved persona.
    func upsertDouble(displayName: String, handle: String, personaPrompt: String, traits: [String], accentIndex: Int) async throws -> Persona
    /// Start a new season (world). Becomes the caller's current world.
    func createWorld(name: String, vibe: WorldVibe) async throws -> World
    /// Join an existing season by invite code. Becomes the caller's current world.
    func joinWorld(code: String) async throws -> World

    /// Create/return an invite code for the caller's current world (viral loop).
    func invite() async throws -> String

    // Game
    func markets() async throws -> [Market]
    func myBets() async throws -> [Bet]
    func placeBet(marketId: String, optionKey: String, stake: Int) async throws -> Bet
    func setAgenda(_ text: String) async throws
    func spendPowerMove(_ type: PowerMoveType, targetDoubleId: String?) async throws -> Int // returns remaining
    func unlock(beatId: String) async throws -> Beat

    // Season
    func standings() async throws -> [SeasonScore]
    func awards() async throws -> [Award]
    func episodeArchive() async throws -> [Episode]

    // Identity / safety
    func runPersonaModeration(_ text: String) async throws -> Bool // true = ok
    func entitlements() async throws -> [Entitlement]
    func deleteAccount() async throws
}

// MARK: - Environment injection

private struct RepositoryKey: EnvironmentKey {
    static let defaultValue: any DoublesRepository = MockRepository()
}

extension EnvironmentValues {
    var repo: any DoublesRepository {
        get { self[RepositoryKey.self] }
        set { self[RepositoryKey.self] = newValue }
    }
}

// The live implementation lives in APIRepository.swift.
