//
//  Pills.swift
//  StatPill, SectionLabel, CountUpNumber, CloutCounter.
//

import SwiftUI

struct StatPill: View {
    var label: String
    var value: Int
    var tint: Color = DS.rose

    var body: some View {
        HStack(spacing: DS.Space.xs) {
            Text(label).monoLabel(9, tracking: 1)
            Text("\(value)").monoLabel(10, bold: true, tracking: 1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, DS.Space.s)
        .padding(.vertical, 4)
        .overlay(Capsule().stroke(tint.opacity(0.5), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(value)")
    }
}

/// Status chip (pill is allowed here per the brief).
struct TagChip: View {
    var text: String
    var tint: Color
    var filled: Bool = false
    var body: some View {
        Text(text)
            .monoLabel(9, bold: true, tracking: 1.5)
            .foregroundStyle(filled ? DS.ink : tint)
            .padding(.horizontal, DS.Space.s).padding(.vertical, 4)
            .background(filled ? tint : .clear)
            .overlay(filled ? nil : Capsule().stroke(tint.opacity(0.6), lineWidth: 1))
            .clipShape(Capsule())
    }
}

struct SectionLabel: View {
    var text: String
    var trailing: String? = nil
    var body: some View {
        HStack(spacing: DS.Space.m) {
            Text(text).monoLabel(11, bold: true, tracking: 2.5).foregroundStyle(DS.rose)
            Rectangle().fill(DS.line).frame(height: 1)
            if let trailing {
                Text(trailing).monoLabel(10, tracking: 1.5).foregroundStyle(DS.boneDim)
            }
        }
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel(text.lowercased())
    }
}

/// Animated number with a colour flash: acid for up, magenta for down.
struct CountUpNumber: View {
    var value: Int
    var font: Font = .mono(28, bold: true)
    @State private var flash: Color? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text("\(value)")
            .font(font)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .contentTransition(.numericText(value: Double(value)))
            .foregroundStyle(flash ?? DS.bone)
            .onChange(of: value) { old, new in
                guard !reduceMotion else { return }
                flash = new >= old ? DS.acid : DS.magenta
                Haptics.tap()
                withAnimation(.easeOut(duration: DS.Dur.base)) { flash = nil }
            }
            .animation(.spring(duration: DS.Dur.base), value: value)
    }
}

/// Clout balance: a big mono number with a subtle flame motif.
struct CloutCounter: View {
    var balance: Int
    var body: some View {
        HStack(spacing: DS.Space.s) {
            Image(systemName: "bolt.heart.fill").foregroundStyle(DS.magenta)
                .font(.system(size: 22))
            CountUpNumber(value: balance, font: .mono(34, bold: true))
            Text("clout").monoLabel(10, tracking: 2).foregroundStyle(DS.boneDim)
                .padding(.leading, DS.Space.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(balance) clout")
    }
}

#Preview("Pills & Counters") {
    struct Demo: View {
        @State private var clout = 1840
        var body: some View {
            ScreenBackground {
                VStack(alignment: .leading, spacing: DS.Space.xl) {
                    SectionLabel(text: "standings", trailing: "ep 04")
                    HStack { StatPill(label: "drama", value: 9, tint: DS.magenta)
                        StatPill(label: "ships", value: 7, tint: DS.acid)
                        TagChip(text: "live", tint: DS.acid, filled: true) }
                    CloutCounter(balance: clout)
                    PrimaryButton(title: "+250 clout") { clout += 250 }
                    PrimaryButton(title: "-150 clout", fill: DS.acid) { clout -= 150 }
                }
                .padding(DS.Space.l)
            }
        }
    }
    return Demo()
}
