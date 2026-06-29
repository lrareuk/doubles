//
//  APIRepository.swift
//  Live implementation of DoublesRepository against apps/api (Next.js) + Supabase.
//  Maps the wire shapes (packages/shared) into the iOS UI models, synthesising the
//  tabloid recap fields and computing awards client-side from standings.
//

import Foundation

enum APIError: LocalizedError {
    case http(Int, String?)
    case noWorld
    case decoding(String)
    var errorDescription: String? {
        switch self {
        case .http(_, let m): m ?? "the server hiccuped."
        case .noWorld: "you're not in a world yet."
        case .decoding(let m): "couldn't read that. (\(m))"
        }
    }
}

final class APIRepository: DoublesRepository {
    private let token: String
    private let userId: String
    private let base = Config.apiBaseURL
    private var cachedWorldId: String?

    init(token: String, userId: String) {
        self.token = token
        self.userId = userId
    }

    // MARK: HTTP
    private func request<T: Decodable>(_ path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> T {
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        if let body { req.httpBody = try JSONSerialization.data(withJSONObject: body) }

        let (data, response) = try await URLSession.shared.data(for: req)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(code) else {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
            throw APIError.http(code, msg)
        }
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw APIError.decoding(String(describing: error)) }
    }

    private func worldId() async throws -> String {
        if let id = cachedWorldId { return id }
        let env: WorldsEnvelope = try await request("me/worlds")
        guard let first = env.worlds.first else { throw APIError.noWorld }
        cachedWorldId = first.id
        return first.id
    }

    // MARK: snapshot
    func snapshot() async throws -> WorldSnapshot {
        let id = try await worldId()
        async let stateReq: WorldStateDTO = request("worlds/\(id)")
        async let recapReq: RecapEnvelope = request("worlds/\(id)/recap/latest")
        let state = try await stateReq
        let cast = state.standings.map { mapPersona($0.double) }
        let me = state.myDouble.map(mapPersona) ?? cast.first { $0.isMine } ?? cast.first!

        let epNumber = max(1, state.world.currentEpisode)
        let epView: EpisodeViewDTO = try await request("worlds/\(id)/episodes/\(epNumber)")
        let recap = (try? await recapReq)?.recap

        let beats = epView.beats.map(mapBeat)
        let episode = Episode(
            id: "ep_\(epView.number)", number: epView.number,
            headline: (epView.headline ?? "tonight in \(state.world.name)").uppercased(),
            dateLabel: "ep \(String(format: "%02d", epView.number))",
            status: epView.status, isUnread: true,
            beats: beats,
            recap: mapRecap(recap, episode: epView, standings: state.standings))
        return WorldSnapshot(world: mapWorld(state.world), myDouble: me, cast: cast,
                             episode: episode, agenda: nil,
                             cloutBalance: state.cloutBalance, powerMovesRemaining: state.powerMovesRemaining)
    }

    func worlds() async throws -> [World] {
        let env: WorldsEnvelope = try await request("me/worlds")
        return env.worlds.map(mapWorld)
    }

    func cast() async throws -> [Persona] {
        let id = try await worldId()
        let state: WorldStateDTO = try await request("worlds/\(id)")
        return state.standings.map { mapPersona($0.double) }
    }

    func relationships(for doubleId: String) async throws -> [Relationship] {
        let id = try await worldId()
        let env: RelationshipsEnvelope = try await request("worlds/\(id)/relationships")
        return env.relationships
            .filter { $0.fromDoubleId == doubleId }
            .map { Relationship(fromId: $0.fromDoubleId, toId: $0.toDoubleId,
                                type: RelationshipType(rawValue: $0.type) ?? .neutral, affinity: $0.affinity) }
    }

    func beats(for doubleId: String) async throws -> [Beat] {
        let snap = try await snapshot()
        return snap.episode.beats.filter { $0.authorId == doubleId || $0.participantIds.contains(doubleId) }
    }

    func upsertDouble(displayName: String, handle: String, personaPrompt: String, traits: [String], accentIndex: Int) async throws -> Persona {
        var traitMap: [String: Any] = Dictionary(uniqueKeysWithValues: traits.map { ($0, true) })
        traitMap["_accent"] = accentIndex
        let env: DoubleEnvelope = try await request("doubles", method: "POST", body: [
            "displayName": displayName, "handle": handle, "personaPrompt": personaPrompt,
            "traits": traitMap, "avatarSeed": handle,
        ])
        guard let d = env.double else { throw APIError.decoding("no double in response") }
        return mapPersona(d)
    }

