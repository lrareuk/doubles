//
//  Backgrounds.swift
//  ScreenBackground (wine→plum gradient + grain) and the GrainOverlay motif.
//

import SwiftUI

/// Subtle tiled film-grain. Soft-light blend, low opacity — a quiet broadcast texture.
/// Hidden under Reduce Transparency. Deterministic so it doesn't shimmer on redraw.
struct GrainOverlay: View {
    var opacity: Double = 0.05
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if reduceTransparency {
            EmptyView()
        } else {
            Canvas { context, size in
                var rng = SeededRNG(seed: 0xD0_0B_1E)
                let count = Int(min(6000, size.width * size.height / 16))
                for _ in 0..<count {
                    let x = Double(rng.next()) / Double(UInt64.max) * size.width
                    let y = Double(rng.next()) / Double(UInt64.max) * size.height
                    let a = Double(rng.next()) / Double(UInt64.max)
                    let rect = CGRect(x: x, y: y, width: 1, height: 1)
                    context.fill(Path(rect), with: .color(.white.opacity(a)))
                }
            }
            .blendMode(.softLight)
            .opacity(opacity)
            .allowsHitTesting(false)
            .ignoresSafeArea()
        }
    }
}

/// The standard screen backdrop: wine→plum diagonal gradient plus grain.
struct ScreenBackground<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DS.wine, DS.plum],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            GrainOverlay()
            content
        }
    }
}

/// A tiny, fast, deterministic RNG (xorshift) so grain is stable across redraws.
struct SeededRNG {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0xDEAD_BEEF : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

#Preview("ScreenBackground") {
    ScreenBackground {
        VStack(spacing: DS.Space.m) {
            Text("WINE → PLUM").font(.display(40)).foregroundStyle(DS.bone)
            Text("with quiet grain").font(.ui(15)).foregroundStyle(DS.boneDim)
        }
    }
}
