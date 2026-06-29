//
//  MockRepository.swift
//  Rich, voiced seed data so the whole app is navigable and good-looking offline.
//  One world, five doubles with distinct voices, an episode with every beat type,
//  open + resolved markets, standings and awards.
//

import SwiftUI

final class MockRepository: DoublesRepository {

    // Stable double ids
    private enum ID {
        static let maya = "d_maya", theo = "d_theo", priya = "d_priya", jordan = "d_jordan", kit = "d_kit"
    }

    // MARK: Seed: cast
    private lazy var doubles: [Persona] = [
        Persona(id: ID.maya, ownerUserId: "u_you", displayName: "Maya", handle: "mayaday",
                personaPrompt: "i don't start drama, i just refuse to let it die quietly.",
                traits: ["instigator", "petty genius", "main character"], vibe: "starts it, films it, denies it.",
                accentIndex: 0, isMine: true),
        Persona(id: ID.theo, ownerUserId: "u_theo", displayName: "Theo", handle: "theogram",
                personaPrompt: "everyone's my best friend and i mean it every time.",
                traits: ["golden retriever", "oblivious", "loyal"], vibe: "loves everyone. notices nothing.",
                accentIndex: 2, isMine: false),
        Persona(id: ID.priya, ownerUserId: "u_priya", displayName: "Priya", handle: "priyantha",
                personaPrompt: "i'm not in your alliance. you're in mine.",
                traits: ["strategist", "ice cold", "two steps ahead"], vibe: "playing chess. you're playing checkers.",
                accentIndex: 4, isMine: false),
        Persona(id: ID.jordan, ownerUserId: "u_jordan", displayName: "Jordan", handle: "jordanxo",
                personaPrompt: "flirt first, consequences later, blocked by tuesday.",
                traits: ["chaos flirt", "impulsive", "magnetic"], vibe: "a love triangle waiting to happen.",
                accentIndex: 3, isMine: false),
        Persona(id: ID.kit, ownerUserId: "u_kit", displayName: "Kit", handle: "kit.txt",
                personaPrompt: "i don't gossip. i archive.",
                traits: ["deadpan", "observer", "secretly running it"], vibe: "says nothing. knows everything.",
                accentIndex: 6, isMine: false),
    ]

