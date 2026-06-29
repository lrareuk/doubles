//
//  Session.swift
//  Supabase auth over plain GoTrue REST (no SDK). Email/password, native Sign in
//  with Apple (id_token), and Google (PKCE via ASWebAuthenticationSession).
//  Token is kept in memory for the demo; swap to Keychain for production.
//

import SwiftUI

@MainActor
@Observable
final class Session {
    var accessToken: String?
    var userId: String?
    var email: String?
    var isWorking = false
    var errorMessage: String?

    var isAuthenticated: Bool { accessToken != nil }

    /// Custom URL scheme + redirect used for the OAuth (Google) flow. Must match
    /// the Info.plist URL type and the Supabase redirect allow-list (see SETUP.md).
    static let redirectScheme = "doubles"
    static let redirectURL = "doubles://auth-callback"

    private let webAuth = WebAuth()
    private var base: URL { Config.supabaseURL.appendingPathComponent("auth/v1") }

    // MARK: email
    func signIn(email: String, password: String) async {
        await run { try await self.post("token?grant_type=password", ["email": email, "password": password]) }
        if isAuthenticated { self.email = email }
    }

    func signUp(email: String, password: String) async {
        await run { try await self.post("signup", ["email": email, "password": password]) }
        if accessToken == nil && errorMessage == nil {
            errorMessage = "check your email to confirm, then sign in."
        }
    }

    // MARK: Sign in with Apple (native id_token)
    func signInWithApple(idToken: String, rawNonce: String) async {
        await run { try await self.post("token?grant_type=id_token",
                                        ["provider": "apple", "id_token": idToken, "nonce": rawNonce]) }
    }

    // MARK: Google (OAuth + PKCE over a web auth session)
    func signInWithGoogle() async {
        isWorking = true; errorMessage = nil
        defer { isWorking = false }
        do {
            let verifier = AuthCrypto.codeVerifier()
            var comps = URLComponents(url: base.appendingPathComponent("authorize"), resolvingAgainstBaseURL: false)!
            comps.queryItems = [
                .init(name: "provider", value: "google"),
                .init(name: "redirect_to", value: Session.redirectURL),
                .init(name: "code_challenge", value: AuthCrypto.codeChallenge(verifier)),
                .init(name: "code_challenge_method", value: "s256"),
            ]
            let callback = try await webAuth.start(url: comps.url!, scheme: Session.redirectScheme)
            guard let code = URLComponents(url: callback, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "code" })?.value else {
                throw AuthError.noCode
            }
            try await post("token?grant_type=pkce", ["auth_code": code, "code_verifier": verifier])
        } catch is CancellationError {
            // user dismissed — no error banner
        } catch {
            if case AuthError.cancelled = error { return }
            errorMessage = (error as? LocalizedError)?.errorDescription?.lowercased() ?? "google sign-in failed."
        }
    }

    func signOut() {
        accessToken = nil; userId = nil; email = nil; errorMessage = nil
    }

    // MARK: helpers
    private func run(_ op: @escaping () async throws -> Void) async {
        isWorking = true; errorMessage = nil
        defer { isWorking = false }
        do { try await op() } catch { errorMessage = "network's being dramatic. try again." }
    }

    /// POST to GoTrue; applies the session on success, sets errorMessage on failure.
    private func post(_ path: String, _ body: [String: Any]) async throws {
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        let http = response as? HTTPURLResponse
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]

        if let http, !(200...299).contains(http.statusCode) {
            let msg = (json["msg"] ?? json["error_description"] ?? json["message"] ?? json["error"]) as? String
            errorMessage = ((msg ?? "couldn't sign in") + " (\(http.statusCode))").lowercased()
            return
        }
        if let token = json["access_token"] as? String {
            accessToken = token
            if let user = json["user"] as? [String: Any] {
                userId = user["id"] as? String
                email = user["email"] as? String
            }
            Haptics.success()
        }
    }
}
