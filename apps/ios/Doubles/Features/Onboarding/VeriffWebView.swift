//
//  VeriffWebView.swift
//  Presents the Veriff age-estimation hosted flow in a WKWebView (selfie capture).
//  The web result only means "submitted" — the authoritative 18+ decision arrives
//  on the backend via the signed Veriff webhook, so the caller polls the server
//  after this closes. (If you later add the Veriff iOS SPM SDK, swap this out.)
//

import SwiftUI
import WebKit

struct VeriffWebView: View {
    let url: URL
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            VeriffWebContainer(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("age check")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("done") { onClose() }.foregroundStyle(DS.bone)
                    }
                }
                .toolbarBackground(DS.wine, for: .navigationBar)
        }
    }
}

private struct VeriffWebContainer: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        let web = WKWebView(frame: .zero, configuration: cfg)
        web.uiDelegate = context.coordinator
        web.isOpaque = false
        web.backgroundColor = .black
        web.scrollView.backgroundColor = .black
        web.load(URLRequest(url: url))
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    // Grant in-page camera access (Veriff selfie). Requires NSCameraUsageDescription.
    final class Coordinator: NSObject, WKUIDelegate {
        func webView(_ webView: WKWebView,
                     requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                     initiatedByFrame frame: WKFrameInfo,
                     type: WKMediaCaptureType,
                     decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }
    }
}
