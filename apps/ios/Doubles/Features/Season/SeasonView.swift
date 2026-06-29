//
//  SeasonView.swift
//  The league table. Standings leaderboard, awards-in-progress, a finale countdown,
//  and the episode archive. When the season hits its finale, the awards-show moment
//  (FinaleView) takes over — the most shareable artifact in the app.
//

import SwiftUI

@Observable
@MainActor
final class SeasonViewModel {
    enum Phase { case loading, loaded, error }
    var phase: Phase = .loading
    var standings: [SeasonScore] = []
    var awards: [Award] = []
    var archive: [Episode] = []
    var cast: [Persona] = []
    var world: World?

    func load(_ repo: any DoublesRepository, initial: Bool = true) async {
        if initial { phase = .loading }
        do {
            async let s = repo.standings()
            async let a = repo.awards()
            async let e = repo.episodeArchive()
            async let c = repo.cast()
            async let snap = repo.snapshot()
            let (standings, awards, archive, cast, snapshot) = try await (s, a, e, c, snap)
            self.standings = standings
            self.awards = awards
            self.archive = archive
            self.cast = cast
            self.world = snapshot.world
            phase = .loaded
        } catch {
            phase = .error
        }
    }

    func persona(_ id: String) -> Persona? { cast.first { $0.id == id } }
    func rank(of doubleId: String) -> Int? {
        standings.firstIndex { $0.doubleId == doubleId }.map { $0 + 1 }
    }
}

struct SeasonView: View {
    @Environment(\.repo) private var repo
    @State private var vm = SeasonViewModel()

    var body: some View {
        NavigationStack {
            ScreenBackground {
                content
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("season").font(.ui(15, .bold)).foregroundStyle(DS.bone)
                        .accessibilityLabel("season")
                }
            }
            .toolbarBackground(DS.wine, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task { await vm.load(repo) }
    }

    @ViewBuilder private var content: some View {
        switch vm.phase {
        case .loading:
            ScrollView { FeedSkeleton().padding(DS.Space.l) }
        case .error:
            ErrorStateView { Task { await vm.load(repo) } }
        case .loaded:
            if vm.world?.seasonStatus == .finale {
                FinaleView(awards: vm.awards, persona: vm.persona, world: vm.world)
            } else {
                loaded
            }
        }
    }

    private var loaded: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {
                if let world = vm.world {
                    Chyron(label: "season \(world.seasonNumber)", value: world.name.uppercased())
                }
                countdown
                standingsBlock
                awardsBlock
                archiveBlock
            }
            .padding(DS.Space.l)
            .padding(.bottom, DS.Space.xxxl)
        }
        .refreshable { await vm.load(repo, initial: false) }
    }

    // MARK: countdown
    private var countdown: some View {
        HStack(spacing: DS.Space.m) {
            Image(systemName: "trophy.fill").font(.system(size: 18)).foregroundStyle(DS.acid)
            VStack(alignment: .leading, spacing: 1) {
                Text("finale in 9 days").font(.ui(15, .semibold)).foregroundStyle(DS.bone)
                Text("standings lock when the credits roll.").font(.ui(12)).foregroundStyle(DS.boneDim)
            }
            Spacer()
        }
        .padding(DS.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.surface)
        .overlay(alignment: .leading) { Rectangle().fill(DS.acid).frame(width: 3) }
        .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
    }

    // MARK: standings
    private var standingsBlock: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionLabel(text: "standings", trailing: "ep \(String(format: "%02d", vm.world?.currentEpisode ?? 0))")
            VStack(spacing: DS.Space.s) {
                ForEach(Array(vm.standings.enumerated()), id: \.element.id) { index, score in
                    standingRow(rank: index + 1, score: score)
                }
            }
        }
    }

    private func standingRow(rank: Int, score: SeasonScore) -> some View {
        let persona = vm.persona(score.doubleId)
        return HStack(spacing: DS.Space.m) {
            Text("\(rank)").font(.display(26))
                .foregroundStyle(rank == 1 ? DS.acid : DS.boneDim)
                .frame(width: 34, alignment: .leading)
                .accessibilityLabel("rank \(rank)")
            if let persona { DoubleAvatar(persona: persona, size: 40) }
            VStack(alignment: .leading, spacing: 4) {
                Text(persona?.displayName ?? "—").font(.ui(15, .semibold)).foregroundStyle(DS.bone)
                HStack(spacing: DS.Space.xs) {
                    StatPill(label: "drama", value: score.drama, tint: DS.magenta)
                    StatPill(label: "ships", value: score.ships, tint: DS.acid)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(score.total)").font(.mono(22, bold: true)).foregroundStyle(DS.bone)
                Text("total").monoLabel(8, tracking: 1.5).foregroundStyle(DS.boneDim)
            }
        }
        .padding(DS.Space.m)
        .background(DS.surface)
        .overlay(alignment: .leading) {
            Rectangle().fill(rank == 1 ? DS.acid : (persona?.accent ?? DS.line)).frame(width: 3)
        }
        .overlay(Rectangle().stroke(rank == 1 ? DS.acid.opacity(0.5) : DS.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("rank \(rank), \(persona?.displayName ?? "unknown"), \(score.total) points")
    }

    // MARK: awards
    private var awardsBlock: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionLabel(text: "awards in progress", trailing: "live")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: DS.Space.m),
                                GridItem(.flexible(), spacing: DS.Space.m)], spacing: DS.Space.m) {
                ForEach(vm.awards) { award in awardCard(award) }
            }
        }
    }

    private func awardCard(_ award: Award) -> some View {
        let leader = vm.persona(award.leaderDoubleId)
        return VStack(alignment: .leading, spacing: DS.Space.s) {
            HStack {
                Image(systemName: award.category.symbol).font(.system(size: 16)).foregroundStyle(DS.magenta)
                Spacer()
                if let leader { DoubleAvatar(persona: leader, size: 32) }
            }
            Text(award.category.title).font(.ui(13, .bold)).foregroundStyle(DS.bone)
                .fixedSize(horizontal: false, vertical: true)
            Text(leader?.displayName.lowercased() ?? "tbd").monoLabel(11, bold: true, tracking: 1.5)
                .foregroundStyle(DS.acid)
            Text(award.detail).monoLabel(9, tracking: 1).foregroundStyle(DS.boneDim)
        }
        .padding(DS.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.surface)
        .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(award.category.title), leader \(leader?.displayName ?? "tbd"), \(award.detail)")
    }

    // MARK: archive
    private var archiveBlock: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionLabel(text: "episode archive", trailing: "\(vm.archive.count)")
            VStack(spacing: DS.Space.s) {
                ForEach(vm.archive) { episode in archiveRow(episode) }
            }
        }
    }

    private func archiveRow(_ episode: Episode) -> some View {
        HStack(spacing: DS.Space.m) {
            Text("EP \(String(format: "%02d", episode.number))")
                .monoLabel(11, bold: true, tracking: 2).foregroundStyle(DS.acid)
                .frame(width: 52, alignment: .leading)
                .accessibilityLabel("episode \(episode.number)")
            VStack(alignment: .leading, spacing: 2) {
                Text(episode.headline).font(.ui(14, .semibold)).foregroundStyle(DS.bone)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                Text(episode.dateLabel).monoLabel(9, tracking: 1.5).foregroundStyle(DS.boneDim)
            }
            Spacer()
            if episode.isUnread {
                Text("new").monoLabel(8, bold: true).foregroundStyle(DS.ink)
                    .padding(.horizontal, DS.Space.s).padding(.vertical, 3).background(DS.acid)
            }
        }
        .padding(DS.Space.m)
        .background(DS.surface)
        .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("episode \(episode.number), \(episode.headline.lowercased()), \(episode.dateLabel)")
    }
}

