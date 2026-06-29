//
//  States.swift
//  Themed loading skeletons, empty states, and error views. No spinners on blank screens.
//

import SwiftUI

struct SkeletonBar: View {
    var height: CGFloat = 14
    var widthFraction: CGFloat = 1
    @State private var shimmer = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(DS.surfaceLift)
                .overlay(
                    LinearGradient(colors: [.clear, DS.bone.opacity(0.06), .clear],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(width: geo.size.width * 0.5)
                        .offset(x: shimmer ? geo.size.width : -geo.size.width)
                )
                .clipShape(.rect(cornerRadius: DS.Radius.card))
                .frame(width: geo.size.width * widthFraction, alignment: .leading)
        }
        .frame(height: height)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { shimmer = true }
        }
        .accessibilityHidden(true)
    }
}

/// A few stacked skeleton cards for feed-style loading.
struct FeedSkeleton: View {
    var body: some View {
        VStack(spacing: DS.Space.m) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: DS.Space.m) {
                    HStack(spacing: DS.Space.m) {
                        Rectangle().fill(DS.surfaceLift).frame(width: 40, height: 40)
                        VStack(alignment: .leading, spacing: 6) {
                            SkeletonBar(height: 12, widthFraction: 0.4)
                            SkeletonBar(height: 9, widthFraction: 0.25)
                        }
                    }
                    SkeletonBar(height: 12, widthFraction: 0.95)
                    SkeletonBar(height: 12, widthFraction: 0.7)
                }
                .padding(DS.Space.l)
                .background(DS.surface)
                .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
            }
        }
        .accessibilityLabel("loading")
    }
}

struct LoadingView: View {
    var caption: String = "checking the timeline…"
    var body: some View {
        VStack(spacing: DS.Space.l) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 28)).foregroundStyle(DS.magenta)
                .accessibilityHidden(true)
            Text(caption).monoLabel(11, tracking: 2).foregroundStyle(DS.boneDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel(caption)
    }
}

struct EmptyStateView: View {
    var symbol: String
    var title: String
    var message: String
    var body: some View {
        VStack(spacing: DS.Space.m) {
            Image(systemName: symbol).font(.system(size: 34)).foregroundStyle(DS.rose)
                .accessibilityHidden(true)
            Text(title).font(.display(26)).foregroundStyle(DS.bone)
                .multilineTextAlignment(.center)
            Text(message).font(.ui(14)).foregroundStyle(DS.boneDim)
                .multilineTextAlignment(.center)
        }
        .padding(DS.Space.xxl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct ErrorStateView: View {
    var message: String = "something glitched in the timeline."
    var retry: () -> Void
    var body: some View {
        VStack(spacing: DS.Space.l) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 30)).foregroundStyle(DS.magenta)
                .accessibilityHidden(true)
            Text(message).font(.ui(15)).foregroundStyle(DS.bone).multilineTextAlignment(.center)
            GhostButton(title: "try again", icon: "arrow.clockwise") { retry() }
                .frame(maxWidth: 220)
        }
        .padding(DS.Space.xxl)
        .frame(maxWidth: .infinity)
    }
}

#Preview("States") {
    ScreenBackground {
        ScrollView {
            VStack(spacing: DS.Space.xl) {
                FeedSkeleton()
                EmptyStateView(symbol: "chart.line.uptrend.xyaxis",
                               title: "nothing to bet on yet",
                               message: "the drama's still loading. check back after tonight's episode.")
                ErrorStateView { }
            }
            .padding(DS.Space.l)
        }
    }
}
