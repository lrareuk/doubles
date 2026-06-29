//
//  CastDetailView.swift
//  One double's profile: a big accent header, traits, season stats, who they're
//  tangled up with, and their recent beats. Your own double gets an edit entry.
//

import SwiftUI

@Observable
@MainActor
final class CastDetailViewModel {
    enum Phase { case loading, loaded, error }
    var phase: Phase = .loading
    var relationships: [Relationship] = []
    var beats: [Beat] = []
    var cast: [Persona] = []
    var score: SeasonScore?

    func load(_ repo: any DoublesRepository, persona: Persona) async {
        phase = .loading
        do {
            async let rels = repo.relationships(for: persona.id)
            async let theBeats = repo.beats(for: persona.id)
            async let people = repo.cast()
            async let standings = repo.standings()
            let (rels2, beats2, cast2, scores) = try await (rels, theBeats, people, standings)
            relationships = rels2
            beats = beats2
            cast = cast2
            score = scores.first { $0.doubleId == persona.id }
            phase = .loaded
        } catch {
            phase = .error
        }
    }

    func persona(_ id: String) -> Persona? { cast.first { $0.id == id } }
}

struct CastDetailView: View {
    var persona: Persona

    @Environment(\.repo) private var repo
    @State private var vm = CastDetailViewModel()
    @State private var showEdit = false

