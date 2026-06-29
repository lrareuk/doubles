//
//  BuildDoubleView.swift
//  Bring your double to life. Name, handle, a persona prompt, traits, and an accent.
//  A live avatar preview updates as you type. Submission runs persona moderation
//  (safety, brief §13) before it lets you through.
//

import SwiftUI

struct BuildDoubleView: View {
    /// When set, the form is in edit mode for an existing double.
    var editing: Persona? = nil
    var onDone: () -> Void

    @Environment(\.repo) private var repo
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var handle: String
    @State private var prompt: String
    @State private var selectedTraits: Set<String>
    @State private var accentIndex: Int

    @State private var submitting = false
    @State private var moderationFailed = false
    @State private var showFieldErrors = false

    // A curated trait palette in brand voice.
    private let traitPool = ["instigator", "petty genius", "main character", "golden retriever",
                             "strategist", "chaos flirt", "deadpan", "observer", "loyal",
                             "two-faced", "soft launch", "menace", "peacemaker", "messy"]

    init(editing: Persona? = nil, onDone: @escaping () -> Void) {
        self.editing = editing
        self.onDone = onDone
        _name = State(initialValue: editing?.displayName ?? "")
        _handle = State(initialValue: editing?.handle ?? "")
        _prompt = State(initialValue: editing?.personaPrompt ?? "")
        _selectedTraits = State(initialValue: Set(editing?.traits ?? []))
        _accentIndex = State(initialValue: editing?.accentIndex ?? 0)
    }

    // Live preview persona built from current inputs.
    private var preview: Persona {
        Persona(id: editing?.id ?? "preview",
                ownerUserId: editing?.ownerUserId ?? "u_you",
                displayName: name.isEmpty ? "your double" : name,
                handle: handle.isEmpty ? "yourhandle" : handle,
                personaPrompt: prompt,
                traits: Array(selectedTraits),
                vibe: prompt.isEmpty ? "tell us who you are." : prompt,
                accentIndex: accentIndex,
                isMine: true)
    }

