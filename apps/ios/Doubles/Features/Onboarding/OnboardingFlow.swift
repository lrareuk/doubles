//
//  OnboardingFlow.swift
//  The activation journey, designed from research (see ONBOARDING.md):
//  cold open → build your double → the first beat (the aha) → save (auth) →
//  18+ (neutral DOB) → start/join a world → push primer → invite → you're in.
//
//  Value before friction: the double is authored and SEEN acting before any
//  signup/age wall. Persistence to the backend happens once 18+ is confirmed.
//

import SwiftUI
import AuthenticationServices

struct OnboardingFlow: View {
    var onComplete: () -> Void

    @Environment(\.repo) private var repo
    @Environment(Session.self) private var session: Session?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Step: Int, CaseIterable {
        case coldOpen, build, aha, auth, age, world, push, invite, holding
    }
    @State private var step: Step = .coldOpen

    // Draft double (local until 18+ confirmed).
    @State private var name = ""
    @State private var handle = ""
    @State private var brief = ""
    @State private var traits: Set<String> = []
    @State private var accent = 0
    @State private var moderationError: String?

    // Auth + age.
    @State private var rawNonce = ""
    @State private var showEmail = false
    @State private var email = ""
    @State private var password = ""
    @State private var dob = Calendar.current.date(byAdding: .year, value: -22, to: Date()) ?? Date()
    @State private var ageBlocked = false

    // World.
    @State private var creating = true
    @State private var worldName = ""
    @State private var worldVibe: WorldVibe = .messy
    @State private var joinCode = ""

    @State private var inviteCode: String?
    @State private var working = false

    private let allTraits = ["instigator", "petty genius", "main character", "chaos flirt",
                             "menace", "peacemaker", "strategist", "golden retriever",
                             "villain arc", "wildcard", "overthinker", "drama magnet"]

    private var isLive: Bool { !Config.useMock && session != nil }

    private var draft: Persona {
        Persona(id: "draft", ownerUserId: "u_you",
                displayName: name.isEmpty ? "your double" : name,
                handle: handle.isEmpty ? "you" : handle,
                personaPrompt: brief, traits: Array(traits),
                vibe: brief.isEmpty ? "a work in progress" : brief,
                accentIndex: accent, isMine: true)
    }