    var body: some View {
        ScreenBackground {
            content
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("@\(persona.handle)").monoLabel(11, bold: true, tracking: 2)
                    .foregroundStyle(DS.boneDim)
            }
        }
        .toolbarBackground(DS.wine, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showEdit) {
            BuildDoubleView(editing: persona) { showEdit = false }
        }
        .task { await vm.load(repo, persona: persona) }
    }

    @ViewBuilder private var content: some View {
        switch vm.phase {
        case .loading:
            ScrollView { VStack(spacing: DS.Space.l) { header; FeedSkeleton() }.padding(DS.Space.l) }
        case .error:
            ErrorStateView { Task { await vm.load(repo, persona: persona) } }
        case .loaded:
            loaded
        }
    }

    private var loaded: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {
                header
                if persona.isMine { editEntry }
                traits
                if let score = vm.score { stats(score) }
                relationships
                recentBeats
            }
            .padding(DS.Space.l)
            .padding(.bottom, DS.Space.xxxl)
        }
    }

    // MARK: header
    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [persona.accent.opacity(0.95), persona.accent.opacity(0.2)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 150)
                HStack(alignment: .bottom, spacing: DS.Space.m) {
                    DoubleAvatar(persona: persona, size: 72)
                    if persona.isMine {
                        Text("you")
                            .monoLabel(9, bold: true)
                            .padding(.horizontal, DS.Space.s).padding(.vertical, 3)
                            .background(DS.ink).foregroundStyle(persona.accent)
                            .clipShape(.rect(cornerRadius: DS.Radius.card))
                    }
                    Spacer()
                }
                .padding(DS.Space.l)
            }
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(persona.displayName).font(.display(36)).foregroundStyle(DS.bone)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .accessibilityLabel(persona.displayName)
                Text("@\(persona.handle)").monoLabel(11).foregroundStyle(DS.boneDim)
                Text(persona.vibe).font(.ui(15)).foregroundStyle(DS.boneDim)
                    .padding(.top, DS.Space.xs)
            }
            .padding(DS.Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.surface)
        }
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
    }

    private var editEntry: some View {
        GhostButton(title: "edit your double", icon: "slider.horizontal.3", tint: persona.accent) {
            showEdit = true
        }
    }

    // MARK: traits
    private var traits: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionLabel(text: "the read")
            Text("“\(persona.personaPrompt)”")
                .font(.ui(15).italic()).foregroundStyle(DS.bone)
                .fixedSize(horizontal: false, vertical: true)
            FlowChips(items: persona.traits, tint: persona.accent)
        }
    }

    private func stats(_ score: SeasonScore) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionLabel(text: "season \(1) stats", trailing: "total \(score.total)")
            HStack(spacing: DS.Space.s) {
                StatPill(label: "drama", value: score.drama, tint: DS.magenta)
                StatPill(label: "ships", value: score.ships, tint: DS.acid)
                StatPill(label: "glow", value: score.glowup, tint: DS.rose)
                StatPill(label: "villain", value: score.villain, tint: DS.magenta)
            }
        }
    }

    // MARK: relationships
    @ViewBuilder private var relationships: some View {
        if !vm.relationships.isEmpty {
            VStack(alignment: .leading, spacing: DS.Space.m) {
                SectionLabel(text: "entanglements", trailing: "\(vm.relationships.count)")
                VStack(spacing: DS.Space.s) {
                    ForEach(vm.relationships) { rel in
                        relationshipRow(rel)
                    }
                }
            }
        }
    }

    private func relationshipRow(_ rel: Relationship) -> some View {
        let target = vm.persona(rel.toId)
        return HStack(spacing: DS.Space.m) {
            if let target {
                DoubleAvatar(persona: target, size: 36)
            } else {
                Image(systemName: "person.fill").foregroundStyle(DS.boneDim).frame(width: 36, height: 36)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(target?.displayName ?? "someone").font(.ui(14, .semibold)).foregroundStyle(DS.bone)
                HStack(spacing: DS.Space.xs) {
                    Image(systemName: rel.type.symbol).font(.system(size: 9))
                    Text(rel.type.label).monoLabel(9, bold: true, tracking: 1.5)
                }
                .foregroundStyle(rel.type.accent)
            }
            Spacer()
            StatPill(label: "affinity", value: rel.affinity, tint: rel.affinity >= 0 ? DS.acid : DS.magenta)
        }
        .padding(DS.Space.m)
        .background(DS.surface)
        .overlay(alignment: .leading) { Rectangle().fill(rel.type.accent).frame(width: 3) }
        .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(rel.type.label) with \(target?.displayName ?? "someone"), affinity \(rel.affinity)")
    }

    // MARK: recent beats
    @ViewBuilder private var recentBeats: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionLabel(text: "recent beats", trailing: "\(vm.beats.count)")
            if vm.beats.isEmpty {
                EmptyStateView(symbol: "text.bubble",
                               title: "quiet so far",
                               message: "\(persona.displayName.lowercased()) hasn't made a scene this episode. give it time.")
            } else {
                ForEach(vm.beats) { beat in
                    BeatCard(beat: beat,
                             author: vm.persona(beat.authorId) ?? persona,
                             partner: beat.kind == .ship ? secondParticipant(beat) : nil)
                }
            }
        }
    }

    private func secondParticipant(_ beat: Beat) -> Persona? {
        guard beat.participantIds.count > 1 else { return nil }
        return vm.persona(beat.participantIds[1])
    }
}

/// A simple wrapping row of trait chips (TagChip-styled).
struct FlowChips: View {
    var items: [String]
    var tint: Color = DS.rose

    var body: some View {
        FlowLayout(spacing: DS.Space.s) {
            ForEach(items, id: \.self) { item in
                TagChip(text: item, tint: tint)
            }
        }
    }
}

/// Minimal flow layout so chips wrap across lines without a fixed grid.
struct FlowLayout: Layout {
    var spacing: CGFloat = DS.Space.s

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview("CastDetail — mine") {
    NavigationStack {
        CastDetailView(persona: MockRepository.preview.persona("d_maya"))
    }
    .environment(\.repo, MockRepository.preview)
    .preferredColorScheme(.dark)
}

#Preview("CastDetail — other") {
    NavigationStack {
        CastDetailView(persona: MockRepository.preview.persona("d_priya"))
    }
    .environment(\.repo, MockRepository.preview)
    .preferredColorScheme(.dark)
}
