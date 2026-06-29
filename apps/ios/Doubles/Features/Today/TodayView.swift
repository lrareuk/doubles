//
//  TodayView.swift
//  The hero. Opening this in the morning should feel like opening a group chat
//  that has been popping off all night — except the cast is AI versions of friends.
//

import SwiftUI

@Observable
@MainActor
final class TodayViewModel {
    enum Phase { case loading, loaded, empty, error }
    var phase: Phase = .loading
    var snapshot: WorldSnapshot?

    func load(_ repo: any DoublesRepository, initial: Bool = true) async {
        if initial { phase = .loading }
        do {
            let snap = try await repo.snapshot()
            snapshot = snap
            phase = snap.episode.beats.isEmpty ? .empty : .loaded
        } catch {
            phase = .error
        }
    }

    func unlock(_ beatId: String, repo: any DoublesRepository) async {
        guard let updated = try? await repo.unlock(beatId: beatId) else { return }
        guard let idx = snapshot?.episode.beats.firstIndex(where: { $0.id == beatId }) else { return }
        snapshot?.episode.beats[idx] = updated
        Haptics.success()
    }

    func persona(_ id: String) -> Persona? { snapshot?.cast.first { $0.id == id } }
}

struct TodayView: View {
    @Environment(\.repo) private var repo
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var vm = TodayViewModel()
    @State private var revealed = false

    @State private var showWorlds = false
    @State private var showPowerMoves = false
    @State private var showAgenda = false
    @State private var showSettings = false
    @State private var showInvite = false

