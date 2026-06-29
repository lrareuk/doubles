//
//  AuthView.swift
//  The live entry: brand hook, the 18+ gate, one-tap demo, and real sign-in/up.
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Bindable var session: Session

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var is18 = false
    @State private var blocked = false
    @State private var rawNonce = ""

    enum Mode { case signIn, signUp }

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xl) {
                    // brand hook
                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        Text("DOUBLES").font(.display(52)).foregroundStyle(DS.bone)
                            .lineLimit(1).minimumScaleFactor(0.5)
                            .accessibilityLabel("doubles")
                        Text("your friends. but ai. living their own lives while you sleep.")
                            .font(.ui(17)).foregroundStyle(DS.boneDim)
                            .fixedSize(horizontal: false, vertical: true)
                        Chyron(label: "now casting", value: "THE GROUP CHAT", marquee: true)
                    }
                    .padding(.top, DS.Space.xxxl)

                    if blocked {
                        ageBlocked
                    } else {
                        gate
                        form
                    }
                }
                .padding(DS.Space.l)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // 18+ gate — required before any social screen (brief §13).
    private var gate: some View {
        Button { Haptics.tap(); is18.toggle() } label: {
            HStack(spacing: DS.Space.m) {
                Image(systemName: is18 ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22)).foregroundStyle(is18 ? DS.acid : DS.boneDim)
                Text("i'm 18 or older. it gets messy.")
                    .font(.ui(15, .medium)).foregroundStyle(DS.bone)
                Spacer()
            }
            .padding(DS.Space.l)
            .background(DS.surface)
            .overlay(Rectangle().stroke(is18 ? DS.acid.opacity(0.5) : DS.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(is18 ? .isSelected : [])
        .accessibilityLabel("confirm you are 18 or older")
    }

    private var form: some View {
        VStack(spacing: DS.Space.m) {
            // Social sign-in (Apple required first by HIG when offering others).
            SignInWithAppleButton(.continue) { request in
                let nonce = AuthCrypto.randomNonce()
                rawNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = AuthCrypto.sha256Hex(nonce)
            } onCompletion: { handleApple($0) }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .disabled(!is18 || session.isWorking)
                .opacity(is18 ? 1 : 0.4)
                .accessibilityHint(is18 ? "" : "confirm you're 18 or older first")

            GhostButton(title: "continue with google", icon: "globe") {
                guard is18 else { blocked = true; return }
                Task { await session.signInWithGoogle() }
            }
            .opacity(is18 ? 1 : 0.4)

            HStack(spacing: DS.Space.m) {
                Rectangle().fill(DS.line).frame(height: 1)
                Text("or use email").monoLabel(9, tracking: 2).foregroundStyle(DS.boneDim)
                Rectangle().fill(DS.line).frame(height: 1)
            }
            .padding(.vertical, DS.Space.xs)

            field("email", text: $email, keyboard: .emailAddress)
            field("password", text: $password, secure: true)

            if let err = session.errorMessage {
                Text(err).font(.ui(13)).foregroundStyle(DS.magenta)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(title: actionTitle, icon: "arrow.right",
                          isEnabled: is18 && !email.isEmpty && password.count >= 6 && !session.isWorking) {
                Task { await submit() }
            }

            Button(mode == .signIn ? "new here? make an account" : "already have one? sign in") {
                Haptics.tap(); mode = mode == .signIn ? .signUp : .signIn
            }
            .font(.ui(13)).foregroundStyle(DS.rose)

            // One-tap populated demo.
            Divider().overlay(DS.line).padding(.vertical, DS.Space.s)
            Text("or skip the setup").monoLabel(10, tracking: 2).foregroundStyle(DS.boneDim)
            PrimaryButton(title: "enter the live demo", icon: "sparkles", fill: DS.acid,
                          isEnabled: is18 && !session.isWorking) {
                Task { await session.signIn(email: Config.demoEmail, password: Config.demoPassword) }
            }
            if !is18 {
                Text("confirm you're 18+ to continue.").font(.ui(12)).foregroundStyle(DS.boneDim)
            }
        }
    }

    private var ageBlocked: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            Text("come back when you're 18.").font(.display(28)).foregroundStyle(DS.bone)
            Text("doubles is adults only. there's no path in under 18 — no exceptions.")
                .font(.ui(14)).foregroundStyle(DS.boneDim)
            GhostButton(title: "go back") { blocked = false }
        }
        .padding(DS.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.surface)
        .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
    }

    private var actionTitle: String {
        session.isWorking ? "hang on…" : (mode == .signIn ? "sign in" : "create account")
    }

    private func submit() async {
        guard is18 else { blocked = true; return }
        switch mode {
        case .signIn: await session.signIn(email: email, password: password)
        case .signUp: await session.signUp(email: email, password: password)
        }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let cred = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = cred.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else {
                session.errorMessage = "apple didn't return a token."
                return
            }
            Task { await session.signInWithApple(idToken: token, rawNonce: rawNonce) }
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue { return }
            session.errorMessage = "apple sign-in failed."
        }
    }

    private func field(_ label: String, text: Binding<String>, secure: Bool = false, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(label).monoLabel(10, tracking: 2).foregroundStyle(DS.rose)
            Group {
                if secure { SecureField("", text: text) }
                else { TextField("", text: text).keyboardType(keyboard).textInputAutocapitalization(.never).autocorrectionDisabled() }
            }
            .font(.ui(16)).foregroundStyle(DS.bone)
            .padding(DS.Space.m)
            .background(DS.surface)
            .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }
}

#Preview("AuthView") {
    AuthView(session: Session()).preferredColorScheme(.dark)
}
