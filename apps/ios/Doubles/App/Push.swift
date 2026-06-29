//
//  Push.swift
//  Notification permission + APNs device-token capture for the morning recap
//  push ("episode N is live — your double did something"). The token is sent to
//  the API in live mode; actual APNs delivery is server-side (see SETUP.md).
//

import SwiftUI
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class PushManager {
    static let shared = PushManager()
    private(set) var deviceToken: String?

    /// Ask for notification permission, then register for remote notifications.
    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        #if canImport(UIKit)
        if granted { UIApplication.shared.registerForRemoteNotifications() }
        #endif
    }

    func setToken(_ data: Data) {
        deviceToken = data.map { String(format: "%02x", $0) }.joined()
    }
}

#if canImport(UIKit)
/// Captures the APNs device token (SwiftUI has no direct hook).
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in PushManager.shared.setToken(deviceToken) }
    }
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // No-op for the demo; surfaced via logs in development.
    }
}
#endif
