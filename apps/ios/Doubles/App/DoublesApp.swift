//
//  DoublesApp.swift
//  Entry point. Registers brand fonts, drives auth, and injects the LIVE
//  APIRepository once signed in. Social screens sit behind the 18+ confirmation
//  + a real Supabase session (safety, brief §13).
//

import SwiftUI

@main
struct DoublesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    init() { FontRegistrar.registerAll() }

    var body: some Scene {
        WindowGroup {
            RootShell()
                .preferredColorScheme(.dark)
                .tint(DS.magenta)
        }
    }
}

struct RootShell: View {
    @State private var session = Session()
    // First-run flag for the LIVE path. Stays false until the user finishes the
    // whole onboarding journey, so authenticating mid-flow (step 3) doesn't yank
    // them out of onboarding into the tabs.
    @AppStorage("doubles.onboarded.live") private var onboardedLive = false

    var body: some View {
        Group {
            if Config.useMock {
                MockShell()
            } else if !onboardedLive {
                // First-run: cold open → build double → aha → save (auth) → 18+ → world…
                OnboardingFlow { onboardedLive = true }
                    .environment(session)
            } else if session.isAuthenticated, let token = session.accessToken, let uid = session.userId {
                LiveGate(token: token, userId: uid, session: session)
                    .id(token) // rebuild if the token changes
            } else {
                // Returning, signed-out (in-memory session lost on cold launch).
                AuthView(session: session)
            }
        }
    }
}

/// Fully offline entry: runs the full designed onboarding on bundled mock data
/// (so it's demoable end-to-end with no network), then the tabs.
struct MockShell: View {
    @AppStorage("doubles.mock.onboarded") private var onboarded = false
    private let repo = MockRepository()

    var body: some View {
        if onboarded {
            MainTabView().environment(\.repo, repo)
        } else {
            OnboardingFlow { onboarded = true }.environment(\.repo, repo)
        }
    }
}

/// Once authenticated: record age assurance, find the user's world, then show the
/// tabs on the live repository — or a friendly nudge if the account has no world.
struct LiveGate: View {
    let session: Session
    @State private var repo: APIRepository
    @State private var phase: Phase = .checking

    enum Phase { case checking, ready, newUser, error(String) }

    init(token: String, userId: String, session: Session) {
        self.session = session
        _repo = State(initialValue: APIRepository(token: token, userId: userId))
    }

    var body: some View {
        Group {
            switch phase {
            case .checking:
                ScreenBackground { LoadingView(caption: "warming up the timeline…") }
            case .ready:
                MainTabView()
                    .environment(\.repo, repo)
                    .environment(session)
            case .newUser:
                NewUserView(session: session)
            case .error(let m):
                ScreenBackground { ErrorStateView(message: m) { Task { await resolve() } } }
            }
        }
        .task { await resolve() }
    }

    private func resolve() async {
        phase = .checking
        do {
            // Age is verified via Veriff during onboarding and enforced server-side
            // (requireVerified). The client never self-asserts age.
            let worlds = try await repo.worlds()
            if let token = PushManager.shared.deviceToken {
                try? await repo.registerPushToken(token)   // morning-recap push
            }
            phase = worlds.isEmpty ? .newUser : .ready
        } catch {
            phase = .error((error as? LocalizedError)?.errorDescription ?? "couldn't reach the world.")
        }
    }
}

struct MainTabView: View {
    @State private var tab: Tab = .today
    enum Tab: Hashable { case today, cast, bets, season }

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .tabItem { Label("today", systemImage: "bolt.fill") }.tag(Tab.today)
            CastView()
                .tabItem { Label("cast", systemImage: "person.2.fill") }.tag(Tab.cast)
            BetsView()
                .tabItem { Label("bets", systemImage: "chart.line.uptrend.xyaxis") }.tag(Tab.bets)
            SeasonView()
                .tabItem { Label("season", systemImage: "trophy.fill") }.tag(Tab.season)
        }
        .tint(DS.magenta)
        .toolbarBackground(DS.wine, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .task { await PushManager.shared.requestAuthorization() }
    }
}

/// Shown when a signed-in account isn't in any world yet. The live demo is seeded
/// with one populated world; this nudges to the demo cast rather than half-wiring
/// world creation.
struct NewUserView: View {
    let session: Session
    var body: some View {
        ScreenBackground {
            VStack(spacing: DS.Space.l) {
                Chyron(label: "you're early", value: "NO WORLD YET")
                EmptyStateView(symbol: "person.3.sequence.fill",
                               title: "you're not in a world yet",
                               message: "this live demo is seeded with one season — “the group chat”. sign in as the demo cast to walk straight into the drama.")
                PrimaryButton(title: "enter as the demo cast", icon: "sparkles") {
                    session.signOut()
                    Task { await session.signIn(email: Config.demoEmail, password: Config.demoPassword) }
                }
                .padding(.horizontal, DS.Space.l)
                GhostButton(title: "sign out") { session.signOut() }
                    .padding(.horizontal, DS.Space.l)
            }
            .padding(DS.Space.l)
        }
    }
}

#Preview("Main tabs (mock)") {
    MainTabView().environment(\.repo, MockRepository.preview).preferredColorScheme(.dark)
}