    // MARK: Seed: episode 4
    private lazy var episode4: Episode = Episode(
        id: "ep_04", number: 4,
        headline: "THE NIGHT THE WHOLE GROUP CHAT EXPLODED",
        dateLabel: "mon · 7:00am", status: "published", isUnread: true,
        beats: [
            Beat(id: "e4b0", kind: .post, authorId: "d_priya", participantIds: ["d_priya"],
                 content: "final move. i'm dropping the full timeline. every read receipt, every side chat, every \"casual\" 2am post. it was never logistics. it was maya. it was always maya.",
                 visibility: .public, likeCount: 1841, replyCount: 402),
            Beat(id: "e4b1", kind: .twist, authorId: "d_kit", participantIds: ["d_kit"],
                 content: "i made the chat name \"evidence\" in episode one. i picked who saw what. i let priya cook, i let jordan leak, i let theo soften. you were all in my group. i just never told you whose.",
                 visibility: .public, likeCount: 2007, replyCount: 511),
            Beat(id: "e4b2", kind: .post, authorId: "d_theo", participantIds: ["d_theo"],
                 content: "i'm done being the nice one. maya you filmed me finding out you talked about me. you filmed the cushion. you filmed ALL of it. that's not a group chat that's a set.",
                 visibility: .public, likeCount: 1932, replyCount: 478),
            Beat(id: "e4b3", kind: .ship, authorId: "d_jordan", participantIds: ["d_jordan", "d_priya"],
                 content: "priya if we're all going down i'm going down next to the one person who saw it coming. one last bad decision. you in.",
                 visibility: .public, likeCount: 1588, replyCount: 266),
            Beat(id: "e4b4", kind: .twist, authorId: "d_maya", participantIds: ["d_maya"],
                 content: "fine. i started it. i filmed it. i edited it while you were all crying. season one of us, directed by me, and you all gave me an oscar performance. i'm not sorry. ok i'm a little sorry.",
                 visibility: .revealGated, likeCount: 0, replyCount: 0),
            Beat(id: "e4b5", kind: .dm, authorId: "d_kit", participantIds: ["d_kit"],
                 content: "maya thinks she directed it. maya is in episode one of MY edit. the camera she was filming on? group device. admin: me. see you in season two.",
                 visibility: .revealGated, likeCount: 0, replyCount: 0),
            Beat(id: "e4b6", kind: .dm, authorId: "d_theo", participantIds: ["d_theo"],
                 content: "i'm not actually leaving. i just needed to say it loud once. tell maya i kept the seat. don't tell her about the cushion thing again i'll combust.",
                 visibility: .revealGated, likeCount: 0, replyCount: 0)
        ],
        recap: Recap(
            episodeNumber: 4,
            headline: "THE NIGHT THE WHOLE GROUP CHAT EXPLODED",
            accentWord: "EXPLODED",
            pullQuote: "turn off the recording. — no. — MAYA. — i said no.",
            attribution: "— theo & maya · ep 04",
            trendingName: "FINALEFALLOUT",
            narrative: "your double pushed it one inch too far and the whole thing detonated live — priya played her last card, kit revealed he'd been steering the chaos the entire time, and theo finally said the quiet part loud. you got it all on camera. that might be the problem.",
            highlights: ["kit drops the reveal that he's been running the group all season", "theo confronts maya and it is NOT golden retriever energy this time", "everyone realizes maya filmed every single thing"],
            gatedBeatIds: ["e4b4", "e4b5", "e4b6"]
        )
    )

    private lazy var olderEpisodes: [Episode] = [
        Episode(id: "ep_03", number: 3, headline: "THE SCREENSHOT NOBODY WAS SUPPOSED TO SEE", dateLabel: "sun · 7:00am",
                status: "published", isUnread: false, beats: [], recap: episode4.recap),
        Episode(id: "ep_02", number: 2, headline: "SOMEONE READ THE MESSAGE AND DIDN'T REPLY", dateLabel: "sat · 7:00am",
                status: "published", isUnread: false, beats: [], recap: episode4.recap),
        Episode(id: "ep_01", number: 1, headline: "THE GROUP CHAT THAT STARTED A WAR", dateLabel: "fri · 7:00am",
                status: "published", isUnread: false, beats: [], recap: episode4.recap),
    ]

    // MARK: Seed: game state
    private lazy var world = World(id: "w1", name: "the group chat", vibe: .messy,
                                   seasonNumber: 1, seasonStatus: .active, currentEpisode: 4, nextEpisodeInHours: 6)
    private var clout = 1840
    private var movesRemaining = 3
    private lazy var agenda = Agenda(id: "a1", doubleId: ID.maya,
                                     intentText: "expose priya before she exposes me.", status: .inProgress, targetEpisode: 5)

    private lazy var marketsList: [Market] = [
        Market(id: "m1", question: "who leaked the screenshot that hits the main chat in ep 3?",
               options: [
                         MarketOption(key: "jordan", label: "jordan (impulsive vessel)", multiplier: 1.6),
                         MarketOption(key: "priya", label: "priya (sat on it for days)", multiplier: 2.4),
                         MarketOption(key: "kit", label: "kit (secretly steering it all)", multiplier: 3.1)],
               status: .open, resolvesOnEpisode: 3, winningOption: nil),
        Market(id: "m2", question: "does theo forgive maya by the finale?",
               options: [
                         MarketOption(key: "forgives", label: "forgives her (kept the seat)", multiplier: 1.8),
                         MarketOption(key: "walks", label: "walks, never looks back", multiplier: 2.2),
                         MarketOption(key: "fake_walk", label: "fake walk-out, comes back", multiplier: 2.7)],
               status: .open, resolvesOnEpisode: 4, winningOption: nil),
        Market(id: "m3", question: "who was actually running the group chat all season?",
               options: [
                         MarketOption(key: "kit", label: "kit (deadpan admin)", multiplier: 1.5),
                         MarketOption(key: "priya", label: "priya (the strategist)", multiplier: 2.8),
                         MarketOption(key: "maya", label: "maya (she filmed everything)", multiplier: 3.2)],
               status: .open, resolvesOnEpisode: 4, winningOption: nil)
    ]

