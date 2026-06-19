//
//  MatchCompositionEditorSheet.swift
//  LeVestaire
//

import SwiftUI

struct MatchCompositionEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MatchDetailViewModel

    let readOnly: Bool

    @State private var tab: CompositionTabDraft
    @State private var selectedTemplateId: String?
    @State private var pickerContext: MatchCompositionPickerContext?
    @FocusState private var focusedField: Int?

    private enum Field {
        static let name = 1
        static let notes = 2
    }

    init(viewModel: MatchDetailViewModel, readOnly: Bool = false) {
        self.viewModel = viewModel
        self.readOnly = readOnly || !viewModel.canEditComposition
        _tab = State(initialValue: viewModel.makeCompositionTabDraft())
    }

    private var canEdit: Bool {
        !readOnly && viewModel.canEditComposition
    }

    private var members: [TeamMember] {
        viewModel.editorMembers
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if canEdit, !viewModel.teamTemplates.isEmpty {
                        templateSection
                    }

                    compositionForm

                    if canEdit {
                        saveButton
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AuthScreenBackground())
            .navigationTitle(
                canEdit
                    ? L10n.text("createCompositionForMatch")
                    : L10n.text("composition")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.close) { dismiss() }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 12) {
            if focusedField != nil {
                HStack {
                    Spacer()
                    Button(L10n.done) {
                        focusedField = nil
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppPalette.Primary.main)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .glassEffect(.regular, in: .rect(cornerRadius: 20))
                .padding(.horizontal, 16)
            }
        }
        .sheet(item: $pickerContext) { context in
            PlayerPositionPickerSheet(
                members: members,
                assignedMemberIds: assignedMemberIds(excluding: context),
                slotOccupant: slotOccupant(for: context),
                onSelect: { member in
                    applySelection(member: member, context: context)
                },
                onClear: {
                    clearSelection(context: context)
                }
            )
        }
        .task {
            async let playersTask: Void = viewModel.loadSelectablePlayers()
            async let templatesTask: Void = viewModel.loadTeamTemplates()
            _ = await (playersTask, templatesTask)

            let refreshedTab = viewModel.makeCompositionTabDraft()
            if readOnly {
                if !refreshedTab.starterAssignments.isEmpty {
                    tab = refreshedTab
                }
            } else {
                tab = refreshedTab
            }
        }
    }

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.applyTeamTemplate)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            Picker(L10n.applyTeamTemplate, selection: $selectedTemplateId) {
                Text(L10n.select).tag(Optional<String>.none)
                ForEach(viewModel.teamTemplates) { template in
                    Text(template.name).tag(Optional(template.id))
                }
            }
            .pickerStyle(.menu)
            .tint(AppPalette.Primary.main)
            .onChange(of: selectedTemplateId) { _, newValue in
                guard let newValue,
                      let template = viewModel.teamTemplates.first(where: { $0.id == newValue }),
                      let imported = CompositionTabDraft.from(composition: template).first(where: \.isMain) else {
                    return
                }
                tab = imported
                if tab.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    tab.name = viewModel.match?.title ?? template.name
                }
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private var compositionForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            UGlassTextField(
                placeholder: L10n.text("compositionNamePlaceholder"),
                icon: "doc.text.fill",
                text: $tab.name,
                autocapitalization: .words,
                focusTag: Field.name,
                focusedTag: $focusedField,
                usesSystemKeyboardToolbar: false
            )
            .disabled(!canEdit)

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("formation"))
                    .font(.subheadline.weight(.semibold))

                Picker(L10n.text("formation"), selection: $tab.formationKey) {
                    ForEach(FormationCatalog.all) { formation in
                        Text(formation.displayName).tag(formation.id)
                    }
                }
                .pickerStyle(.menu)
                .disabled(!canEdit)
                .onChange(of: tab.formationKey) { _, _ in
                    tab.starterAssignments = [:]
                }
            }

            if members.isEmpty {
                ProgressView(L10n.loading)
                    .frame(maxWidth: .infinity)
            } else {
                FormationFieldView(
                    formationKey: tab.formationKey,
                    members: members,
                    assignments: tab.starterAssignments,
                    onPositionTapped: { positionId in
                        guard canEdit else { return }
                        focusedField = nil
                        pickerContext = MatchCompositionPickerContext(
                            positionId: positionId,
                            substituteIndex: nil
                        )
                    }
                )

                SubstitutesBenchView(
                    members: members,
                    substituteMemberIds: tab.substituteMemberIds,
                    onBenchSlotTapped: { index in
                        guard canEdit else { return }
                        focusedField = nil
                        pickerContext = MatchCompositionPickerContext(
                            positionId: nil,
                            substituteIndex: index
                        )
                    }
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("tacticalNotes"))
                    .font(.subheadline.weight(.semibold))

                TextField(
                    L10n.text("tacticalInstructionsPlaceholder"),
                    text: $tab.tacticalNotes,
                    axis: .vertical
                )
                .lineLimit(3...6)
                .padding(12)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                .focused($focusedField, equals: Field.notes)
                .disabled(!canEdit)
            }
        }
    }

    private var saveButton: some View {
        Button(L10n.text("save")) {
            focusedField = nil
            Task {
                if await viewModel.saveMatchComposition(
                    mainTab: tab,
                    templateCompositionId: selectedTemplateId
                ) {
                    dismiss()
                }
            }
        }
        .primarySheetButton(isLoading: viewModel.isSubmitting)
        .disabled(viewModel.isSubmitting)
    }

    private func assignedMemberIds(excluding context: MatchCompositionPickerContext) -> Set<String> {
        var ids = Set<String>()
        ids.formUnion(tab.starterAssignments.values)
        ids.formUnion(tab.substituteMemberIds.compactMap { $0 })

        if let positionId = context.positionId,
           let current = tab.starterAssignments[positionId] {
            ids.remove(current)
        }

        if let substituteIndex = context.substituteIndex,
           let current = tab.substituteMemberIds[substituteIndex] {
            ids.remove(current)
        }

        return ids
    }

    private func applySelection(member: TeamMember, context: MatchCompositionPickerContext) {
        let memberKey = member.compositionMemberKey

        clearMemberFromTab(
            member: member,
            excludingPositionId: context.positionId,
            excludingSubstituteIndex: context.substituteIndex
        )

        if let positionId = context.positionId {
            tab.starterAssignments[positionId] = memberKey
        } else if let substituteIndex = context.substituteIndex {
            tab.substituteMemberIds[substituteIndex] = memberKey
        }

        if let jerseyNumber = member.jerseyNumber {
            tab.memberJerseyNumbers[memberKey] = jerseyNumber
        }
    }

    private func clearMemberFromTab(
        member: TeamMember,
        excludingPositionId: String? = nil,
        excludingSubstituteIndex: Int? = nil
    ) {
        for (positionId, assignedKey) in tab.starterAssignments {
            guard positionId != excludingPositionId else { continue }
            if memberMatchesAssignment(assignedKey, member: member) {
                tab.starterAssignments.removeValue(forKey: positionId)
            }
        }

        for substituteIndex in tab.substituteMemberIds.indices {
            guard substituteIndex != excludingSubstituteIndex else { continue }
            guard let assignedKey = tab.substituteMemberIds[substituteIndex] else { continue }
            if memberMatchesAssignment(assignedKey, member: member) {
                tab.substituteMemberIds[substituteIndex] = nil
            }
        }
    }

    private func memberMatchesAssignment(_ assignedKey: String, member: TeamMember) -> Bool {
        member.matchesCompositionMemberKey(assignedKey)
    }

    private func slotOccupant(for context: MatchCompositionPickerContext) -> TeamMember? {
        let memberKey: String?
        if let positionId = context.positionId {
            memberKey = tab.starterAssignments[positionId]
        } else if let substituteIndex = context.substituteIndex {
            memberKey = tab.substituteMemberIds[substituteIndex]
        } else {
            memberKey = nil
        }

        guard let memberKey else { return nil }
        return members.first { $0.matchesCompositionMemberKey(memberKey) }
    }

    private func clearSelection(context: MatchCompositionPickerContext) {
        if let positionId = context.positionId {
            tab.starterAssignments.removeValue(forKey: positionId)
        } else if let substituteIndex = context.substituteIndex {
            tab.substituteMemberIds[substituteIndex] = nil
        }
    }
}

private struct MatchCompositionPickerContext: Identifiable {
    let id = UUID()
    let positionId: String?
    let substituteIndex: Int?
}

#if DEBUG
#Preview("Édition") {
    MatchCompositionEditorSheet(viewModel: MatchDetailViewModel(matchId: "preview"))
        .teamPreviewEnvironment()
}
#endif
