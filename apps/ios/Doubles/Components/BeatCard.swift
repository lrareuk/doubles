//
//  BeatCard.swift
//  The feed unit, four visual types: post, dm/confessional, twist, ship.
//  Plus the reveal-gated locked state. Honest copy — never implies real users.
//

import SwiftUI

struct BeatCard: View {
    var beat: Beat
    var author: Persona
    var partner: Persona?          // for ship beats
    var onUnlock: () async -> Void = {}

    @State private var isUnlocking = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var edge: Color { beat.kind.accent }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            if beat.kind == .twist {
                Chyron(label: "plot twist", value: author.displayName.uppercased())
            }
            header
            content
            if !beat.isGated && (beat.kind == .post || beat.kind == .ship) {
                footer
            }
        }
        .padding(DS.Space.l)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay(alignment: .leading) {
            Rectangle().fill(edge).frame(width: beat.kind == .post ? 0 : 3)
        }
        .overlay(Rectangle().stroke(beat.kind == .twist ? DS.magenta.opacity(0.5) : DS.line, lineWidth: 1))
        .shadow(color: beat.kind == .twist ? DS.magenta.opacity(0.25) : .clear, radius: 16, y: 6)
    }

    // MARK: header
    @ViewBuilder private var header: some View {
        HStack(spacing: DS.Space.m) {
            if beat.kind == .ship, let partner {
                ShipAvatars(a: author, b: partner, size: 40)
            } else {
                DoubleAvatar(persona: author, size: 40)
            }
            VStack(alignment: .leading, spacing: 1) {
                if beat.kind == .ship, let partner {
                    Text("\(author.displayName) + \(partner.displayName)")
                        .font(.ui(15, .semibold)).foregroundStyle(DS.bone)
                } else {
                    Text(author.displayName).font(.ui(15, .semibold)).foregroundStyle(DS.bone)
                }
                Text("@\(author.handle)").monoLabel(10).foregroundStyle(DS.boneDim)
            }
            Spacer()
            tag
        }
    }

    @ViewBuilder private var tag: some View {
        switch beat.kind {
        case .dm: TagChip(text: "confessional", tint: DS.acid)
        case .ship: TagChip(text: "ship", tint: DS.acid, filled: true)
        case .scene: TagChip(text: "scene", tint: DS.rose)
        case .twist, .post: EmptyView()
        }
    }

    // MARK: content
    @ViewBuilder private var content: some View {
        if beat.isGated && beat.visibility == .revealGated {
            LockedOverlay(isUnlocking: isUnlocking) {
                isUnlocking = true
                Task { await onUnlock(); isUnlocking = false }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(beat.content)
                .font(beat.kind == .dm ? .ui(15).italic() : .ui(15))
                .foregroundStyle(beat.kind == .dm ? DS.bone : DS.bone)
                .fixedSize(horizontal: false, vertical: true)
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
        }
    }

    // MARK: footer
    private var footer: some View {
        HStack(spacing: DS.Space.l) {
            Label("\(beat.likeCount)", systemImage: "heart")
            Label("\(beat.replyCount)", systemImage: "bubble.right")
            Spacer()
        }
        .monoLabel(10)
        .foregroundStyle(DS.boneDim)
        .labelStyle(.titleAndIcon)
    }
}

/// Redaction bars over hidden content + an honest unlock CTA.
struct LockedOverlay: View {
    var isUnlocking: Bool
    var onUnlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach([0.9, 0.7, 0.55], id: \.self) { w in
                    Rectangle()
                        .fill(DS.ink.opacity(0.85))
                        .frame(width: nil, height: 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .scaleEffect(x: w, anchor: .leading)
                        .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
                }
            }
            Text("this happened in the dms. unlock to see it.")
                .font(.ui(13)).foregroundStyle(DS.boneDim)
            RevealButton(isLoading: isUnlocking, action: onUnlock)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("hidden beat. this happened in the dms.")
        .accessibilityHint("double tap to unlock")
    }
}

struct RevealButton: View {
    var isLoading: Bool = false
    var action: () -> Void
    var body: some View {
        Button(action: { Haptics.commit(); action() }) {
            HStack(spacing: DS.Space.s) {
                Image(systemName: isLoading ? "hourglass" : "lock.fill")
                Text(isLoading ? "unlocking…" : "unlock").monoLabel(11, bold: true, tracking: 2)
            }
            .foregroundStyle(DS.ink)
            .padding(.horizontal, DS.Space.l).padding(.vertical, DS.Space.s)
            .background(DS.acid)
            .clipShape(.rect(cornerRadius: DS.Radius.card))
        }
        .disabled(isLoading)
    }
}

#Preview("BeatCard variants") {
    let r = MockRepository.preview
    return ScreenBackground {
        ScrollView {
            VStack(spacing: DS.Space.m) {
                BeatCard(beat: Beat(id: "1", kind: .post, authorId: "d_maya", participantIds: ["d_maya"],
                                    content: "if you're going to subtweet me at least @ me. i have notifications on for a reason.",
                                    visibility: .public, likeCount: 214, replyCount: 38),
                         author: r.persona("d_maya"))
                BeatCard(beat: Beat(id: "3", kind: .twist, authorId: "d_priya", participantIds: ["d_priya"],
                                    content: "priya has been feeding both sides of the fight all week. on purpose.",
                                    visibility: .public, likeCount: 0, replyCount: 0),
                         author: r.persona("d_priya"))
                BeatCard(beat: Beat(id: "4", kind: .ship, authorId: "d_jordan", participantIds: ["d_jordan", "d_theo"],
                                    content: "jordan and theo left at the same time. again.",
                                    visibility: .public, likeCount: 188, replyCount: 51),
                         author: r.persona("d_jordan"), partner: r.persona("d_theo"))
                BeatCard(beat: Beat(id: "5", kind: .dm, authorId: "d_kit", participantIds: ["d_kit"],
                                    content: "secret", visibility: .revealGated, likeCount: 0, replyCount: 0),
                         author: r.persona("d_kit"))
            }
            .padding(DS.Space.l)
        }
    }
}