    func createWorld(name: String, vibe: WorldVibe) async throws -> World {
        let env: WorldEnvelope = try await request("worlds", method: "POST", body: ["name": name, "vibe": vibe.rawValue])
        cachedWorldId = env.world.id
        return mapWorld(env.world)
    }

    func joinWorld(code: String) async throws -> World {
        // The join route resolves the world from the token; the path id is ignored.
        let env: WorldEnvelope = try await request("worlds/join/join", method: "POST", body: ["token": code])
        cachedWorldId = env.world.id
        return mapWorld(env.world)
    }

    func invite() async throws -> String {
        let id = try await worldId()
        let env: InviteEnvelope = try await request("worlds/\(id)/invite", method: "POST", body: [:])
        return env.token
    }

    func markets() async throws -> [Market] {
        let id = try await worldId()
        let env: MarketsEnvelope = try await request("worlds/\(id)/markets")
        return env.markets.map(mapMarket)
    }

    func myBets() async throws -> [Bet] {
        let id = try await worldId()
        let env: BetsEnvelope = try await request("worlds/\(id)/bets")
        return env.bets.map {
            Bet(id: $0.id, marketId: $0.marketId, marketQuestion: $0.marketQuestion,
                optionLabel: $0.optionLabel, stake: $0.stake,
                status: BetStatus(rawValue: $0.status) ?? .open, potentialPayout: $0.potentialPayout)
        }
    }

    func placeBet(marketId: String, optionKey: String, stake: Int) async throws -> Bet {
        let id = try await worldId()
        let _: BetPlacedEnvelope = try await request(
            "worlds/\(id)/bets", method: "POST",
            body: ["marketId": marketId, "optionKey": optionKey, "stakeClout": stake])
        // Re-read for the enriched display shape.
        let mine = try await myBets()
        return mine.first ?? Bet(id: UUID().uuidString, marketId: marketId, marketQuestion: "",
                                 optionLabel: optionKey, stake: stake, status: .open, potentialPayout: stake * 2)
    }

    func setAgenda(_ text: String) async throws {
        let id = try await worldId()
        let _: OkEnvelope = try await request("worlds/\(id)/agenda", method: "POST", body: ["intentText": text])
    }

    func spendPowerMove(_ type: PowerMoveType, targetDoubleId: String?) async throws -> Int {
        let id = try await worldId()
        var body: [String: Any] = ["type": type.rawValue]
        if let targetDoubleId { body["targetDoubleId"] = targetDoubleId }
        let env: PowerMoveEnvelope = try await request("worlds/\(id)/power-moves", method: "POST", body: body)
        return env.powerMovesRemaining
    }

    func unlock(beatId: String) async throws -> Beat {
        let env: BeatEnvelope = try await request("reveals/\(beatId)/unlock", method: "POST", body: [:])
        let b = env.beat
        return Beat(id: b.id, kind: BeatKind(rawValue: b.kind) ?? .dm,
                    authorId: b.participantDoubleIds.first ?? "",
                    participantIds: b.participantDoubleIds, content: b.content ?? "",
                    visibility: .public, likeCount: 0, replyCount: 0)
    }

    func standings() async throws -> [SeasonScore] {
        let id = try await worldId()
        let env: ScoresEnvelope = try await request("worlds/\(id)/scores")
        return env.standings.compactMap { s in
            guard let sc = s.score else { return SeasonScore(doubleId: s.double.id, drama: 0, ships: 0, glowup: 0, villain: 0) }
            return SeasonScore(doubleId: s.double.id, drama: sc.drama, ships: sc.ships, glowup: sc.glowup, villain: sc.villain)
        }.sorted { $0.total > $1.total }
    }

    func awards() async throws -> [Award] {
        let id = try await worldId()
        let state: WorldStateDTO = try await request("worlds/\(id)")
        let scored = state.standings.compactMap { s -> (Persona, SeasonScore)? in
            guard let sc = s.score else { return nil }
            return (mapPersona(s.double), SeasonScore(doubleId: s.double.id, drama: sc.drama, ships: sc.ships, glowup: sc.glowup, villain: sc.villain))
        }
        var out: [Award] = []
        if let v = scored.filter({ $0.1.villain > 0 }).max(by: { $0.1.villain < $1.1.villain }) {
            out.append(Award(category: .villain, leaderDoubleId: v.0.id, detail: "\(v.1.villain) villain pts"))
        }
        if let c = scored.filter({ $0.1.ships > 0 }).max(by: { $0.1.ships < $1.1.ships }) {
            out.append(Award(category: .bestCouple, leaderDoubleId: c.0.id, detail: "\(c.1.ships) ship pts"))
        }
        if let g = scored.filter({ $0.1.glowup > 0 }).max(by: { $0.1.glowup < $1.1.glowup }) {
            out.append(Award(category: .biggestGlowup, leaderDoubleId: g.0.id, detail: "\(g.1.glowup) glow-up pts"))
        }
        if let d = scored.filter({ $0.1.drama > 0 }).max(by: { $0.1.drama < $1.1.drama }) {
            out.append(Award(category: .mostDrama, leaderDoubleId: d.0.id, detail: "\(d.1.drama) drama pts"))
        }
        return out
    }