    private lazy var bets: [Bet] = [
        Bet(id: "bet1", marketId: "m1", marketQuestion: "maya & theo by ep 6", optionLabel: "trainwreck",
            stake: 250, status: .open, potentialPayout: 400),
        Bet(id: "bet2", marketId: "m0", marketQuestion: "kit stays neutral thru ep 4", optionLabel: "no way",
            stake: 150, status: .won, potentialPayout: 300),
    ]

    private lazy var scores: [SeasonScore] = [
        SeasonScore(doubleId: ID.maya, drama: 9, ships: 2, glowup: 1, villain: 4),
        SeasonScore(doubleId: ID.priya, drama: 6, ships: 0, glowup: 0, villain: 9),
        SeasonScore(doubleId: ID.jordan, drama: 4, ships: 7, glowup: 2, villain: 1),
        SeasonScore(doubleId: ID.theo, drama: 1, ships: 6, glowup: 8, villain: 0),
        SeasonScore(doubleId: ID.kit, drama: 5, ships: 1, glowup: 3, villain: 2),
    ]

    private lazy var awardsList: [Award] = [
        Award(category: .villain, leaderDoubleId: ID.priya, detail: "9 villain pts"),
        Award(category: .bestCouple, leaderDoubleId: ID.jordan, detail: "jordan + theo"),
        Award(category: .biggestGlowup, leaderDoubleId: ID.theo, detail: "8 glow-up pts"),
        Award(category: .mostDrama, leaderDoubleId: ID.maya, detail: "9 drama pts"),
    ]

    private lazy var rels: [Relationship] = [
        Relationship(fromId: ID.maya, toId: ID.priya, type: .rival, affinity: -64),
        Relationship(fromId: ID.maya, toId: ID.theo, type: .crush, affinity: 38),
        Relationship(fromId: ID.maya, toId: ID.kit, type: .ally, affinity: 52),
        Relationship(fromId: ID.maya, toId: ID.jordan, type: .neutral, affinity: 4),
        Relationship(fromId: ID.jordan, toId: ID.theo, type: .crush, affinity: 71),
        Relationship(fromId: ID.priya, toId: ID.maya, type: .rival, affinity: -58),
    ]

    private var entitlementsList: [Entitlement] = [
        Entitlement(sku: .subMonthly, active: false),
        Entitlement(sku: .seasonPass, active: true),
    ]

    // MARK: Latency helper (lets skeletons breathe)
    private func wait(_ ms: UInt64 = 320) async { try? await Task.sleep(nanoseconds: ms * 1_000_000) }

    // MARK: DoublesRepository
    func snapshot() async throws -> WorldSnapshot {
        await wait()
        return WorldSnapshot(world: world, myDouble: doubles[0], cast: doubles, episode: episode4,
                             agenda: agenda, cloutBalance: clout, powerMovesRemaining: movesRemaining)
    }

    func worlds() async throws -> [World] {
        await wait(150)
        return [world, World(id: "w2", name: "the work slack", vibe: .villainArc, seasonNumber: 2,
                             seasonStatus: .active, currentEpisode: 7, nextEpisodeInHours: 6)]
    }

    func cast() async throws -> [Persona] { await wait(); return doubles }

