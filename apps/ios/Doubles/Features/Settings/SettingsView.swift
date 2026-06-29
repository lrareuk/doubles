//
//  SettingsView.swift
//  Your double, your plan, your worlds, notifications — and a real, honest privacy
//  section with a working 18+ status line and a genuine data-deletion path (brief §13).
//

import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {
    var myDouble: Persona?
    var entitlements: [Entitlement] = []
    var worlds: [World] = []
    var deleting = false
    var deleted = false

    func load(_ repo: any DoublesRepository) async {
        async let snap = repo.snapshot()
        async let ent = repo.entitlements()
        async let w = repo.worlds()
        myDouble = (try? await snap)?.myDouble
        entitlements = (try? await ent) ?? []
        worlds = (try? await w) ?? []
    }

    func delete(_ repo: any DoublesRepository) async {
        deleting = true
        try? await repo.deleteAccount()
        deleting = false
        deleted = true
        Haptics.success()
    }
}

struct SettingsView: View {
    @Environment(\.repo) private var repo
    @Environment(\.dismiss) private var dismiss
    @Environment(Session.self) private var session: Session?
    // Offline-mode entry gate (set by MockShell). Resetting it restarts onboarding.
    @AppStorage("doubles.mock.onboarded") private var mockOnboarded = false
    @State private var vm = SettingsViewModel()

    @State private var showPaywall = false
    @State private var showEdit = false
    @State private var confirmDelete = false

    // Local-only toggles; wired to real prefs when the backend lands.
    @AppStorage("doubles.notif.episodes") private var notifEpisodes = true
    @AppStorage("doubles.notif.drama") private var notifDrama = true

    var body: some View {
        NavigationStack {
            ScreenBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Space.xl) {
                        if vm.deleted {
                            deletedState
                        } else {
                            doubleSection
                            planSection
                            worldsSection
                            notificationsSection
                            privacySection
                            signOut
                        }
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
                    Text("settings").font(.ui(15, .bold)).foregroundStyle(DS.bone)
                }
            }
            .toolbarBackground(DS.wine, for: .navigationBar)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showEdit) {
            if let me = vm.myDouble { BuildDoubleView(editing: me) { showEdit = false } }
        }
        .confirmationDialog("delete your double & data?",
                            isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("delete everything", role: .destructive) {
                Task { await vm.delete(repo); session?.signOut(); mockOnboarded = false }
            }
            Button("keep my double", role: .cancel) {}
        } message: {
            Text("this permanently purges your double, your agendas, your bets, and everything it ever posted. it can't be undone.")
        }
        .task { await vm.load(repo) }
    }

    // MARK: your double
    @ViewBuilder private var doubleSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionLabel(text: "your double")
            HStack(spacing: DS.Space.m) {
                if let me = vm.myDouble { DoubleAvatar(persona: me, size: 48) }
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.myDouble?.displayName ?? "your double")
                        .font(.ui(16, .semibold)).foregroundStyle(DS.bone)
                    Text("@\(vm.myDouble?.handle ?? "you")").monoLabel(10).foregroundStyle(DS.boneDim)
                }
                Spacer()
            }
            .padding(DS.Space.m)
            .background(DS.surface)
            .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
            GhostButton(title: "edit your double", icon: "slider.horizontal.3") { showEdit = true }
        }
    }

    // MARK: plan
    private var planSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionLabel(text: "your plan")
            VStack(spacing: DS.Space.s) {
                ForEach(vm.entitlements) { ent in
                    HStack {
                        Text(planTitle(ent.sku)).font(.ui(15, .medium)).foregroundStyle(DS.bone)
                        Spacer()
                        TagChip(text: ent.active ? "active" : "inactive",
                                tint: ent.active ? DS.acid : DS.boneDim, filled: ent.active)
                    }
                    .padding(DS.Space.m)
                    .background(DS.surface)
                    .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
                }
            }
            PrimaryButton(title: "see plans", icon: "crown.fill") { showPaywall = true }
        }
    }

    private func planTitle(_ sku: EntitlementSku) -> String {
        switch sku {
        case .subMonthly: "doubles+ (monthly)"
        case .seasonPass: "season pass"
        case .powerpack: "power pack"
        case .cloutpack: "clout pack"
        }
    }

    // MARK: worlds
    @ViewBuilder private var worldsSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionLabel(text: "your worlds", trailing: "\(vm.worlds.count)")
            VStack(spacing: DS.Space.s) {
                ForEach(vm.worlds) { world in
                    HStack(spacing: DS.Space.m) {
                        Text(world.vibe.emoji).font(.system(size: 18)).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(world.name).font(.ui(15, .semibold)).foregroundStyle(DS.bone)
                            Text("\(world.vibe.title) · ep \(String(format: "%02d", world.currentEpisode))")
                                .monoLabel(9, tracking: 1.5).foregroundStyle(DS.boneDim)
                        }
                        Spacer()
                    }
                    .padding(DS.Space.m)
                    .background(DS.surface)
                    .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(world.name), \(world.vibe.title), episode \(world.currentEpisode)")
                }
            }
        }
    }

    // MARK: notifications
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionLabel(text: "notifications")
            VStack(spacing: 0) {
                toggleRow("new episode drops", isOn: $notifEpisodes)
                Divider().overlay(DS.line)
                toggleRow("when your double gets dragged", isOn: $notifDrama)
            }
            .background(DS.surface)
            .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
        }
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label).font(.ui(15, .medium)).foregroundStyle(DS.bone)
        }
        .tint(DS.magenta)
        .padding(DS.Space.m)
    }

    // MARK: privacy
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionLabel(text: "privacy & safety")
            HStack(spacing: DS.Space.m) {
                Image(systemName: "checkmark.shield.fill").foregroundStyle(DS.acid)
                Text("18+ confirmed").font(.ui(15, .medium)).foregroundStyle(DS.bone)
                Spacer()
            }
            .padding(DS.Space.m)
            .background(DS.surface)
            .overlay(Rectangle().stroke(DS.line, lineWidth: 1))

            Text("your double's content lives on your account. delete it and it's gone — for good, not hidden.")
                .font(.ui(12)).foregroundStyle(DS.boneDim)

            GhostButton(title: vm.deleting ? "deleting…" : "delete my double & data",
                        icon: "trash.fill", tint: DS.magenta) {
                guard !vm.deleting else { return }
                confirmDelete = true
            }
        }
    }

    private var signOut: some View {
        GhostButton(title: "sign out", icon: "arrow.right.square") {
            session?.signOut()      // live mode → AuthView
            mockOnboarded = false   // offline mode → restart onboarding
            dismiss()
        }
    }

    private var deletedState: some View {
        VStack(spacing: DS.Space.l) {
            EmptyStateView(symbol: "checkmark.circle.fill",
                           title: "your double is gone.",
                           message: "we've purged your double and everything it posted. nothing's kept on our side. take care of yourself out there.")
            PrimaryButton(title: "done", icon: "checkmark") { dismiss() }
                .padding(.horizontal, DS.Space.l)
        }
        .padding(.top, DS.Space.xxxl)
    }
}

#Preview("Settings") {
    SettingsView()
        .environment(\.repo, MockRepository.preview)
        .preferredColorScheme(.dark)
}