    var body: some View {
        NavigationStack {
            ScreenBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Space.xl) {
                        livePreview
                        nameField
                        handleField
                        promptField
                        traitsPicker
                        accentPicker
                        if moderationFailed {
                            Text("let's keep it kind. try rewording that.")
                                .font(.ui(13)).foregroundStyle(DS.magenta)
                        }
                        PrimaryButton(title: submitting ? "bringing you to life…"
                                      : (editing == nil ? "bring yourself to life" : "save your double"),
                                      icon: "sparkles",
                                      isEnabled: !submitting) { submit() }
                    }
                    .padding(DS.Space.l)
                    .padding(.bottom, DS.Space.xxxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(editing == nil ? "your double" : "edit double")
                        .font(.ui(15, .bold)).foregroundStyle(DS.bone)
                }
                if editing != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("close") { dismiss() }.foregroundStyle(DS.boneDim).font(.ui(15))
                    }
                }
            }
            .toolbarBackground(DS.wine, for: .navigationBar)
        }
    }

    // MARK: live preview
    private var livePreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [preview.accent.opacity(0.95), preview.accent.opacity(0.2)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 110)
                DoubleAvatar(persona: preview, size: 64).padding(DS.Space.l)
            }
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(preview.displayName).font(.display(26)).foregroundStyle(DS.bone)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .accessibilityLabel(preview.displayName)
                Text("@\(preview.handle)").monoLabel(10).foregroundStyle(DS.boneDim)
                if !selectedTraits.isEmpty {
                    FlowChips(items: Array(selectedTraits), tint: preview.accent)
                        .padding(.top, DS.Space.xs)
                }
            }
            .padding(DS.Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.surface)
        }
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
        .animation(.spring(duration: DS.Dur.quick), value: accentIndex)
    }

    // MARK: fields
    private var nameField: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            SectionLabel(text: "name")
            BrandTextField(text: $name, placeholder: "what do they call you?")
            if showFieldErrors && trimmed(name).isEmpty {
                Text("give your double a name.").font(.ui(12)).foregroundStyle(DS.magenta)
            }
        }
    }

    private var handleField: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            SectionLabel(text: "handle")
            HStack(spacing: 0) {
                Text("@").font(.mono(16, bold: true)).foregroundStyle(DS.boneDim)
                    .padding(.leading, DS.Space.m)
                BrandTextField(text: $handle, placeholder: "yourhandle", autocaps: false, standalone: false)
            }
            .background(DS.surface)
            .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
            if showFieldErrors && trimmed(handle).isEmpty {
                Text("pick a handle.").font(.ui(12)).foregroundStyle(DS.magenta)
            }
        }
    }

    private var promptField: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            SectionLabel(text: "the brief")
            ZStack(alignment: .topLeading) {
                if prompt.isEmpty {
                    Text("bring yourself to life — who are you in the group chat?")
                        .font(.ui(15)).foregroundStyle(DS.boneDim.opacity(0.6))
                        .padding(DS.Space.m)
                }
                TextEditor(text: $prompt)
                    .font(.ui(15)).foregroundStyle(DS.bone)
                    .scrollContentBackground(.hidden)
                    .padding(DS.Space.s)
                    .frame(minHeight: 110)
                    .accessibilityLabel("the brief — who your double is")
            }
            .background(DS.surface)
            .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
        }
    }

    private var traitsPicker: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            SectionLabel(text: "traits", trailing: "\(selectedTraits.count)")
            FlowLayout(spacing: DS.Space.s) {
                ForEach(traitPool, id: \.self) { trait in
                    let on = selectedTraits.contains(trait)
                    Button {
                        Haptics.tap()
                        if on { selectedTraits.remove(trait) } else { selectedTraits.insert(trait) }
                    } label: {
                        TagChip(text: trait, tint: preview.accent, filled: on)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(trait)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
    }

    private var accentPicker: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            SectionLabel(text: "your colour")
            HStack(spacing: DS.Space.m) {
                ForEach(Array(DS.characters.enumerated()), id: \.offset) { index, color in
                    Button {
                        Haptics.tap(); accentIndex = index
                    } label: {
                        Rectangle().fill(color).frame(width: 34, height: 34)
                            .overlay(Rectangle().stroke(accentIndex == index ? DS.bone : .clear, lineWidth: 2))
                            .overlay(Rectangle().stroke(DS.ink.opacity(0.25), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("colour \(index + 1)")
                    .accessibilityAddTraits(accentIndex == index ? .isSelected : [])
                }
            }
        }
    }

    // MARK: validation & submit
    private func trimmed(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var fieldsValid: Bool { !trimmed(name).isEmpty && !trimmed(handle).isEmpty }

    private func submit() {
        moderationFailed = false
        showFieldErrors = true
        guard fieldsValid else { Haptics.warning(); return }
        submitting = true
        Task {
            let ok = (try? await repo.runPersonaModeration(prompt)) ?? true
            submitting = false
            if ok {
                Haptics.success()
                onDone()
            } else {
                Haptics.failure()
                moderationFailed = true
            }
        }
    }
}

/// A sharp single-line brand text field.
struct BrandTextField: View {
    @Binding var text: String
    var placeholder: String
    var autocaps: Bool = true
    var standalone: Bool = true

    var body: some View {
        let field = TextField("", text: $text, prompt: Text(placeholder)
            .foregroundColor(DS.boneDim.opacity(0.6)))
            .font(.ui(16)).foregroundStyle(DS.bone)
            .textInputAutocapitalization(autocaps ? .sentences : .never)
            .autocorrectionDisabled(!autocaps)
            .padding(DS.Space.m)
        if standalone {
            field
                .background(DS.surface)
                .overlay(Rectangle().stroke(DS.line, lineWidth: 1))
        } else {
            field
        }
    }
}

#Preview("BuildDouble — new") {
    BuildDoubleView {}
        .environment(\.repo, MockRepository.preview)
        .preferredColorScheme(.dark)
}

#Preview("BuildDouble — edit") {
    BuildDoubleView(editing: MockRepository.preview.persona("d_maya")) {}
        .environment(\.repo, MockRepository.preview)
        .preferredColorScheme(.dark)
}
