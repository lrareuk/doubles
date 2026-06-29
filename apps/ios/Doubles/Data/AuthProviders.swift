//
//  AuthProviders.swift
//  Crypto + web-auth helpers for Apple / Google sign-in via Supabase (no SDKs).
//  Apple uses native id_token; Google uses Supabase's authorize endpoint over
//  ASWebAuthenticationSession with PKCE. Both resolve to a Supabase session.
//

import Foundation
import CryptoKit
import AuthenticationServices

enum AuthError: LocalizedError {
    case cancelled, noCode, badToken
    var errorDescription: String? {
        switch self {
        case .cancelled: "sign-in cancelled."
        case .noCode: "didn't get an auth code back."
        case .badToken: "apple didn't return a token."
        }
    }
}

enum AuthCrypto {
    /// Random URL-safe nonce string.
    static func randomNonce(length: Int = 32) -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._")
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return String(bytes.map { chars[Int($0) % chars.count] })
    }

    /// SHA256 hex — what Apple's request.nonce expects (Supabase gets the raw nonce).
    static func sha256Hex(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// PKCE verifier (43–128 url-safe chars).
    static func codeVerifier() -> String { randomNonce(length: 64) }

    /// PKCE challenge = base64url(sha256(verifier)), no padding.
    static func codeChallenge(_ verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

/// Drives ASWebAuthenticationSession for the Google (OAuth) flow.
@MainActor
final class WebAuth: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    /// Opens `url`, waits for a `scheme://` redirect, returns the callback URL.
    func start(url: URL, scheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) { callback, error in
                if let callback {
                    cont.resume(returning: callback)
                } else {
                    cont.resume(throwing: error ?? AuthError.cancelled)
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }
}