    func episodeArchive() async throws -> [Episode] {
        let id = try await worldId()
        let state: WorldStateDTO = try await request("worlds/\(id)")
        let top = max(1, state.world.currentEpisode)
        let low = max(1, top - 4)
        var episodes: [Episode] = []
        for n in stride(from: top, through: low, by: -1) {
            if let ev: EpisodeViewDTO = try? await request("worlds/\(id)/episodes/\(n)") {
                episodes.append(Episode(id: "ep_\(ev.number)", number: ev.number,
                                        headline: (ev.headline ?? "episode \(ev.number)").uppercased(),
                                        dateLabel: "ep \(String(format: "%02d", ev.number))",
                                        status: ev.status, isUnread: false,
                                        beats: ev.beats.map(mapBeat),
                                        recap: mapRecap(nil, episode: ev, standings: state.standings)))
            }
        }
        return episodes
    }

    func runPersonaModeration(_ text: String) async throws -> Bool { true } // server enforces on create

    /// Start a Veriff age-estimation session; returns the hosted URL to present.
    func startAgeVerification() async throws -> URL {
        let env: AgeStartEnvelope = try await request("me/age-verify/start", method: "POST", body: [:])
        guard let url = URL(string: env.url) else { throw APIError.decoding("bad age-verify url") }
        return url
    }

    /// Whether the server has confirmed the caller is 18+ (set only by the
    /// HMAC-verified Veriff webhook — the client can never self-assert age).
    func ageVerified() async throws -> Bool {
        let env: AgeStatusEnvelope = try await request("me/age-verify")
        return env.ageVerified
    }

    /// Register the APNs device token for morning-recap push (idempotent).
    func registerPushToken(_ token: String) async throws {
        let _: OkEnvelope = try await request("me/push-token", method: "POST",
                                              body: ["token": token, "platform": "ios"])
    }

    func entitlements() async throws -> [Entitlement] {
        let env: EntitlementsEnvelope = try await request("me/entitlements")
        return env.entitlements.compactMap {
            guard let sku = EntitlementSku(rawValue: $0.sku) else { return nil }
            return Entitlement(sku: sku, active: $0.status == "active")
        }
    }

    func deleteAccount() async throws {
        let _: OkDeleteEnvelope = try await request("doubles/me", method: "DELETE")
    }

    // MARK: mapping
    private func mapPersona(_ d: DoubleDTO) -> Persona {
        let hash = d.id.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return Persona(id: d.id, ownerUserId: d.ownerUserId, displayName: d.displayName, handle: d.handle,
                       personaPrompt: d.personaPrompt, traits: [], vibe: d.personaPrompt,
                       accentIndex: hash % 8, isMine: d.ownerUserId == userId)
    }

    private func mapWorld(_ w: WorldDTO) -> World {
        World(id: w.id, name: w.name, vibe: WorldVibe(rawValue: w.vibe) ?? .messy,
              seasonNumber: w.seasonNumber, seasonStatus: SeasonStatus(rawValue: w.seasonStatus) ?? .active,
              currentEpisode: w.currentEpisode, nextEpisodeInHours: nil)
    }

    private func mapBeat(_ b: BeatDTO) -> Beat {
        Beat(id: b.id, kind: BeatKind(rawValue: b.kind) ?? .post,
             authorId: b.participantDoubleIds.first ?? "",
             participantIds: b.participantDoubleIds, content: b.content ?? "",
             visibility: b.locked ? .revealGated : .public,
             likeCount: 0, replyCount: 0)
    }

    private func mapMarket(_ m: MarketDTO) -> Market {
        Market(id: m.id, question: m.question,
               options: m.options.map { MarketOption(key: $0.key, label: $0.label, multiplier: m.multiplier) },
               status: MarketStatus(rawValue: m.status) ?? .open,
               resolvesOnEpisode: m.resolvesOnEpisode, winningOption: m.winningOption)
    }