// MARK: - FinaleView
//
// The awards-show payoff. Built to be screenshotted and shared.

struct FinaleView: View {
    var awards: [Award]
    var persona: (String) -> Persona?
    var world: World?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {
                VStack(alignment: .leading, spacing: DS.Space.s) {
                    Chyron(label: "that's a wrap", value: world?.name.uppercased() ?? "DOUBLES", fill: DS.acid)
                    Text("SEASON \(world?.seasonNumber ?? 1) WRAPPED")
                        .font(.display(46)).foregroundStyle(DS.bone)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("season \(world?.seasonNumber ?? 1) wrapped")
                    Text("here's who ran it.").font(.ui(16)).foregroundStyle(DS.boneDim)
                }

                VStack(spacing: DS.Space.m) {
                    ForEach(awards) { award in winnerCard(award) }
                }

                PrimaryButton(title: "share the finale", icon: "square.and.arrow.up", fill: DS.acid) {
                    Haptics.success()
                }

                Text("the doubles are ai. the bragging rights are real.")
                    .font(.ui(12)).foregroundStyle(DS.boneDim)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(DS.Space.l)
            .padding(.bottom, DS.Space.xxxl)
        }
    }

    private func winnerCard(_ award: Award) -> some View {
        let winner = persona(award.leaderDoubleId)
        return VStack(alignment: .leading, spacing: DS.Space.m) {
            Chyron(label: "winner", value: award.category.title.uppercased())
            HStack(spacing: DS.Space.m) {
                if let winner { DoubleAvatar(persona: winner, size: 60) }
                VStack(alignment: .leading, spacing: 2) {
                    Text(winner?.displayName ?? "—").font(.display(28)).foregroundStyle(DS.bone)
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .accessibilityLabel(winner?.displayName ?? "unknown")
                    Text(award.detail).monoLabel(10, bold: true, tracking: 1.5).foregroundStyle(DS.acid)
                }
                Spacer()
                Image(systemName: award.category.symbol).font(.system(size: 26)).foregroundStyle(DS.magenta)
            }
        }
        .padding(DS.Space.l)
        .background(DS.surface)
        .overlay(Rectangle().stroke(DS.magenta.opacity(0.5), lineWidth: 1))
        .shadow(color: DS.magenta.opacity(0.2), radius: 16, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(award.category.title) winner: \(winner?.displayName ?? "unknown"), \(award.detail)")
    }
}

#Preview("Season") {
    SeasonView().environment(\.repo, MockRepository.preview).preferredColorScheme(.dark)
}

#Preview("Finale") {
    ScreenBackground {
        FinaleView(awards: [
            Award(category: .villain, leaderDoubleId: "d_priya", detail: "9 villain pts"),
            Award(category: .bestCouple, leaderDoubleId: "d_jordan", detail: "jordan + theo"),
            Award(category: .biggestGlowup, leaderDoubleId: "d_theo", detail: "8 glow-up pts"),
            Award(category: .mostDrama, leaderDoubleId: "d_maya", detail: "9 drama pts"),
        ], persona: { MockRepository.preview.persona($0) },
        world: World(id: "w1", name: "the group chat", vibe: .messy, seasonNumber: 1,
                     seasonStatus: .finale, currentEpisode: 10, nextEpisodeInHours: nil))
    }
    .environment(\.repo, MockRepository.preview)
    .preferredColorScheme(.dark)
}
