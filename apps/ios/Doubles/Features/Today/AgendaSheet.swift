//
//  AgendaSheet.swift
//  Set your double's intent for the next episode. You steer; you never script the
//  double's actions (autonomous-sim boundary, brief §13).
//

import SwiftUI

struct AgendaSheet: View {
    var myDouble: Persona
    var existing: Agenda?
    var onSaved: () async -> Void

    @Environment(\.repo) private var repo
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var saving = false
    private let limit = 140

    init(myDouble: Persona, existing: Agenda?, onSaved: @escaping () async -> Void) {
        self.myDouble = myDouble
        self.existing = existing
        self.onSaved = onSaved
        _text = State(initialValue: existing?.intentText ?? "")
    }

    var body: some View {
        NavigationStack {
            ScreenBackground {
                VStack(alignment: .leading, spacing: DS.Space.xl) {
                    Chyron(label: "agenda", value: myDouble.displayName.uppercased())

                    Text("what's \(myDouble.displayName.lowercased()) chasing this week?")
                        .font(.display(28)).foregroundStyle(DS.bone)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("set the goal. the engine decides how your double chases it — you influence, you don't write their lines.")
                        .font(.ui(13)).foregroundStyle(DS.boneDim)

                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("e.g. expose priya before she exposes me.")
                                .font(.ui(16)).foregroundStyle(DS.boneDim.opacity(0.6))
                                .padding(DS.Space.m)
                        }
                        TextEditor(text: $text)
                            .font(.ui(16)).foregroundStyle(DS.bone)
                            .scrollContentBackground(.hidden)
                            .padding(DS.Space.s)
                            .frame(minHeight: 120)
                            .accessibilityLabel("agenda")
                    }
                    .background(DS.surface)
                    .overlay(Rectangle().stroke(DS.line, lineWidth: 1))

                    HStack {
                        Spacer()
                        Text("\(text.count)/\(limit)").monoLabel(10)
                            .foregroundStyle(text.count > limit ? DS.magenta : DS.boneDim)
                    }

                    Spacer()
                    PrimaryButton(title: saving ? "setting…" : "set agenda", icon: "target",
                                  isEnabled: isValid && !saving) { save() }
                }
                .padding(DS.Space.l)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("close") { dismiss() }.foregroundStyle(DS.boneDim).font(.ui(15))
                }
            }
            .toolbarBackground(DS.wine, for: .navigationBar)
        }
        .presentationDetents([.large])
    }

    private var isValid: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text.count <= limit }

    private func save() {
        saving = true
        Task {
            try? await repo.setAgenda(text)
            Haptics.success()
            await onSaved()
            dismiss()
        }
    }
}

#Preview("AgendaSheet") {
    AgendaSheet(myDouble: MockRepository.preview.persona("d_maya"),
                existing: nil) {}
        .environment(\.repo, MockRepository.preview)
        .preferredColorScheme(.dark)
}