    private func mapRecap(_ r: RecapDTO?, episode: EpisodeViewDTO, standings: [StandingDTO]) -> Recap {
        let headline = (episode.headline ?? "tonight in the group chat").uppercased()
        let accent = headline.components(separatedBy: " ").max(by: { $0.count < $1.count }) ?? headline
        let topName = standings.first?.double.displayName ?? "the cast"
        let topHandle = standings.first?.double.handle ?? "doubles"
        let firstPublic = episode.beats.first { !$0.locked }?.content
        let quote = firstPublic ?? r?.highlights.first ?? "it all kicked off tonight."
        return Recap(episodeNumber: episode.number, headline: headline, accentWord: accent,
                     pullQuote: "“\(quote)”", attribution: "— \(topHandle) · ep \(String(format: "%02d", episode.number))",
                     trendingName: topName.uppercased(),
                     narrative: r?.narrative ?? "your double was right in the middle of it.",
                     highlights: r?.highlights ?? [], gatedBeatIds: r?.gatedBeatIds ?? [])
    }
}

// MARK: - Wire DTOs (decoded from the API; camelCase)

private struct WorldsEnvelope: Decodable { let worlds: [WorldDTO] }
private struct RelationshipsEnvelope: Decodable { let relationships: [RelationshipDTO] }
private struct MarketsEnvelope: Decodable { let markets: [MarketDTO] }
private struct BetsEnvelope: Decodable { let bets: [BetDTO] }
private struct BetPlacedEnvelope: Decodable { let bet: SharedBetDTO }
private struct ScoresEnvelope: Decodable { let standings: [StandingDTO] }
private struct RecapEnvelope: Decodable { let recap: RecapDTO? }
private struct EntitlementsEnvelope: Decodable { let entitlements: [EntitlementDTO] }
private struct InviteEnvelope: Decodable { let token: String }
private struct DoubleEnvelope: Decodable { let double: DoubleDTO? }
private struct WorldEnvelope: Decodable { let world: WorldDTO }
private struct PowerMoveEnvelope: Decodable { let ok: Bool; let powerMovesRemaining: Int }
private struct OkEnvelope: Decodable { let ok: Bool }
private struct OkDeleteEnvelope: Decodable { let deleted: Bool }
private struct BeatEnvelope: Decodable { let beat: SharedBeatDTO }

private struct WorldDTO: Decodable {
    let id, name, vibe, seasonStatus: String
    let seasonNumber, currentEpisode: Int
}
private struct DoubleDTO: Decodable {
    let id, ownerUserId, displayName, handle, personaPrompt: String
}
private struct ScoreDTO: Decodable { let doubleId: String; let drama, ships, glowup, villain: Int }
private struct StandingDTO: Decodable { let double: DoubleDTO; let score: ScoreDTO? }
private struct WorldStateDTO: Decodable {
    let world: WorldDTO
    let myDouble: DoubleDTO?
    let standings: [StandingDTO]
    let cloutBalance, powerMovesRemaining: Int
}
private struct BeatDTO: Decodable {
    let id, kind, visibility: String
    let participantDoubleIds: [String]
    let content: String?
    let locked: Bool
}
private struct EpisodeViewDTO: Decodable {
    let number: Int
    let status: String
    let headline: String?
    let beats: [BeatDTO]
}
private struct RecapDTO: Decodable { let narrative: String; let highlights: [String]; let gatedBeatIds: [String] }
private struct MarketOptionDTO: Decodable { let key, label: String }
private struct MarketDTO: Decodable {
    let id, question, status: String
    let options: [MarketOptionDTO]
    let resolvesOnEpisode: Int
    let multiplier: Double
    let winningOption: String?
}
private struct BetDTO: Decodable {
    let id, marketId, marketQuestion, optionLabel, status: String
    let stake, potentialPayout: Int
}
private struct SharedBetDTO: Decodable { let id: String }
private struct SharedBeatDTO: Decodable {
    let id, kind: String
    let participantDoubleIds: [String]
    let content: String?
}
private struct RelationshipDTO: Decodable {
    let fromDoubleId, toDoubleId, type: String
    let affinity: Int
}
private struct EntitlementDTO: Decodable { let sku, status: String }
private struct AgeStartEnvelope: Decodable { let url: String; let id: String }
private struct AgeStatusEnvelope: Decodable { let ageVerified: Bool }
