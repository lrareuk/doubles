//
//  FontRegistrar.swift
//  Registers the bundled custom fonts at launch via CoreText.
//
//  We register programmatically (rather than via Info.plist UIAppFonts) so the
//  fonts load reliably regardless of the generated Info.plist. Call once from the
//  App init, before any view renders, so the first frame already has brand type.
//

import CoreText
import Foundation

enum FontRegistrar {
    private static let files = [
        "Anton-Regular",
        "BricolageGrotesque-Regular",
        "BricolageGrotesque-Medium",
        "BricolageGrotesque-SemiBold",
        "BricolageGrotesque-ExtraBold",
        "SpaceMono-Regular",
        "SpaceMono-Bold",
    ]

    private static var didRegister = false

    /// Idempotent. Safe to call from App init and from previews.
    static func registerAll() {
        guard !didRegister else { return }
        didRegister = true
        for name in files {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                assertionFailure("Missing bundled font \(name).ttf — confirm it is in the target's Copy Bundle Resources.")
                continue
            }
            var error: Unmanaged<CFError>?
            // .process scope: available in-app, not system-wide. Re-registering is a no-op error we ignore.
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        }
    }
}
