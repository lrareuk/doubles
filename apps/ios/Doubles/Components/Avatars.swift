//
//  Avatars.swift
//  DoubleAvatar (drawn — no remote images) and CharacterCard (trading-card).
//

import SwiftUI

struct DoubleAvatar: View {
    var persona: Persona
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            LinearGradient(colors: [persona.accent, persona.accent.opacity(0.55)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            // generated mark: faint concentric arcs, broadcast-card texture
            GeometryReader { geo in
                let d = min(geo.size.width, geo.size.height)
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(DS.ink.opacity(0.10), lineWidth: d * 0.06)
                        .frame(width: d * (0.5 + CGFloat(i) * 0.34))
                        .position(x: geo.size.width * 0.82, y: geo.size.height * 0.85)
                }
            }
            Text(persona.initials)
                .font(.display(size * 0.42))
                .foregroundStyle(DS.ink)
                .shadow(color: .white.opacity(0.15), radius: 0, x: 0, y: 1)
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay(Rectangle().stroke(DS.ink.opacity(0.25), lineWidth: 1))
        .accessibilityHidden(true)
    }
}

/// Two avatars overlapped, for ship beats.
struct ShipAvatars: View {
    var a: Persona
    var b: Persona
    var size: CGFloat = 44
    var body: some View {
        HStack(spacing: -size * 0.3) {
            DoubleAvatar(persona: a, size: size)
            DoubleAvatar(persona: b, size: size)
                .overlay(Rectangle().stroke(DS.wine, lineWidth: 2))
        }
        .accessibilityHidden(true)
    }
}

struct CharacterCard: View {
    var persona: Persona
    var score: SeasonScore?
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: { Haptics.tap(); onTap() }) {
            VStack(alignment: .leading, spacing: 0) {
                // accent header strip
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: [persona.accent.opacity(0.9), persona.accent.opacity(0.25)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 92)
                    HStack(alignment: .bottom) {
                        DoubleAvatar(persona: persona, size: 56)
                        Spacer()
                        if persona.isMine {
                            Text("you")
                                .monoLabel(9, bold: true)
                                .padding(.horizontal, DS.Space.s).padding(.vertical, 3)
                                .background(DS.ink).foregroundStyle(persona.accent)
                                .clipShape(.rect(cornerRadius: DS.Radius.card))
                        }
                    }
                    .padding(DS.Space.m)
                }
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text(persona.displayName).font(.display(22)).foregroundStyle(DS.bone)
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .accessibilityLabel(persona.displayName)
                    Text("@\(persona.handle)").monoLabel(10).foregroundStyle(DS.boneDim)
                    Text(persona.vibe).font(.ui(13)).foregroundStyle(DS.boneDim)
                        .lineLimit(2).frame(height: 34, alignment: .top)
                    if let score {
                        HStack(spacing: DS.Space.xs) {
                            StatPill(label: "drama", value: score.drama, tint: DS.magenta)
                            StatPill(label: "ships", value: score.ships, tint: DS.acid)
                        }
                        .padding(.top, DS.Space.xs)
                    }
                }
                .padding(DS.Space.m)
            }
            .background(DS.surface)
            .clipShape(.rect(cornerRadius: DS.Radius.card))
            .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(persona.displayName), @\(persona.handle). \(persona.vibe)")
        .accessibilityHint("opens profile")
    }
}

#Preview("Avatars & CharacterCard") {
    let repo = MockRepository.preview
    return ScreenBackground {
        ScrollView {
            VStack(spacing: DS.Space.l) {
                HStack(spacing: DS.Space.m) {
                    DoubleAvatar(persona: repo.persona("d_maya"), size: 64)
                    DoubleAvatar(persona: repo.persona("d_priya"), size: 64)
                    ShipAvatars(a: repo.persona("d_jordan"), b: repo.persona("d_theo"))
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Space.m) {
                    CharacterCard(persona: repo.persona("d_maya"),
                                  score: SeasonScore(doubleId: "d_maya", drama: 9, ships: 2, glowup: 1, villain: 4))
                    CharacterCard(persona: repo.persona("d_priya"),
                                  score: SeasonScore(doubleId: "d_priya", drama: 6, ships: 0, glowup: 0, villain: 9))
                }
            }
            .padding(DS.Space.l)
        }
    }
}