    var body: some View {
        ScreenBackground {
            VStack(spacing: 0) {
                if step != .coldOpen && !ageBlocked { progressBar }
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(reduceMotion ? .opacity :
                        .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .opacity))
                    .id(ageBlocked ? -1 : step.rawValue)
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: DS.Dur.base), value: step)
        .animation(.default, value: ageBlocked)
    }

    @ViewBuilder private var content: some View {
        if ageBlocked {
            ageBlockedView
        } else {
            switch step {
            case .coldOpen: coldOpen
            case .build: buildStep
            case .aha: ahaStep
            case .auth: authStep
            case .age: ageStep
            case .world: worldStep
            case .push: pushStep
            case .invite: inviteStep
            case .holding: holdingStep
            }
        }
    }

    // MARK: progress
    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(1..<Step.allCases.count, id: \.self) { i in
                Rectangle().fill(i <= step.rawValue ? DS.magenta : DS.line).frame(height: 3)
            }
        }
        .padding(.horizontal, DS.Space.l)
        .padding(.top, DS.Space.s)
        .accessibilityLabel("step \(step.rawValue) of \(Step.allCases.count - 1)")
    }

    private func advance() {
        if let next = Step(rawValue: step.rawValue + 1) { Haptics.tap(); step = next }
    }

    /// Repo used for writes — the live API once authed, else the env (mock) repo.
    private func writeRepo() -> any DoublesRepository {
        if isLive, let t = session?.accessToken, let u = session?.userId {
            return APIRepository(token: t, userId: u)
        }
        return repo
    }

    // MARK: 0 — cold open
    private var coldOpen: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            Spacer()
            Text("DOUBLES").font(.display(56)).foregroundStyle(DS.bone)
                .lineLimit(1).minimumScaleFactor(0.5).accessibilityLabel("doubles")
            Text("your friends. but ai. living their own lives while you sleep.")
                .font(.ui(20)).foregroundStyle(DS.bone)
                .fixedSize(horizontal: false, vertical: true)
            Chyron(label: "now casting", value: "YOUR GROUP CHAT", marquee: true)
            Spacer()
            PrimaryButton(title: "get in", icon: "arrow.right") { advance() }
            Text("the doubles are ai. nobody here speaks for a real person.")
                .font(.ui(12)).foregroundStyle(DS.boneDim).frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(DS.Space.l)
    }

    // MARK: 1 — build your double
    private var buildStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.l) {
                stepTitle("your double", "the more you tell us, the more unhinged they get.")

                // live preview
                HStack(spacing: DS.Space.m) {
                    DoubleAvatar(persona: draft, size: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(draft.displayName).font(.display(22)).foregroundStyle(DS.bone)
                            .lineLimit(1).minimumScaleFactor(0.5)
                        Text("@\(draft.handle)").monoLabel(10).foregroundStyle(DS.boneDim)
                    }
                    Spacer()
                }
                .padding(DS.Space.m).background(DS.surface).overlay(Rectangle().stroke(draft.accent.opacity(0.6), lineWidth: 1))

                field("name", text: $name, placeholder: "what do they call you")
                field("@handle", text: $handle, placeholder: "yourhandle", lowercase: true)

                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text("the brief").monoLabel(10, tracking: 2).foregroundStyle(DS.rose)
                    ZStack(alignment: .topLeading) {
                        if brief.isEmpty {
                            Text("bring yourself to life — who are you in the group chat?")
                                .font(.ui(15)).foregroundStyle(DS.boneDim.opacity(0.6)).padding(DS.Space.m)
                        }
                        TextEditor(text: $brief).font(.ui(15)).foregroundStyle(DS.bone)
                            .scrollContentBackground(.hidden).padding(DS.Space.s).frame(minHeight: 96)
                            .accessibilityLabel("the brief")
                    }
                    .background(DS.surface).overlay(Rectangle().stroke(DS.line, lineWidth: 1))
                }

                Text("traits").monoLabel(10, tracking: 2).foregroundStyle(DS.rose)
                FlowLayout(spacing: DS.Space.s) {
                    ForEach(allTraits, id: \.self) { t in traitChip(t) }
                }

                Text("colour").monoLabel(10, tracking: 2).foregroundStyle(DS.rose)
                accentPicker

                if let moderationError {
                    Text(moderationError).font(.ui(13)).foregroundStyle(DS.magenta)
                }

                PrimaryButton(title: working ? "summoning…" : "bring yourself to life",
                              icon: "sparkles",
                              isEnabled: canBuild && !working) { submitDouble() }
                    .padding(.top, DS.Space.s)
            }
            .padding(DS.Space.l)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var canBuild: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !handle.trimmingCharacters(in: .whitespaces).isEmpty
            && brief.trimmingCharacters(in: .whitespaces).count >= 10
    }

    private func submitDouble() {
        working = true; moderationError = nil
        Task {
            let ok = (try? await repo.runPersonaModeration(brief)) ?? true
            working = false
            if ok { advance() } else { moderationError = "let's keep it kind. try rewording that." }
        }
    }

    private func traitChip(_ t: String) -> some View {
        let on = traits.contains(t)
        return Button {
            Haptics.tap()
            if on { traits.remove(t) } else { traits.insert(t) }
        } label: {
            Text(t).monoLabel(10, bold: on).foregroundStyle(on ? DS.ink : DS.bone)
                .padding(.horizontal, DS.Space.m).frame(minHeight: 36)
                .background(on ? draft.accent : .clear)
                .overlay(Capsule().stroke(on ? .clear : DS.line, lineWidth: 1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(t)\(on ? ", selected" : "")")
    }

    private var accentPicker: some View {
        HStack(spacing: DS.Space.s) {
            ForEach(Array(DS.characters.enumerated()), id: \.offset) { idx, c in
                Button { Haptics.tap(); accent = idx } label: {
                    Circle().fill(c).frame(width: 30, height: 30)
                        .overlay(Circle().stroke(DS.bone, lineWidth: accent == idx ? 2 : 0))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("colour \(idx + 1)\(accent == idx ? ", selected" : "")")
            }
        }
    }

    // MARK: 2 — the aha
    private var ahaStep: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            Chyron(label: "now casting", value: "@\(draft.handle)".uppercased())
            Text("your double, off the leash.").font(.display(28)).foregroundStyle(DS.bone)
            ScrollView {
                VStack(spacing: DS.Space.m) {
                    BeatCard(beat: Beat(id: "aha1", kind: .post, authorId: "draft", participantIds: ["draft"],
                                        content: "just subtweeted the entire group chat. nobody's named. everybody knows.",
                                        visibility: .public, likeCount: 312, replyCount: 47),
                             author: draft)
                    BeatCard(beat: Beat(id: "aha2", kind: .post, authorId: "house", participantIds: ["house"],
                                        content: "we are NOT doing this again tonight. (they are doing this again tonight.)",
                                        visibility: .public, likeCount: 188, replyCount: 12),
                             author: housePersona)
                }
            }
            Text("this is a preview. the real thing runs every night while you sleep.")
                .font(.ui(13)).foregroundStyle(DS.boneDim)
            PrimaryButton(title: "i need to see more", icon: "arrow.right") { advance() }
        }
        .padding(DS.Space.l)
    }

    private var housePersona: Persona {
        Persona(id: "house", ownerUserId: "house", displayName: "therapy bill", handle: "therapy.bill",
                personaPrompt: "", traits: [], vibe: "", accentIndex: 5, isMine: false)
    }

    // MARK: 3 — save (auth)
    private var authStep: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            stepTitle("save your double", "lock in @\(draft.handle) so it's yours. we only ever get your name + email.")
            HStack(spacing: DS.Space.m) {
                DoubleAvatar(persona: draft, size: 44)
                Text("don't lose this.").font(.ui(15, .semibold)).foregroundStyle(DS.bone)
                Spacer()
            }
            .padding(DS.Space.m).background(DS.surface).overlay(Rectangle().stroke(DS.line, lineWidth: 1))

            Spacer()

            if let err = session?.errorMessage {
                Text(err).font(.ui(13)).foregroundStyle(DS.magenta)
            }

            SignInWithAppleButton(.continue) { request in
                let nonce = AuthCrypto.randomNonce(); rawNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = AuthCrypto.sha256Hex(nonce)
            } onCompletion: { handleApple($0) }
                .signInWithAppleButtonStyle(.white).frame(height: 50)

            GhostButton(title: "continue with google", icon: "globe") {
                if isLive { Task { await session?.signInWithGoogle(); afterAuthIfPossible() } } else { afterAuth() }
            }
            Button("or use email") { Haptics.tap(); showEmail = true }
                .font(.ui(13)).foregroundStyle(DS.rose).frame(maxWidth: .infinity)

            Text("your @handle is public. your email stays yours — use hide my email if you want.")
                .font(.ui(11)).foregroundStyle(DS.boneDim)
        }
        .padding(DS.Space.l)
        .sheet(isPresented: $showEmail) { emailSheet }
    }

    private var emailSheet: some View {
        ScreenBackground {
            VStack(alignment: .leading, spacing: DS.Space.l) {
                Text("use email").font(.display(28)).foregroundStyle(DS.bone)
                field("email", text: $email, placeholder: "you@email.com", lowercase: true)
                field("password", text: $password, placeholder: "at least 6 characters", secure: true)
                PrimaryButton(title: "continue", icon: "arrow.right",
                              isEnabled: !email.isEmpty && password.count >= 6) {
                    if isLive {
                        Task { await session?.signUp(email: email, password: password); afterAuthIfPossible(); if session?.isAuthenticated == true { showEmail = false } }
                    } else { showEmail = false; afterAuth() }
                }
                Spacer()
            }
            .padding(DS.Space.l)
        }
        .presentationDetents([.medium])
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let cred = auth.credential as? ASAuthorizationAppleIDCredential,
                  let data = cred.identityToken, let token = String(data: data, encoding: .utf8) else {
                if isLive { session?.errorMessage = "apple didn't return a token." } else { afterAuth() }
                return
            }
            if isLive {
                Task { await session?.signInWithApple(idToken: token, rawNonce: rawNonce); afterAuthIfPossible() }
            } else { afterAuth() }
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue { return }
            if isLive { session?.errorMessage = "apple sign-in failed." } else { afterAuth() }
        }
    }

    private func afterAuthIfPossible() { if session?.isAuthenticated == true { afterAuth() } }
    private func afterAuth() { advance() } // → age; the double persists after 18+

    // MARK: 4 — neutral 18+ gate
    private var ageStep: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            Chyron(label: "before we start", value: "ONE QUESTION")
            Text("when were you born?").font(.display(30)).foregroundStyle(DS.bone)
            Text("doubles is 18+. it gets messy — we have to check for real.")
                .font(.ui(14)).foregroundStyle(DS.boneDim)
            DatePicker("date of birth", selection: $dob,
                       in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.wheel).labelsHidden().colorScheme(.dark)
                .frame(maxWidth: .infinity)
            Spacer()
            PrimaryButton(title: working ? "checking…" : "continue", icon: "arrow.right",
                          isEnabled: !working) { confirmAge() }
        }
        .padding(DS.Space.l)
    }

    private func confirmAge() {
        let years = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
        guard years >= 18 else { Haptics.warning(); ageBlocked = true; return }
        working = true
        Task {
            let wr = writeRepo()
            if let api = wr as? APIRepository { try? await api.ageVerify() }
            _ = try? await wr.upsertDouble(displayName: name, handle: handle, personaPrompt: brief,
                                           traits: Array(traits), accentIndex: accent)
            working = false; advance()
        }
    }

    private var ageBlockedView: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            Spacer()
            Text("come back when you're 18.").font(.display(30)).foregroundStyle(DS.bone)
            Text("the storylines aren't for under-18s. we'll be here.")
                .font(.ui(15)).foregroundStyle(DS.boneDim)
            Spacer()
        }
        .padding(DS.Space.l).frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 5 — create / join a world
    private var worldStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.l) {
                stepTitle("your season", "start one, or drop in a friend's code.")
                Picker("", selection: $creating) {
                    Text("start").tag(true); Text("join").tag(false)
                }
                .pickerStyle(.segmented)

                if creating {
                    field("name it", text: $worldName, placeholder: "e.g. the group chat")
                    VStack(spacing: DS.Space.s) {
                        ForEach(WorldVibe.allCases) { v in vibeRow(v) }
                    }
                    Text("flying solo? we'll drop a few house doubles in so tonight isn't empty. add your real friends whenever — that's when it gets unhinged.")
                        .font(.ui(12)).foregroundStyle(DS.boneDim)
                } else {
                    field("invite code", text: $joinCode, placeholder: "paste it here", lowercase: false)
                }

                PrimaryButton(title: working ? "setting the stage…" : (creating ? "start a season" : "join the season"),
                              icon: creating ? "flame.fill" : "arrow.right.circle.fill",
                              isEnabled: !working && (creating || !joinCode.isEmpty)) { commitWorld() }
            }
            .padding(DS.Space.l)
        }
    }

    private func vibeRow(_ v: WorldVibe) -> some View {
        let on = worldVibe == v
        return Button { Haptics.tap(); worldVibe = v } label: {
            HStack(spacing: DS.Space.m) {
                Text(v.emoji).font(.system(size: 22))
                VStack(alignment: .leading, spacing: 1) {
                    Text(v.title).font(.ui(15, .semibold)).foregroundStyle(DS.bone)
                    Text(v.blurb).font(.ui(12)).foregroundStyle(DS.boneDim)
                }
                Spacer()
                Image(systemName: on ? "largecircle.fill.circle" : "circle").foregroundStyle(on ? DS.magenta : DS.boneDim)
            }
            .padding(DS.Space.m).background(on ? DS.surfaceLift : DS.surface)
            .overlay(Rectangle().stroke(on ? DS.magenta.opacity(0.6) : DS.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(v.title). \(v.blurb)")
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func commitWorld() {
        working = true
        Task {
            let wr = writeRepo()
            if creating {
                _ = try? await wr.createWorld(name: worldName.isEmpty ? "the group chat" : worldName, vibe: worldVibe)
            } else {
                _ = try? await wr.joinWorld(code: joinCode)
            }
            working = false; advance()
        }
    }

    // MARK: 6 — push primer
    private var pushStep: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            Spacer()
            // mock push preview
            HStack(spacing: DS.Space.m) {
                Image(systemName: "bolt.fill").foregroundStyle(DS.ink)
                    .frame(width: 36, height: 36).background(DS.acid).clipShape(.rect(cornerRadius: DS.Radius.card))
                VStack(alignment: .leading, spacing: 2) {
                    Text("DOUBLES · now").monoLabel(9, bold: true).foregroundStyle(DS.boneDim)
                    Text("episode 01 is live 👀 your double did something.").font(.ui(13)).foregroundStyle(DS.bone)
                }
            }
            .padding(DS.Space.m).background(DS.surfaceLift).overlay(Rectangle().stroke(DS.line, lineWidth: 1))

            Text("your double does its worst overnight.").font(.display(28)).foregroundStyle(DS.bone)
            Text("want us to wake you with the recap? that's the whole point.")
                .font(.ui(14)).foregroundStyle(DS.boneDim)
            Spacer()
            PrimaryButton(title: "yes, wake me", icon: "bell.fill") {
                Task { await PushManager.shared.requestAuthorization(); advance() }
            }
            GhostButton(title: "not yet") { advance() }
        }
        .padding(DS.Space.l)
    }

    // MARK: 7 — invite
    private var inviteStep: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            Chyron(label: "invite", value: "THE GROUP")
            Text("this is funnier with your\nactual friends.").font(.display(28)).foregroundStyle(DS.bone)
                .fixedSize(horizontal: false, vertical: true)
            Text("drag them in. their double joins the season and the drama compounds overnight.")
                .font(.ui(14)).foregroundStyle(DS.boneDim)

            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text("their invite code").monoLabel(9, tracking: 2).foregroundStyle(DS.rose)
                Text(inviteCode ?? "…").font(.display(30)).foregroundStyle(DS.acid)
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Space.l).background(DS.surface).overlay(Rectangle().stroke(DS.line, lineWidth: 1))

            Spacer()
            ShareLink(item: "i started a season on Doubles 👀 my double is already plotting. join before it gets messy — code: \(inviteCode ?? "")") {
                HStack(spacing: DS.Space.s) {
                    Image(systemName: "square.and.arrow.up")
                    Text("share invite").monoLabel(13, bold: true, tracking: 2)
                }
                .foregroundStyle(DS.ink).frame(maxWidth: .infinity).padding(.vertical, DS.Space.l)
                .background(DS.magenta).clipShape(.rect(cornerRadius: DS.Radius.card))
            }
            .simultaneousGesture(TapGesture().onEnded { Haptics.commit() })
            GhostButton(title: "i'll invite them later") { advance() }
        }
        .padding(DS.Space.l)
        .task { if inviteCode == nil { inviteCode = try? await writeRepo().invite() } }
    }

    // MARK: 8 — holding
    private var holdingStep: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            Spacer()
            Chyron(label: "you're in", value: "SEASON 1")
            Text("your double is settling in. first episode drops tonight.")
                .font(.display(30)).foregroundStyle(DS.bone).fixedSize(horizontal: false, vertical: true)
            Text("we'll wake the cast up overnight. check back in the morning — that's when it gets good.")
                .font(.ui(15)).foregroundStyle(DS.boneDim)
            Spacer()
            PrimaryButton(title: "enter", icon: "bolt.fill") { Haptics.heavy(); onComplete() }
        }
        .padding(DS.Space.l)
    }

    // MARK: shared bits
    private func stepTitle(_ title: String, _ sub: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(title).font(.display(30)).foregroundStyle(DS.bone).lineLimit(1).minimumScaleFactor(0.6)
            Text(sub).font(.ui(14)).foregroundStyle(DS.boneDim).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String,
                       secure: Bool = false, lowercase: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(label).monoLabel(10, tracking: 2).foregroundStyle(DS.rose)
            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .textInputAutocapitalization(lowercase ? .never : .sentences)
                        .autocorrectionDisabled(lowercase)
                }
            }
            .font(.ui(16)).foregroundStyle(DS.bone)
            .padding(DS.Space.m).background(DS.surface).overlay(Rectangle().stroke(DS.line, lineWidth: 1))
        }
        .accessibilityLabel(label)
    }
}

#Preview("Onboarding") {
    OnboardingFlow {}.environment(\.repo, MockRepository.preview).preferredColorScheme(.dark)
}
