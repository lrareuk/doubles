//
//  PowerMoveSheet.swift
//  Spend the metered, monetised verb. High-value, decisive, with a firm haptic.
//

import SwiftUI

struct PowerMoveSheet: View {
    var cast: [Persona]
    var remaining: Int
    var onSpent: () async -> Void

    @Environment(\.repo) private var repo
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selected: PowerMoveType?
    @State private var target: Persona?
    @State private var spending = false
    @State private var launched = false
    @State private var localRemaining: Int
    @State private var showPaywall = false

    init(cast: [Persona], remaining: Int, onSpent: @escaping () async -> Void) {
        self.cast = cast
        self.remaining = remaining
        self.onSpent = onSpent
        _localRemaining = State(initialValue: remaining)
    }

    var body: some View {
        NavigationStack {
            ScreenBackground {
                if localRemaining <= 0 && !launched {
                    outOfMoves
                } else {
                    chooser
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("close") { dismiss() }.foregroundStyle(DS.boneDim).font(.ui(15))
                }
                ToolbarItem(placement: .principal) {
                    Text("power moves").font(.ui(15, .bold)).foregroundStyle(DS.bone)
                }
            }
            .toolbarBackground(DS.wine, for: .navigationBar)
        }
        .presentationDetents([.large])
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var chooser: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.l) {
                HStack {
                    Text("\(localRemaining) moves left today").monoLabel(11, bold: true, tracking: 2)
                        .foregroundStyle(DS.acid)
                    Spacer()
                }
                Text("nudge the story. you can't write your double's lines — but you can light a fuse.")
                    .font(.ui(13)).foregroundStyle(DS.boneDim)

                ForEach(PowerMoveType.allCases) { type in
                    PowerMoveCard(type: type, isSelected: selected == type) {
                        withAnimation(.spring(duration: DS.Dur.quick)) {
                            selected = type
                            if !type.needsTarget { target = nil }
                        }
                    }
                }

                if let selected, selected.needsTarget {
                    SectionLabel(text: "target")
                    targetPicker
                }

                PrimaryButton(title: spending ? "in motion…" : "spend move",
                              icon: selected?.symbol ?? "bolt.fill",
                              isEnabled: canSpend && !spending) { spend() }
                    .padding(.top, DS.Space.s)
            }
            .padding(DS.Space.l)
        }
        .overlay { if launched { launchFlash } }
    }

    private var targetPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.m) {
                ForEach(cast.filter { !$0.isMine }) { p in
                    Button {
                        Haptics.tap(); target = p
                    } label: {
                        VStack(spacing: DS.Space.xs) {
                            DoubleAvatar(persona: p, size: 56)
                                .overlay(Rectangle().stroke(target?.id == p.id ? DS.magenta : .clear, lineWidth: 2))
                            Text(p.displayName.lowercased()).monoLabel(9)
                                .foregroundStyle(target?.id == p.id ? DS.bone : DS.boneDim)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(p.displayName)
                    .accessibilityAddTraits(target?.id == p.id ? .isSelected : [])
                }
            }
            .padding(.vertical, DS.Space.xs)
        }
    }

    private var launchFlash: some View {
        ZStack {
            DS.magenta.opacity(0.0)
            VStack(spacing: DS.Space.m) {
                Image(systemName: selected?.symbol ?? "bolt.fill")
                    .font(.system(size: 64)).foregroundStyle(DS.magenta)
                    .scaleEffect(launched ? 1 : 0.2)
                Text("in motion").font(.display(34)).foregroundStyle(DS.bone)
            }
        }
        .transition(.opacity)
        .allowsHitTesting(false)
    }

    private var outOfMoves: some View {
        VStack(spacing: DS.Space.l) {
            EmptyStateView(symbol: "bolt.slash.fill",
                           title: "you're out of moves",
                           message: "free moves reset tomorrow. subscribers get more every day — no pressure, the drama runs either way.")
            PrimaryButton(title: "see what's in the sub", icon: "crown.fill") { showPaywall = true }
                .padding(.horizontal, DS.Space.l)
            GhostButton(title: "i'll wait for the reset") { dismiss() }
                .padding(.horizontal, DS.Space.l)
        }
    }

    private var canSpend: Bool {
        guard let selected else { return false }
        return !selected.needsTarget || target != nil
    }

    private func spend() {
        guard let selected else { return }
        spending = true
        Task {
            do {
                let newRemaining = try await repo.spendPowerMove(selected, targetDoubleId: target?.id)
                Haptics.heavy()
                if reduceMotion {
                    localRemaining = newRemaining
                } else {
                    withAnimation(.spring(duration: DS.Dur.dramatic)) { launched = true }
                    try? await Task.sleep(nanoseconds: 900_000_000)
                    localRemaining = newRemaining
                }
                await onSpent()
                dismiss()
            } catch {
                Haptics.failure()
                spending = false
            }
        }
    }
}

#Preview("PowerMoveSheet") {
    PowerMoveSheet(cast: MockRepository.preview.persona("d_maya").isMine
                   ? [MockRepository.preview.persona("d_maya"),
                      MockRepository.preview.persona("d_priya"),
                      MockRepository.preview.persona("d_theo")] : [],
                   remaining: 3) {}
        .environment(\.repo, MockRepository.preview)
        .preferredColorScheme(.dark)
}
