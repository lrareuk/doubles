//
//  Chyron.swift
//  The signature motif: a reality-TV lower-third banner. Magenta fill, ink text,
//  Space Mono bold uppercase, label and value justified across it.
//  Used on the recap card, episode headers, section markers, and twist beats.
//

import SwiftUI

struct Chyron: View {
    var label: String
    var value: String
    var fill: Color = DS.magenta
    var textColor: Color = DS.ink
    var marquee: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: DS.Space.m) {
            Text(label)
                .monoLabel(11, bold: true, tracking: 2)
            Spacer(minLength: DS.Space.m)
            Group {
                if marquee && !reduceMotion {
                    MarqueeText(text: value)
                } else {
                    Text(value).monoLabel(12, bold: true, tracking: 3)
                        .lineLimit(1).truncationMode(.tail).minimumScaleFactor(0.7)
                }
            }
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, DS.Space.m)
        .padding(.vertical, DS.Space.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fill)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label.lowercased()): \(value.lowercased())")
    }
}

/// A continuously scrolling value, used for the "now trending" treatment.
private struct MarqueeText: View {
    let text: String
    @State private var offset: CGFloat = 0
    @State private var runWidth: CGFloat = 0
    private var run: String { "\(text)     •     " }

    var body: some View {
        // A flexible-width band that takes the available width and CLIPS the wide
        // scrolling text to it (the text overflows, but never past the band).
        Color.clear
            .frame(height: 16)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                Text(run + run)
                    .monoLabel(12, bold: true, tracking: 3)
                    .lineLimit(1)
                    .fixedSize()
                    .background(
                        GeometryReader { g in
                            Color.clear.onAppear { runWidth = g.size.width / 2 }
                        }
                    )
                    .offset(x: offset)
            }
            .clipped()
            .onChange(of: runWidth) { _, w in
                guard w > 0 else { return }
                withAnimation(.linear(duration: max(6, Double(w) / 30)).repeatForever(autoreverses: false)) {
                    offset = -w
                }
            }
    }
}

#Preview("Chyron") {
    ScreenBackground {
        VStack(spacing: DS.Space.l) {
            Chyron(label: "now trending", value: "MAYA")
            Chyron(label: "plot twist", value: "PRIYA PLAYED EVERYONE", fill: DS.magenta)
            Chyron(label: "ep 04", value: "the group chat", fill: DS.acid, textColor: DS.ink)
            Chyron(label: "now trending", value: "maya vs priya round three", marquee: true)
        }
        .padding(DS.Space.l)
    }
}
