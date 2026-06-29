//
//  WorldsSwitcherSheet.swift
//  Hop between your worlds. Sharp rows, current one marked, and a way to start a
//  brand-new season.
//

import SwiftUI

struct WorldsSwitcherSheet: View {
    var current: World?

    @Environment(\.repo) private var repo
    @Environment(\.dismiss) private var dismiss
    @State private var worlds: [World] = []
    @State private var loading = true

    var body: some View {
        NavigationStack {
            ScreenBackground {
                Group {
                    if loading {
                        ScrollView { FeedSkeleton().padding(DS.Space.l) }
                    } else {
                        content
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("close") { dismiss() }.foregroundStyle(DS.boneDim).font(.ui(15))
                }
                ToolbarItem(placement: .principal) {
                    Text("your worlds").font(.ui(15, .bold)).foregroundStyle(DS.bone)
                }
            }
            .toolbarBackground(DS.wine, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .task {
            worlds = (try? await repo.worlds()) ?? []
            loading = false
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.l) {
                SectionLabel(text: "switch worlds", trailing: "\(worlds.count)")
                VStack(spacing: DS.Space.s) {
                    ForEach(worlds) { world in worldRow(world) }
                }
                PrimaryButton(title: "start a new world", icon: "plus.circle.fill") {
                    Haptics.commit(); dismiss()
                }
                .padding(.top, DS.Space.s)
            }
            .padding(DS.Space.l)
            .padding(.bottom, DS.Space.xxxl)
        }
    }

    private func worldRow(_ world: World) -> some View {
        let isCurrent = world.id == current?.id
        return Button {
            Haptics.tap(); dismiss()
        } label: {
            HStack(spacing: DS.Space.m) {
                Text(world.vibe.emoji).font(.system(size: 24))
                VStack(alignment: .leading, spacing: 2) {
                    Text(world.name).font(.display(22)).foregroundStyle(DS.bone)
                        .accessibilityLabel(world.name)
                    HStack(spacing: DS.Space.s) {
                        Text(world.vibe.title).monoLabel(9, tracking: 1.5).foregroundStyle(DS.boneDim)
                        Text("·").foregroundStyle(DS.boneDim)
                        Text("ep \(String(format: "%02d", world.currentEpisode))")
                            .monoLabel(9, bold: true, tracking: 1.5).foregroundStyle(DS.acid)
                        Text("·").foregroundStyle(DS.boneDim)
                        Text(world.seasonStatus.rawValue).monoLabel(9, tracking: 1.5).foregroundStyle(DS.rose)
                    }
                }
                Spacer()
                if isCurrent {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(DS.magenta)
                }
            }
            .padding(DS.Space.m)
            .background(isCurrent ? DS.surfaceLift : DS.surface)
            .overlay(alignment: .leading) {
                Rectangle().fill(isCurrent ? DS.magenta : DS.line).frame(width: 3)
            }
            .overlay(Rectangle().stroke(isCurrent ? DS.magenta.opacity(0.5) : DS.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(world.name), \(world.vibe.title), episode \(world.currentEpisode)\(isCurrent ? ", current world" : "")")
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }
}

#Preview("WorldsSwitcher") {
    WorldsSwitcherSheet(current: World(id: "w1", name: "the group chat", vibe: .messy,
                                       seasonNumber: 1, seasonStatus: .active,
                                       currentEpisode: 4, nextEpisodeInHours: 6))
        .environment(\.repo, MockRepository.preview)
        .preferredColorScheme(.dark)
}
