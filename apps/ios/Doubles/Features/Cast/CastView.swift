//
//  CastView.swift
//  The full ensemble as a wall of trading cards. Your double is highlighted with a
//  "tune your double" affordance. Tapping a card opens the profile.
//

import SwiftUI

@Observable
@MainActor
final class CastViewModel {
    enum Phase { case loading, loaded, error }
    var phase: Phase = .loading
    var cast: [Persona] = []
    var scores: [String: SeasonScore] = [:]

    func load(_ repo: any DoublesRepository, initial: Bool = true) async {
        if initial { phase = .loading }
        do {
            async let people = repo.cast()
            async let standings = repo.standings()
            let (cast, scores) = try await (people, standings)
            self.cast = cast
            self.scores = Dictionary(uniqueKeysWithValues: scores.map { ($0.doubleId, $0) })
            phase = .loaded
        } catch {
            phase = .error
        }
    }

    var mine: Persona? { cast.first { $0.isMine } }
    func score(for id: String) -> SeasonScore? { scores[id] }
}

struct CastView: View {
    @Environment(\.repo) private var repo
    @State private var vm = CastViewModel()

    private let columns = [GridItem(.flexible(), spacing: DS.Space.m),
                           GridItem(.flexible(), spacing: DS.Space.m)]

    var body: some View {
        NavigationStack {
            ScreenBackground {
                content
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Persona.self) { CastDetailView(persona: $0) }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("cast").font(.ui(15, .bold)).foregroundStyle(DS.bone)
                        .accessibilityLabel("cast")
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
            loaded
        }
    }

    private var loaded: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.l) {
                SectionLabel(text: "the cast", trailing: "\(vm.cast.count)")

                if let me = vm.mine {
                    mineSpotlight(me)
                }

                LazyVGrid(columns: columns, spacing: DS.Space.m) {
                    ForEach(vm.cast) { persona in
                        NavigationLink(value: persona) {
                            CharacterCard(persona: persona, score: vm.score(for: persona.id))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(DS.Space.l)
            .padding(.bottom, DS.Space.xxxl)
        }
        .refreshable { await vm.load(repo, initial: false) }
    }

    // The "tune your double" affordance for the mine card.
    private func mineSpotlight(_ me: Persona) -> some View {
        NavigationLink(value: me) {
            HStack(spacing: DS.Space.m) {
                DoubleAvatar(persona: me, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("that's your double up there.")
                        .font(.ui(14, .semibold)).foregroundStyle(DS.bone)
                    Text("tune your double — steer the vibe before tonight.")
                        .font(.ui(12)).foregroundStyle(DS.boneDim)
                }
                Spacer()
                HStack(spacing: DS.Space.xs) {
                    Image(systemName: "slider.horizontal.3").font(.system(size: 11))
                    Text("tune").monoLabel(10, bold: true, tracking: 1.5)
                }
                .foregroundStyle(DS.ink)
                .padding(.horizontal, DS.Space.s).padding(.vertical, 6)
                .background(me.accent)
                .clipShape(.rect(cornerRadius: DS.Radius.card))
            }
            .padding(DS.Space.m)
            .background(DS.surface)
            .overlay(Rectangle().stroke(me.accent.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("tune your double, \(me.displayName)")
        .accessibilityHint("opens your profile to edit")
    }
}

#Preview("Cast") {
    CastView().environment(\.repo, MockRepository.preview).preferredColorScheme(.dark)
}
