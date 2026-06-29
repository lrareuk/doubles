//
//  Models.swift
//  Swift mirrors of the `packages/shared` contract — Codable, ready for the real
//  API, fed by MockRepository for now. UI-facing helpers (labels, accents) live here.
//

import SwiftUI

// MARK: - Enums

enum WorldVibe: String, Codable, CaseIterable, Identifiable {
    case messy, wholesomeChaos = "wholesome_chaos", villainArc = "villain_arc", nobodysSafe = "nobodys_safe"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .messy: "messy"
        case .wholesomeChaos: "wholesome chaos"
        case .villainArc: "villain arc"
        case .nobodysSafe: "nobody's safe"
        }
    }
    var blurb: String {
        switch self {
        case .messy: "petty, funny, a little feral."
        case .wholesomeChaos: "chaos, but everyone makes up by morning."
        case .villainArc: "everyone's the antagonist of someone's story."
        case .nobodysSafe: "high stakes. alliances mean nothing here."
        }
    }
    var emoji: String {
        switch self {
        case .messy: "🍿"; case .wholesomeChaos: "🌈"; case .villainArc: "😈"; case .nobodysSafe: "🔪"
        }
    }
}

enum SeasonStatus: String, Codable { case active, finale, ended }

enum RelationshipType: String, Codable, Hashable {
    case neutral, friend, ally, crush, rival, ex
    var label: String { rawValue }
    var accent: Color {
        switch self {
        case .crush: DS.magenta
        case .ally, .friend: DS.acid
        case .rival, .ex: DS.magenta
        case .neutral: DS.rose
        }
    }
    var symbol: String {
        switch self {
        case .neutral: "minus"
        case .friend: "person.fill.checkmark"
        case .ally: "hands.clap.fill"
        case .crush: "heart.fill"
        case .rival: "bolt.fill"
        case .ex: "heart.slash.fill"
        }
    }
}

enum BeatKind: String, Codable {
    case post, dm, scene, twist, ship
    /// The four visual treatments in the feed.
    var label: String {
        switch self {
        case .post: "post"
        case .dm: "confessional"
        case .scene: "scene"
        case .twist: "plot twist"
        case .ship: "ship"
        }
    }
    var accent: Color {
        switch self {
        case .post, .scene: DS.bone
        case .dm: DS.acid
        case .twist: DS.magenta
        case .ship: DS.acid
        }
    }
}

enum BeatVisibility: String, Codable { case `public`, revealGated = "reveal_gated" }

enum PowerMoveType: String, Codable, CaseIterable, Identifiable {
    case whisper, rumour, sabotage, forceEncounter = "force_encounter", spotlight
    var id: String { rawValue }
    var title: String {
        switch self {
        case .whisper: "whisper"
        case .rumour: "start a rumour"
        case .sabotage: "sabotage"
        case .forceEncounter: "force an encounter"
        case .spotlight: "spotlight"
        }
    }
    var blurb: String {
        switch self {
        case .whisper: "lean on your own double. nudge how they act."
        case .rumour: "plant a story thread and watch it spread."
        case .sabotage: "cool down a pairing you don't like."
        case .forceEncounter: "make two doubles cross paths. on purpose."
        case .spotlight: "aim the camera at your double this episode."
        }
    }
    var symbol: String {
        switch self {
        case .whisper: "ear.fill"
        case .rumour: "quote.bubble.fill"
        case .sabotage: "flame.fill"
        case .forceEncounter: "arrow.triangle.merge"
        case .spotlight: "light.beacon.max.fill"
        }
    }
    /// Whether this move needs another double as a target.
    var needsTarget: Bool { self == .sabotage || self == .forceEncounter }
}

enum MarketStatus: String, Codable { case open, resolved, void }
enum BetStatus: String, Codable { case open, won, lost, void }

enum AgendaStatus: String, Codable { case pending, inProgress = "in_progress", succeeded, failed }

// MARK: - Core types

struct Persona: Identifiable, Codable, Hashable {
    let id: String
    var ownerUserId: String
    var displayName: String
    var handle: String
    var personaPrompt: String
    var traits: [String]
    var vibe: String                 // one-line identity used on cards
    var accentIndex: Int             // index into DS.characters
    var isMine: Bool

