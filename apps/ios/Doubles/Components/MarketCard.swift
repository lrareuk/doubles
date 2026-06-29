//
//  MarketCard.swift
//  A prediction market with selectable options, odds, a stake stepper, and a
//  decisive confirm. Locks on placement.
//

import SwiftUI

struct StakeStepper: View {
    @Binding var stake: Int
    var maxStake: Int
    private let quick = [50, 100, 250]

    var body: some View {
        VStack(spacing: DS.Space.s) {
            HStack(spacing: DS.Space.l) {
                stepButton("minus") { stake = max(0, stake - 50) }
                CountUpNumber(value: stake, font: .mono(24, bold: true))
                    .frame(minWidth: 70)
                stepButton("plus") { stake = min(maxStake, stake + 50) }
            }
            HStack(spacing: DS.Space.s) {
                ForEach(quick, id: \.self) { q in
                    Button("+\(q)") { Haptics.tap(); stake = min(maxStake, stake + q) }
                        .monoLabel(10, bold: true)
                        .foregroundStyle(DS.bone)
                        .padding(.horizontal, DS.Space.s)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                        .overlay(Capsule().stroke(DS.line, lineWidth: 1))
                        .accessibilityLabel("add \(q) clout")
                }
                Button("all in") { Haptics.commit(); stake = maxStake }
                    .monoLabel(10, bold: true).foregroundStyle(DS.magenta)
                    .padding(.horizontal, DS.Space.s)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                    .overlay(Capsule().stroke(DS.magenta.opacity(0.6), lineWidth: 1))
                    .accessibilityLabel("stake all your clout")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.tap(); action() }) {
            Image(systemName: symbol).font(.system(size: 16, weight: .bold))
                .foregroundStyle(DS.bone)
                .frame(width: 44, height: 44)
                .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
        }
        .accessibilityLabel(symbol == "minus" ? "decrease stake" : "increase stake")
    }
}

struct MarketCard: View {
    var market: Market
    var clout: Int
    var onPlace: (_ optionKey: String, _ stake: Int) async -> Void

    @State private var selected: String?
    @State private var stake = 100
    @State private var placing = false
    @State private var placed = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack {
                Text("resolves ep \(market.resolvesOnEpisode)").monoLabel(9, tracking: 1.5).foregroundStyle(DS.rose)
                Spacer()
                if placed { TagChip(text: "bet placed", tint: DS.acid, filled: true) }
            }
            Text(market.question).font(.ui(17, .semibold)).foregroundStyle(DS.bone)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: DS.Space.s) {
                ForEach(market.options) { option in
                    optionRow(option)
                }
            }

            if selected != nil && !placed {
                Divider().overlay(DS.line)
                StakeStepper(stake: $stake, maxStake: clout)
                PrimaryButton(title: placing ? "placing…" : "place bet · \(stake)",
                              icon: "checkmark.seal.fill",
                              isEnabled: stake > 0 && stake <= clout && !placing) {
                    place()
                }
                if stake > clout {
                    Text("not enough clout. top up or stake less.")
                        .font(.ui(12)).foregroundStyle(DS.magenta)
                }
            }
        }
        .padding(DS.Space.l)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay(Rectangle().stroke(placed ? DS.acid.opacity(0.5) : DS.line, lineWidth: 1))
        .opacity(placed ? 0.85 : 1)
        .animation(.spring(duration: DS.Dur.base), value: selected)
    }

    private func optionRow(_ option: MarketOption) -> some View {
        let isSel = selected == option.key
        return Button {
            Haptics.tap()
            selected = isSel ? nil : option.key
        } label: {
            HStack {
                Image(systemName: isSel ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSel ? DS.magenta : DS.boneDim)
                Text(option.label).font(.ui(15, .medium)).foregroundStyle(DS.bone)
                Spacer()
                Text("×\(String(format: "%.1f", option.multiplier))")
                    .monoLabel(12, bold: true).foregroundStyle(DS.acid)
            }
            .padding(DS.Space.m)
            .background(isSel ? DS.surfaceLift : .clear)
            .overlay(Rectangle().stroke(isSel ? DS.magenta.opacity(0.6) : DS.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(placed)
        .accessibilityLabel("\(option.label), pays \(String(format: "%.1f", option.multiplier)) times")
        .accessibilityAddTraits(isSel ? .isSelected : [])
    }

    private func place() {
        guard let key = selected else { return }
        placing = true
        Task {
            await onPlace(key, stake)
            Haptics.success()
            withAnimation(.spring(duration: DS.Dur.base)) { placed = true; placing = false }
        }
    }
}

#Preview("MarketCard") {
    let market = Market(id: "m1", question: "maya & theo: endgame or trainwreck by ep 6?",
                        options: [MarketOption(key: "endgame", label: "endgame", multiplier: 2.2),
                                  MarketOption(key: "trainwreck", label: "trainwreck", multiplier: 1.6)],
                        status: .open, resolvesOnEpisode: 6, winningOption: nil)
    return ScreenBackground {
        ScrollView { MarketCard(market: market, clout: 1840) { _, _ in } .padding(DS.Space.l) }
    }
}