    var body: some View {
        NavigationStack {
            ScreenBackground {
                content
            }
            // Custom header (below) instead of the system bar — the iOS 26/27
            // glass toolbar forces a capsule around custom controls.
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showWorlds) { WorldsSwitcherSheet(current: vm.snapshot?.world) }
        .sheet(isPresented: $showAgenda) {
            if let snap = vm.snapshot {
                AgendaSheet(myDouble: snap.myDouble, existing: snap.agenda) { await reload() }
            }
        }
        .sheet(isPresented: $showPowerMoves) {
            if let snap = vm.snapshot {
                PowerMoveSheet(cast: snap.cast, remaining: snap.powerMovesRemaining) { await reload() }
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showInvite) {
            InviteSheet(worldName: vm.snapshot?.world.name ?? "your season")
        }
        .task { await vm.load(repo); triggerReveal() }
    }

    // MARK: content states
    @ViewBuilder private var content: some View {
        switch vm.phase {
        case .loading:
            ScrollView { VStack(spacing: DS.Space.l) { headerSkeleton; FeedSkeleton() }.padding(DS.Space.l) }
        case .error:
            ErrorStateView { Task { await vm.load(repo) } }
        case .empty:
            EmptyStateView(symbol: "moon.stars.fill",
                           title: "first episode drops tonight",
                           message: "your double is settling in. come back in the morning — that's when it gets good.")
        case .loaded:
            if let snap = vm.snapshot { loaded(snap) }
        }
    }

    private func loaded(_ snap: WorldSnapshot) -> some View {
        VStack(spacing: 0) {
            header(snap)
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xl) {
                    episodeHeader(snap)
                    recapBlock(snap)
                    agendaPrompt(snap)
                    inviteCard(snap)
                    feed(snap)
                    if let h = snap.world.nextEpisodeInHours { countdown(h) }
                }
                .padding(DS.Space.l)
                .padding(.bottom, DS.Space.xxxl)
            }
            .refreshable { await vm.load(repo, initial: false) }
        }
    }

    // MARK: custom header (power-moves left · world center · profile right)
    private func header(_ snap: WorldSnapshot) -> some View {
        ZStack {
            // world switcher — centered
            Button { Haptics.tap(); showWorlds = true } label: {
                HStack(spacing: DS.Space.xs) {
                    Text(snap.world.name).font(.ui(15, .bold)).foregroundStyle(DS.bone).lineLimit(1)
                    Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold)).foregroundStyle(DS.rose)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("world: \(snap.world.name). switch worlds")

            HStack {
                // power moves — left
                Button { Haptics.tap(); showPowerMoves = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill").font(.system(size: 11))
                        Text("\(snap.powerMovesRemaining)").monoLabel(11, bold: true)
                    }
                    .foregroundStyle(DS.ink)
                    .padding(.horizontal, DS.Space.s).padding(.vertical, 6)
                    .background(DS.acid)
                    .clipShape(.rect(cornerRadius: DS.Radius.card))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(snap.powerMovesRemaining) power moves left. open power moves")

                Spacer()

                // profile — right
                Button { Haptics.tap(); showSettings = true } label: {
                    DoubleAvatar(persona: snap.myDouble, size: 30)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("you and settings")
            }
        }
        .padding(.horizontal, DS.Space.l)
        .padding(.top, DS.Space.xs)
        .padding(.bottom, DS.Space.m)
        .overlay(alignment: .bottom) { Rectangle().fill(DS.line).frame(height: 1) }
    }

    // MARK: episode header (the reveal)
    private func episodeHeader(_ snap: WorldSnapshot) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            HStack(alignment: .firstTextBaseline) {
                Text("EPISODE \(String(format: "%02d", snap.episode.number))")
                    .font(.display(40)).foregroundStyle(DS.bone)
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .accessibilityLabel("episode \(snap.episode.number)")
                if snap.episode.isUnread {
                    Text("new")
                        .monoLabel(9, bold: true)
                        .foregroundStyle(DS.ink)
                        .padding(.horizontal, DS.Space.s).padding(.vertical, 3)
                        .background(DS.acid)
                        .opacity(revealed || reduceMotion ? 1 : 0)
                        .scaleEffect(revealed || reduceMotion ? 1 : 0.6)
                }
            }
            Chyron(label: snap.episode.dateLabel, value: snap.episode.headline, marquee: true)
                .offset(x: revealed || reduceMotion ? 0 : -30)
                .opacity(revealed || reduceMotion ? 1 : 0)
        }
        .animation(.spring(duration: DS.Dur.dramatic), value: revealed)
    }

    // MARK: recap
    private func recapBlock(_ snap: WorldSnapshot) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionLabel(text: "the recap", trailing: "shareable")
            FittedRecapCard(recap: snap.episode.recap, worldName: snap.world.name)
                .frame(maxWidth: .infinity)
                .scaleEffect(revealed || reduceMotion ? 1 : 0.96)
                .opacity(revealed || reduceMotion ? 1 : 0)
                .animation(.spring(duration: DS.Dur.dramatic).delay(0.1), value: revealed)
            HStack {
                Text(snap.episode.recap.narrative).font(.ui(14)).foregroundStyle(DS.boneDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            RecapShareButton(recap: snap.episode.recap, worldName: snap.world.name)
        }
    }

    // MARK: agenda
    private func agendaPrompt(_ snap: WorldSnapshot) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionLabel(text: "your agenda")
            Button { Haptics.tap(); showAgenda = true } label: {
                VStack(alignment: .leading, spacing: DS.Space.s) {
                    Text("what's \(snap.myDouble.displayName.lowercased()) chasing next episode?")
                        .font(.ui(16, .semibold)).foregroundStyle(DS.bone)
                    if let a = snap.agenda {
                        Text("“\(a.intentText)”").font(.ui(14).italic()).foregroundStyle(DS.acid)
                    } else {
                        Text("tap to set an agenda — you steer, you don't script.")
                            .font(.ui(13)).foregroundStyle(DS.boneDim)
                    }
                }
                .padding(DS.Space.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DS.surface)
                .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityHint("opens the agenda editor")
        }
    }

    // MARK: invite (viral loop)
    private func inviteCard(_ snap: WorldSnapshot) -> some View {
        Button { Haptics.tap(); showInvite = true } label: {
            HStack(spacing: DS.Space.m) {
                Image(systemName: "person.2.badge.plus.fill")
                    .font(.system(size: 22)).foregroundStyle(DS.ink)
                    .frame(width: 44, height: 44)
                    .background(DS.acid)
                    .clipShape(.rect(cornerRadius: DS.Radius.card))
                VStack(alignment: .leading, spacing: 2) {
                    Text("invite the group").font(.ui(16, .semibold)).foregroundStyle(DS.bone)
                    Text("the more friends, the messier it gets.")
                        .font(.ui(13)).foregroundStyle(DS.boneDim)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(DS.rose)
            }
            .padding(DS.Space.l)
            .frame(maxWidth: .infinity)
            .background(DS.surface)
            .overlay(Rectangle().stroke(DS.acid.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityHint("invite friends to this season")
    }

    // MARK: feed
    private func feed(_ snap: WorldSnapshot) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionLabel(text: "the beats", trailing: "\(snap.episode.beats.count)")
            ForEach(snap.episode.beats) { beat in
                BeatCard(beat: beat,
                         author: vm.persona(beat.authorId) ?? snap.myDouble,
                         partner: beat.kind == .ship ? secondParticipant(beat) : nil) {
                    await vm.unlock(beat.id, repo: repo)
                }
            }
        }
    }

    private func secondParticipant(_ beat: Beat) -> Persona? {
        guard beat.participantIds.count > 1 else { return nil }
        return vm.persona(beat.participantIds[1])
    }

    private func countdown(_ hours: Int) -> some View {
        HStack(spacing: DS.Space.s) {
            Image(systemName: "hourglass").foregroundStyle(DS.rose)
            Text("next episode in \(hours)h").monoLabel(11, tracking: 2).foregroundStyle(DS.boneDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Space.l)
    }

    private var headerSkeleton: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SkeletonBar(height: 36, widthFraction: 0.7)
            SkeletonBar(height: 28, widthFraction: 1)
            SkeletonBar(height: 200, widthFraction: 1)
        }
    }

    private func triggerReveal() {
        guard !reduceMotion else { revealed = true; return }
        Haptics.heavy()
        withAnimation(.spring(duration: DS.Dur.dramatic)) { revealed = true }
    }

    private func reload() async { await vm.load(repo, initial: false) }
}

#Preview("Today") {
    TodayView().environment(\.repo, MockRepository.preview).preferredColorScheme(.dark)
}