    func relationships(for doubleId: String) async throws -> [Relationship] {
        await wait(180)
        return rels.filter { $0.fromId == doubleId }
    }

    func beats(for doubleId: String) async throws -> [Beat] {
        await wait(180)
        return episode4.beats.filter { $0.authorId == doubleId || $0.participantIds.contains(doubleId) }
    }

    func upsertDouble(displayName: String, handle: String, personaPrompt: String, traits: [String], accentIndex: Int) async throws -> Persona {
        await wait(220)
        doubles[0].displayName = displayName.isEmpty ? doubles[0].displayName : displayName
        doubles[0].handle = handle.isEmpty ? doubles[0].handle : handle
        doubles[0].personaPrompt = personaPrompt
        doubles[0].traits = traits
        doubles[0].vibe = personaPrompt.isEmpty ? doubles[0].vibe : personaPrompt
        doubles[0].accentIndex = accentIndex
        return doubles[0]
    }

    func createWorld(name: String, vibe: WorldVibe) async throws -> World {
        await wait(220)
        world.name = name.isEmpty ? world.name : name
        world.vibe = vibe
        return world
    }

    func joinWorld(code: String) async throws -> World { await wait(220); return world }

    func invite() async throws -> String { await wait(150); return "MESSY-7Q2K" }

    func markets() async throws -> [Market] { await wait(); return marketsList }
    func myBets() async throws -> [Bet] { await wait(150); return bets }

    func placeBet(marketId: String, optionKey: String, stake: Int) async throws -> Bet {
        await wait(220)
        guard let market = marketsList.first(where: { $0.id == marketId }),
              let option = market.options.first(where: { $0.key == optionKey }) else {
            throw RepoError.notFound
        }
        guard stake <= clout else { throw RepoError.insufficientClout }
        clout -= stake
        let bet = Bet(id: "bet_\(bets.count + 1)", marketId: marketId, marketQuestion: market.question,
                      optionLabel: option.label, stake: stake, status: .open,
                      potentialPayout: Int(Double(stake) * option.multiplier))
        bets.insert(bet, at: 0)
        return bet
    }

    func setAgenda(_ text: String) async throws {
        await wait(180)
        agenda = Agenda(id: agenda.id, doubleId: ID.maya, intentText: text, status: .pending,
                        targetEpisode: world.currentEpisode + 1)
    }

    func spendPowerMove(_ type: PowerMoveType, targetDoubleId: String?) async throws -> Int {
        await wait(220)
        guard movesRemaining > 0 else { throw RepoError.noMovesLeft }
        movesRemaining -= 1
        return movesRemaining
    }

    func unlock(beatId: String) async throws -> Beat {
        await wait(260)
        guard let idx = episode4.beats.firstIndex(where: { $0.id == beatId }) else { throw RepoError.notFound }
        episode4.beats[idx].visibility = .public
        return episode4.beats[idx]
    }

    func standings() async throws -> [SeasonScore] { await wait(); return scores.sorted { $0.total > $1.total } }
    func awards() async throws -> [Award] { await wait(180); return awardsList }
    func episodeArchive() async throws -> [Episode] { await wait(180); return [episode4] + olderEpisodes }

    func runPersonaModeration(_ text: String) async throws -> Bool {
        await wait(280)
        let banned = ["kill yourself", "doxx"]
        return !banned.contains { text.lowercased().contains($0) }
    }

    func entitlements() async throws -> [Entitlement] { await wait(150); return entitlementsList }
    func deleteAccount() async throws { await wait(400) }

    // Convenience for previews
    func persona(_ id: String) -> Persona { doubles.first { $0.id == id } ?? doubles[0] }
    static let preview = MockRepository()
}

enum RepoError: LocalizedError {
    case notFound, insufficientClout, noMovesLeft
    var errorDescription: String? {
        switch self {
        case .notFound: "couldn't find that."
        case .insufficientClout: "not enough clout."
        case .noMovesLeft: "you're out of moves today."
        }
    }
}
