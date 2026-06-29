//
//  Haptics.swift
//  Imperative haptic helpers for tap-time actions. Components also use the
//  declarative `.sensoryFeedback` where a trigger value is natural.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum Haptics {
    static func tap() {
        #if canImport(UIKit)
        impact(.light)
        #endif
    }
    static func commit() {
        #if canImport(UIKit)
        impact(.medium)
        #endif
    }
    static func heavy() {
        #if canImport(UIKit)
        impact(.heavy)
        #endif
    }
    static func success() {
        #if canImport(UIKit)
        notify(.success)
        #endif
    }
    static func warning() {
        #if canImport(UIKit)
        notify(.warning)
        #endif
    }
    static func failure() {
        #if canImport(UIKit)
        notify(.error)
        #endif
    }

    #if canImport(UIKit)
    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let g = UIImpactFeedbackGenerator(style: style)
        g.prepare(); g.impactOccurred()
    }
    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let g = UINotificationFeedbackGenerator()
        g.prepare(); g.notificationOccurred(type)
    }
    #endif
}
