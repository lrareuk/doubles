//
//  PowerMoveCard.swift
//  A selectable card for one power-move type, used in the power-move sheet.
//

import SwiftUI

struct PowerMoveCard: View {
    var type: PowerMoveType
    var isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: { Haptics.tap(); onTap() }) {
            VStack(alignment: .leading, spacing: DS.Space.s) {
                HStack {
                    Image(systemName: type.symbol)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? DS.ink : DS.magenta)
                        .frame(width: 40, height: 40)
                        .background(isSelected ? DS.magenta : DS.surfaceLift)
                        .clipShape(.rect(cornerRadius: DS.Radius.card))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark").font(.system(size: 14, weight: .bold))
                            .foregroundStyle(DS.magenta)
                    }
                }
                Text(type.title).font(.ui(16, .semibold)).foregroundStyle(DS.bone)
                Text(type.blurb).font(.ui(13)).foregroundStyle(DS.boneDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DS.Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.surface)
            .overlay(Rectangle().stroke(isSelected ? DS.magenta : DS.line, lineWidth: isSelected ? 2 : 1))
            .shadow(color: isSelected ? DS.magenta.opacity(0.3) : .clear, radius: 14, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.title). \(type.blurb)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("PowerMoveCard") {
    struct Demo: View {
        @State private var sel: PowerMoveType? = .rumour
        var body: some View {
            ScreenBackground {
                ScrollView {
                    VStack(spacing: DS.Space.m) {
                        ForEach(PowerMoveType.allCases) { t in
                            PowerMoveCard(type: t, isSelected: sel == t) { sel = t }
                        }
                    }
                    .padding(DS.Space.l)
                }
            }
        }
    }
    return Demo()
}
