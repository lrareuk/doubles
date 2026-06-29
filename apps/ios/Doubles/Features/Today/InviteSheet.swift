//
//  InviteSheet.swift
//  The viral loop: invite your real friends so their doubles join the season.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct InviteSheet: View {
    var worldName: String

    @Environment(\.repo) private var repo
    @Environment(\.dismiss) private var dismiss
    @State private var code: String?
    @State private var loading = true
    @State private var copied = false

    private var shareText: String {
        let c = code ?? ""
        return "i started a season on Doubles 👀 my double is already plotting. join “\(worldName)” before it gets messy — invite code: \(c)"
    }

    var body: some View {
        NavigationStack {
            ScreenBackground {
                VStack(alignment: .leading, spacing: DS.Space.xl) {
                    Chyron(label: "invite", value: worldName.uppercased())

                    Text("the more friends,\nthe messier it gets.")
                        .font(.display(30)).foregroundStyle(DS.bone)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("doubles is better with your actual group. send them the code — their double joins the season and the drama compounds overnight.")
                        .font(.ui(14)).foregroundStyle(DS.boneDim)
                        .fixedSize(horizontal: false, vertical: true)

                    if loading {
                        LoadingView(caption: "minting your invite…").frame(height: 120)
                    } else {
                        codeCard
                        ShareLink(item: shareText) {
                            HStack(spacing: DS.Space.s) {
                                Image(systemName: "square.and.arrow.up")
                                Text("share invite").monoLabel(13, bold: true, tracking: 2)
                            }
                            .foregroundStyle(DS.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Space.l)
                            .background(DS.magenta)
                            .clipShape(.rect(cornerRadius: DS.Radius.card))
                            .shadow(color: DS.magenta.opacity(0.35), radius: 14, y: 4)
                        }
                        .simultaneousGesture(TapGesture().onEnded { Haptics.commit() })
                    }
                    Spacer()
                }
                .padding(DS.Space.l)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("close") { dismiss() }.foregroundStyle(DS.boneDim).font(.ui(15))
                }
                ToolbarItem(placement: .principal) {
                    Text("invite the group").font(.ui(15, .bold)).foregroundStyle(DS.bone)
                }
            }
            .toolbarBackground(DS.wine, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .task { await load() }
    }

    private var codeCard: some View {
        Button {
            #if canImport(UIKit)
            UIPasteboard.general.string = code
            #endif
            copied = true
            Haptics.success()
        } label: {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(copied ? "copied" : "their invite code · tap to copy")
                    .monoLabel(9, tracking: 2).foregroundStyle(copied ? DS.acid : DS.rose)
                Text(code ?? "—").font(.display(34)).foregroundStyle(DS.acid)
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Space.l)
            .background(DS.surface)
            .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("invite code \(code ?? ""), tap to copy")
    }

    private func load() async {
        loading = true
        code = (try? await repo.invite()) ?? "MESSY-7Q2K"
        loading = false
    }
}

#Preview("InviteSheet") {
    InviteSheet(worldName: "the group chat")
        .environment(\.repo, MockRepository.preview)
        .preferredColorScheme(.dark)
}