    var accent: Color { DS.characters[accentIndex % DS.characters.count] }
    var initials: String {
        let parts = displayName.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }
}

struct World: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var vibe: WorldVibe
    var seasonNumber: Int
    var seasonStatus: SeasonStatus
    var currentEpisode: Int
    var nextEpisodeInHours: Int?
}

struct Beat: Identifiable, Codable, Hashable {
    let id: String
    var kind: BeatKind
    var authorId: String
    var participantIds: [String]
    var content: String
    var visibility: BeatVisibility
    var likeCount: Int
    var replyCount: Int

    var isGated: Bool { visibility == .revealGated }
}

struct Episode: Identifiable, Codable, Hashable {
    let id: String
    var number: Int
    var headline: String
    var dateLabel: String           // e.g. "mon · 7:00am"
    var status: String
    var isUnread: Bool
    var beats: [Beat]
    var recap: Recap
}

/// The shareable hero. Designed, not generated.
struct Recap: Codable, Hashable {
    var episodeNumber: Int
    var headline: String            // display; one word goes magenta via `accentWord`
    var accentWord: String
    var pullQuote: String
    var attribution: String         // mono, e.g. "— maya, ep 04"
    var trendingName: String        // chyron value
    var narrative: String
    var highlights: [String]
    var gatedBeatIds: [String]
}

struct Relationship: Identifiable, Codable, Hashable {
    var id: String { "\(fromId)->\(toId)" }
    var fromId: String
    var toId: String
    var type: RelationshipType
    var affinity: Int               // -100…100
}

struct Agenda: Identifiable, Codable, Hashable {
    let id: String
    var doubleId: String
    var intentText: String
    var status: AgendaStatus
    var targetEpisode: Int
}

struct MarketOption: Codable, Hashable, Identifiable {
    var id: String { key }
    var key: String
    var label: String
    var multiplier: Double          // payout × on win
}

struct Market: Identifiable, Codable, Hashable {
    let id: String
    var question: String
    var options: [MarketOption]
    var status: MarketStatus
    var resolvesOnEpisode: Int
    var winningOption: String?
}

struct Bet: Identifiable, Codable, Hashable {
    let id: String
    var marketId: String
    var marketQuestion: String
    var optionLabel: String
    var stake: Int
    var status: BetStatus
    var potentialPayout: Int
}

struct SeasonScore: Identifiable, Codable, Hashable {
    var id: String { doubleId }
    var doubleId: String
    var drama: Int
    var ships: Int
    var glowup: Int
    var villain: Int
    var total: Int { drama + ships + glowup + villain }
}

enum AwardCategory: String, Codable, CaseIterable, Identifiable {
    case villain, bestCouple, biggestGlowup, mostDrama
    var id: String { rawValue }
    var title: String {
        switch self {
        case .villain: "villain of the season"
        case .bestCouple: "best couple"
        case .biggestGlowup: "biggest glow-up"
        case .mostDrama: "most drama"
        }
    }
    var symbol: String {
        switch self {
        case .villain: "theatermasks.fill"
        case .bestCouple: "heart.fill"
        case .biggestGlowup: "sparkles"
        case .mostDrama: "flame.fill"
        }
    }
}

struct Award: Identifiable, Codable, Hashable {
    var id: String { category.rawValue }
    var category: AwardCategory
    var leaderDoubleId: String
    var detail: String              // mono sub-line, e.g. "9 villain pts"
}

enum EntitlementSku: String, Codable {
    case subMonthly = "sub_monthly", seasonPass = "season_pass"
    case powerpack = "consumable_powerpack", cloutpack = "consumable_cloutpack"
}

struct Entitlement: Identifiable, Codable, Hashable {
    var id: String { sku.rawValue }
    var sku: EntitlementSku
    var active: Bool
}

/// Everything the Today hero needs in one fetch.
struct WorldSnapshot: Codable, Hashable {
    var world: World
    var myDouble: Persona
    var cast: [Persona]
    var episode: Episode
    var agenda: Agenda?
    var cloutBalance: Int
    var powerMovesRemaining: Int
}
