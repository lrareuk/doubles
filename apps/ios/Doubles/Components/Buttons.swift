//
//  Buttons.swift
//  Sharp-cornered brand buttons. Not capsules. Pressed + disabled states + haptics.
//

import SwiftUI

struct PrimaryButton: View {
    var title: String
    var icon: String? = nil
    var fill: Color = DS.magenta
    var textColor: Color = DS.ink
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.commit()
            action()
        } label: {
            HStack(spacing: DS.Space.s) {
                if let icon { Image(systemName: icon) }
                Text(title).monoLabel(13, bold: true, tracking: 2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(SharpFillStyle(fill: fill, textColor: textColor))
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}

struct GhostButton: View {
    var title: String
    var icon: String? = nil
    var tint: Color = DS.bone
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: DS.Space.s) {
                if let icon { Image(systemName: icon) }
                Text(title).monoLabel(13, bold: true, tracking: 2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(SharpGhostStyle(tint: tint))
    }
}

private struct SharpFillStyle: ButtonStyle {
    var fill: Color
    var textColor: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(textColor)
            .padding(.vertical, DS.Space.l)
            .padding(.horizontal, DS.Space.xl)
            .background(fill)
            .clipShape(.rect(cornerRadius: DS.Radius.card))
            .overlay(
                Rectangle().stroke(fill.opacity(configuration.isPressed ? 0 : 0.0), lineWidth: 0)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .shadow(color: fill.opacity(configuration.isPressed ? 0.0 : 0.35), radius: 14, y: 4)
            .animation(.spring(duration: DS.Dur.quick), value: configuration.isPressed)
    }
}

private struct SharpGhostStyle: ButtonStyle {
    var tint: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(tint)
            .padding(.vertical, DS.Space.l)
            .padding(.horizontal, DS.Space.xl)
            .background(DS.surface.opacity(configuration.isPressed ? 0.9 : 0.4))
            .clipShape(.rect(cornerRadius: DS.Radius.card))
            .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: DS.Dur.quick), value: configuration.isPressed)
    }
}

#Preview("Buttons") {
    ScreenBackground {
        VStack(spacing: DS.Space.l) {
            PrimaryButton(title: "bring yourself to life", icon: "sparkles") {}
            PrimaryButton(title: "place bet", fill: DS.acid) {}
            PrimaryButton(title: "disabled", isEnabled: false) {}
            GhostButton(title: "maybe later") {}
        }
        .padding(DS.Space.l)
    }
}
