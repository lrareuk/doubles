//
//  BetsView.swift
//  The clout casino. Stake on what your doubles do next. Open markets up top,
//  your live + settled bets below. Clout is the play currency — never real money.
//

import SwiftUI

@Observable
@MainActor
final class BetsViewModel {
    enum Phase { case loading, loaded, error }
    var phase: Phase = .loading
    var markets: [Market] = []
    var bets: [Bet] = []
    var clout: Int = 0

    func load(_ repo: any DoublesRepository, initial: Bool = true) async {
        if initial { phase = .loading }
        do {
            async let snap = repo.snapshot()
            async let m = repo.markets()
            async let b = repo.myBets()
            let (snapshot, markets, bets) = try await (snap, m, b)
            clout = snapshot.cloutBalance
            self.markets = markets
            self.bets = bets
            phase = .loaded
        } catch {
            phase = .error
        }
    }

    func place(_ repo: any DoublesRepository, marketId: String, optionKey: String, stake: Int) async {
        do {
            let bet = try await repo.placeBet(marketId: marketId, optionKey: optionKey, stake: stake)
            bets.insert(bet, at: 0)
            clout -= stake
        } catch {
            Haptics.failure()
        }
    }
}

struct BetsView: View {
    @Environment(\.repo) private var repo
    @State private var vm = BetsViewModel()

    var body: some View {
        NavigationStack {
            ScreenBackground {
                content
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("bets").font(.ui(15, .bold)).foregroundStyle(DS.bone)
                        .accessibilityLabel("bets")
                }
            }
            .toolbarBackground(DS.wine, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task { await vm.load(repo) }
    }

    @ViewBuilder private var content: some View {
        switch vm.phase {
        case .loading:
            ScrollView { FeedSkeleton().padding(DS.Space.l) }
        case .error:
            ErrorStateView { Task { await vm.load(repo) } }
        case .loaded:
            loaded
        }
    }

    private var loaded: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {
                HStack {
                    CloutCounter(balance: vm.clout)
                    Spacer()
                }
                Text("play money. bet on the doubles, not real people. clout never cashes out.")
                    .font(.ui(12)).foregroundStyle(DS.boneDim)

                openMarkets
                yourBets
            }
            .padding(DS.Space.l)
            .padding(.bottom, DS.Space.xxxl)
        }
        .refreshable { await vm.load(repo, initial: false) }
    }

    @ViewBuilder private var openMarkets: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionLabel(text: "open markets", trailing: "\(vm.markets.count)")
            if vm.markets.isEmpty {
                EmptyStateView(symbol: "chart.line.uptrend.xyaxis",
                               title: "nothing to bet on yet",
                               message: "the drama's still loading. check back after tonight's episode.")
            } else {
                ForEach(vm.markets) { market in
                    MarketCard(market: market, clout: vm.clout) { optionKey, stake in
                        await vm.place(repo, marketId: market.id, optionKey: optionKey, stake: stake)
                    }
                }
            }
        }
    }

    @ViewBuilder private var yourBets: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionLabel(text: "your bets", trailing: "\(vm.bets.count)")
            if vm.bets.isEmpty {
                EmptyStateView(symbol: "ticket.fill",
                               title: "no bets riding yet",
                               message: "pick a market above and put some clout on the line.")
            } else {
                VStack(spacing: DS.Space.s) {
                    ForEach(vm.bets) { bet in betRow(bet) }
                }
            }
        }
    }

    private func betRow(_ bet: Bet) -> some View {
        HStack(alignment: .top, spacing: DS.Space.m) {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(bet.marketQuestion).font(.ui(14, .semibold)).foregroundStyle(DS.bone)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: DS.Space.s) {
                    Text("on \(bet.optionLabel)").monoLabel(10, tracking: 1.5).foregroundStyle(DS.boneDim)
                        .lineLimit(1).truncationMode(.tail).layoutPriority(1)
                    Text("·").foregroundStyle(DS.boneDim)
                    Text("stake \(bet.stake)").monoLabel(10, tracking: 1.5).foregroundStyle(DS.boneDim)
                    Text("·").foregroundStyle(DS.boneDim)
                    Text("to win \(bet.potentialPayout)").monoLabel(10, bold: true, tracking: 1.5)
                        .foregroundStyle(DS.acid)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            statusChip(bet.status)
        }
        .padding(DS.Space.m)
        .background(DS.surface)
        .overlay(alignment: .leading) { Rectangle().fill(statusTint(bet.status)).frame(width: 3) }
        .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(bet.marketQuestion). on \(bet.optionLabel), staked \(bet.stake), \(bet.status.rawValue)")
    }

    @ViewBuilder private func statusChip(_ status: BetStatus) -> some View {
        switch status {
        case .won:  TagChip(text: "won", tint: DS.acid, filled: true)
        case .lost: TagChip(text: "lost", tint: DS.magenta)
        case .open: TagChip(text: "live", tint: DS.rose)
        case .void: TagChip(text: "void", tint: DS.boneDim)
        }
    }

    private func statusTint(_ status: BetStatus) -> Color {
        switch status {
        case .won: DS.acid
        case .lost: DS.magenta
        case .open: DS.rose
        case .void: DS.boneDim
        }
    }
}

#Preview("Bets") {
    BetsView().environment(\.repo, MockRepository.preview).preferredColorScheme(.dark)
}
