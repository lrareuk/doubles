//
//  RecapCard.swift
//  The growth artifact: a tabloid title card built to be screenshotted.
//  Clean wine→plum gradient (no grain/blur) so ImageRenderer rasterises cleanly.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RecapCard: View {
    var recap: Recap
    var worldName: String

    // Fixed layout so exports are consistent (× scale 3 on export).
    static let exportSize = CGSize(width: 360, height: 480)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // top strip
            HStack {
                Text("DOUBLES").font(.display(20)).foregroundStyle(DS.bone)
                Spacer()
                Text("EP \(String(format: "%02d", recap.episodeNumber))")
                    .monoLabel(12, bold: true, tracking: 3).foregroundStyle(DS.acid)
            }

            Spacer(minLength: DS.Space.l)

            // giant headline, one word magenta
            headline
                .padding(.bottom, DS.Space.l)

            // pull quote
            Text(recap.pullQuote)
                .font(.ui(17).italic())
                .foregroundStyle(DS.bone)
                .fixedSize(horizontal: false, vertical: true)
            Text(recap.attribution)
                .monoLabel(10, tracking: 2).foregroundStyle(DS.boneDim)
                .padding(.top, DS.Space.xs)

            Spacer(minLength: DS.Space.l)

            Chyron(label: "now trending", value: recap.trendingName)

            // footer watermark — a screenshot markets the app
            HStack {
                Text("made with Doubles").monoLabel(9, tracking: 1.5).foregroundStyle(DS.boneDim)
                Spacer()
                Text("@\(worldName.replacingOccurrences(of: " ", with: ""))")
                    .monoLabel(9, tracking: 1.5).foregroundStyle(DS.rose)
            }
            .padding(.top, DS.Space.m)
        }
        .padding(DS.Space.xl)
        .frame(width: RecapCard.exportSize.width, height: RecapCard.exportSize.height, alignment: .topLeading)
        .background(
            LinearGradient(colors: [DS.wine, DS.plum], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .overlay(Rectangle().stroke(DS.magenta, lineWidth: 2))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("recap card. episode \(recap.episodeNumber). \(recap.headline.lowercased()). now trending \(recap.trendingName.lowercased())")
    }

    private var headline: some View {
        let words = recap.headline.split(separator: " ").map(String.init)
        return Text(words.map { word in
            let isAccent = word.uppercased() == recap.accentWord.uppercased()
            var s = AttributedString(word + " ")
            s.foregroundColor = isAccent ? DS.magenta : DS.bone
            return s
        }.reduce(AttributedString(), +))
        .font(.display(44))
        .lineSpacing(-2)
        .minimumScaleFactor(0.5)
    }
}

/// Renders the fixed-size RecapCard scaled to exactly fit the available width, so
/// it never overflows on any device (it's a fixed 360×480 export canvas otherwise).
struct FittedRecapCard: View {
    var recap: Recap
    var worldName: String

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / RecapCard.exportSize.width
            RecapCard(recap: recap, worldName: worldName)
                .scaleEffect(scale, anchor: .topLeading)
        }
        .aspectRatio(RecapCard.exportSize.width / RecapCard.exportSize.height, contentMode: .fit)
    }
}

// MARK: - Export

enum RecapExporter {
    /// Render the card to a high-resolution UIImage (scale 3). Fonts must be registered.
    @MainActor static func image(for recap: Recap, worldName: String) -> UIImage? {
        FontRegistrar.registerAll()
        let renderer = ImageRenderer(content: RecapCard(recap: recap, worldName: worldName))
        renderer.scale = 3
        return renderer.uiImage
    }
}

/// A tasteful share affordance for the recap card (used on Today).
struct RecapShareButton: View {
    var recap: Recap
    var worldName: String
    @State private var rendered: Image?

    var body: some View {
        Group {
            if let rendered {
                ShareLink(item: rendered,
                          preview: SharePreview("episode \(recap.episodeNumber) recap", image: rendered)) {
                    label
                }
            } else {
                Button { render() } label: { label }
            }
        }
        .task { render() }
    }

    private var label: some View {
        HStack(spacing: DS.Space.s) {
            Image(systemName: "square.and.arrow.up")
            Text("share").monoLabel(11, bold: true, tracking: 2)
        }
        .foregroundStyle(DS.ink)
        .padding(.horizontal, DS.Space.l).padding(.vertical, DS.Space.s)
        .background(DS.acid)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
    }

    @MainActor private func render() {
        if let ui = RecapExporter.image(for: recap, worldName: worldName) {
            rendered = Image(uiImage: ui)
        }
    }
}

#Preview("RecapCard") {
    let recap = Recap(
        episodeNumber: 4, headline: "MAYA TORCHED THE GROUP CHAT", accentWord: "TORCHED",
        pullQuote: "“i said what i said. twice.”", attribution: "— maya · ep 04", trendingName: "MAYA",
        narrative: "", highlights: [], gatedBeatIds: [])
    return ScreenBackground {
        VStack(spacing: DS.Space.l) {
            RecapCard(recap: recap, worldName: "the group chat")
            RecapShareButton(recap: recap, worldName: "the group chat")
        }
        .padding(DS.Space.l)
    }
}
