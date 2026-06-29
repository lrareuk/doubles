//
//  PaywallView.swift
//  Honest billing (hard requirement, brief §13). Clear prices + cadence, real
//  benefits, restore purchases, and an obvious "cancel anytime" line. UI only —
//  no real IAP wired. Never sleazy.
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var confirmed = false

    private let subBenefits = [
        "more power moves every single day",
        "run multiple worlds at once",
        "full, uncut recaps — every gated beat",
        "exclusive double cosmetics & accent packs",
    ]
    private let passBenefits = [
        "everything in doubles+ for one season",
        "a season-one finale badge on your double",
        "early access to next season's cast slots",
    ]

    var body: some View {
        NavigationStack {
            ScreenBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Space.xl) {
                        header
                        subscriptionCard
                        seasonPassCard
                        honestyBlock
                        Button("restore purchases") { Haptics.tap() }
                            .monoLabel(11, bold: true, tracking: 2)
                            .foregroundStyle(DS.boneDim)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(DS.Space.l)
                    .padding(.bottom, DS.Space.xxxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("close") { dismiss() }.foregroundStyle(DS.boneDim).font(.ui(15))
                }
                ToolbarItem(placement: .principal) {
                    Text("plans").font(.ui(15, .bold)).foregroundStyle(DS.bone)
                }
            }
            .toolbarBackground(DS.wine, for: .navigationBar)
            .alert("you're set (almost).", isPresented: $confirmed) {
                Button("got it", role: .cancel) {}
            } message: {
                Text("billing isn't wired up in this build — nothing was charged. this is where the real subscription would kick in.")
            }
        }
        .presentationDetents([.large])
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            Chyron(label: "doubles+", value: "THE UNCUT SEASON", fill: DS.acid)
            Text("get the uncut season")
                .font(.display(40)).foregroundStyle(DS.bone)
                .accessibilityLabel("get the uncut season")
            Text("the drama runs whether you pay or not. this just gives you the director's cut.")
                .font(.ui(14)).foregroundStyle(DS.boneDim)
        }
    }

    private var subscriptionCard: some View {
        planCard(title: "doubles+",
                 price: "£6.99",
                 cadence: "/ month",
                 tagline: "best for keeping up every day",
                 benefits: subBenefits,
                 fill: DS.magenta,
                 cta: "subscribe — £6.99 / month")
    }

    private var seasonPassCard: some View {
        planCard(title: "season pass",
                 price: "£14.99",
                 cadence: "/ season",
                 tagline: "one payment, no auto-renew",
                 benefits: passBenefits,
                 fill: DS.acid,
                 cta: "get the season pass — £14.99")
    }

    private func planCard(title: String, price: String, cadence: String, tagline: String,
                          benefits: [String], fill: Color, cta: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.display(26)).foregroundStyle(DS.bone)
                    .accessibilityLabel(title)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: DS.Space.xs) {
                    Text(price).font(.mono(22, bold: true)).foregroundStyle(fill)
                    Text(cadence).monoLabel(10, tracking: 1.5).foregroundStyle(DS.boneDim)
                }
            }
            Text(tagline).font(.ui(13)).foregroundStyle(DS.boneDim)
            VStack(alignment: .leading, spacing: DS.Space.s) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack(alignment: .top, spacing: DS.Space.s) {
                        Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                            .foregroundStyle(fill).padding(.top, 3)
                        Text(benefit).font(.ui(14)).foregroundStyle(DS.bone)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            PrimaryButton(title: cta, fill: fill) { Haptics.success(); confirmed = true }
        }
        .padding(DS.Space.l)
        .background(DS.surface)
        .overlay(Rectangle().stroke(fill.opacity(0.4), lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    private var honestyBlock: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            HStack(spacing: DS.Space.s) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(DS.acid)
                Text("cancel anytime — manage in settings")
                    .font(.ui(14, .semibold)).foregroundStyle(DS.bone)
            }
            Text("monthly auto-renews until you cancel. the season pass is a one-off — it never renews. no hidden charges, no dark patterns. prices shown are placeholders for this build.")
                .font(.ui(12)).foregroundStyle(DS.boneDim)
        }
        .padding(DS.Space.m)
        .background(DS.surfaceLift)
        .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
    }
}

#Preview("Paywall") {
    PaywallView()
        .environment(\.repo, MockRepository.preview)
        .preferredColorScheme(.dark)
}
