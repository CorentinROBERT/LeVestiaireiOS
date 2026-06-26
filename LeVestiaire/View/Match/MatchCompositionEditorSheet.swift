//
//  MatchCompositionEditorSheet.swift
//  LeVestaire
//

import SwiftUI

struct MatchCompositionEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MatchDetailViewModel
    @ObservedObject var compositionViewModel: MatchDetailCompositionViewModel
    @ObservedObject var availabilityViewModel: MatchDetailAvailabilityViewModel

    let readOnly: Bool

    @State private var tabs: [CompositionTabDraft]
    @State private var selectedTabId: String
    @State private var selectedTemplateId: String?
    @State private var pendingTemplateId: String?
    @State private var pickerContext: MatchCompositionPickerContext?
    @State private var hasUserEditedTabs = false
    @State private var sheetErrorMessage: String?
    @State private var showsTemplateImportConfirmation = false
    @State private var showsSaveAvailabilityConfirmation = false
    @State private var showsDeleteAlternativeConfirmation = false
    @FocusState private var focusedField: Int?

    private enum Field {
        static let name = 1
        static let notes = 2
    }

    init(viewModel: MatchDetailViewModel, readOnly: Bool = false) {
        self.viewModel = viewModel
        self.compositionViewModel = viewModel.compositionViewModel
        self.availabilityViewModel = viewModel.availabilityViewModel
        self.readOnly = readOnly || !viewModel.canEditComposition
        let initialTabs = viewModel.compositionViewModel.makeCompositionTabDrafts()
        _tabs = State(initialValue: initialTabs)
        _selectedTabId = State(
            initialValue: initialTabs.first(where: \.isMain)?.id ?? initialTabs.first?.id ?? ""
        )
    }

    private var canEdit: Bool {
        !readOnly && viewModel.canEditComposition
    }

    private var members: [TeamMember] {
        viewModel.editorMembers
    }

    private var selectedTabIndex: Int {
        tabs.firstIndex(where: { $0.id == selectedTabId }) ?? 0
    }

    private var selectedTab: CompositionTabDraft? {
        tabs.first { $0.id == selectedTabId }
    }

    private var canDeleteSelectedTab: Bool {
        canEdit && selectedTab?.isMain == false
    }

    private var showsTabSelector: Bool {
        canEdit || tabs.count > 1
    }

    private var templateAvailabilityReview: CompositionTemplateAvailabilityReview {
        CompositionEditorEngine.templateAvailabilityReview(
            tabs: tabs,
            members: members,
            availability: availabilityViewModel.availability
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if let sheetErrorMessage {
                        compositionErrorBanner(message: sheetErrorMessage)
                    }

                    if canEdit, !compositionViewModel.teamTemplates.isEmpty {
                        templateSection
                    }

                    if templateAvailabilityReview.hasConflicts {
                        CompositionTemplateAvailabilityBanner(
                            review: templateAvailabilityReview,
                            onRemoveAbsent: removeAbsentMembersFromComposition
                        )
                    }

                    if showsTabSelector {
                        tabSelector
                    }

                    if tabs.indices.contains(selectedTabIndex) {
                        compositionForm(for: $tabs[selectedTabIndex])
                    }

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
                if canEdit {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if canDeleteSelectedTab {
                            Button(role: .destructive) {
                                showsDeleteAlternativeConfirmation = true
                            } label: {
                                Image(systemName: "minus")
                            }
                        }

                        Button {
                            addAlternativeTab()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .alert(L10n.deleteAlternativeFormation, isPresented: $showsDeleteAlternativeConfirmation) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.text("delete"), role: .destructive) {
                removeSelectedAlternativeTab()
            }
        } message: {
            if let selectedTab {
                Text(
                    L10n.format(
                        "deleteAlternativeFormationConfirm",
                        selectedTab.displayLabel
                    )
                )
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
            async let playersTask: Void = compositionViewModel.loadSelectablePlayers()
            async let templatesTask: Void = compositionViewModel.loadTeamTemplates()
            async let availabilityTask: Void = availabilityViewModel.refreshBoard(force: true, silent: true)
            _ = await (playersTask, templatesTask, availabilityTask)

            let refreshedTabs = compositionViewModel.makeCompositionTabDrafts()
            guard !hasUserEditedTabs else { return }

            if readOnly {
                if refreshedTabs.contains(where: { !$0.starterAssignments.isEmpty }) {
                    tabs = refreshedTabs
                    selectedTabId = refreshedTabs.first(where: \.isMain)?.id ?? refreshedTabs.first?.id ?? ""
                }
            } else {
                tabs = refreshedTabs
                selectedTabId = refreshedTabs.first(where: \.isMain)?.id ?? refreshedTabs.first?.id ?? ""
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
                ForEach(compositionViewModel.teamTemplates) { template in
                    Text(template.name).tag(Optional(template.id))
                }
            }
            .pickerStyle(.menu)
            .tint(AppPalette.Primary.main)
            .onChange(of: selectedTemplateId) { _, newValue in
                guard let newValue else { return }
                pendingTemplateId = newValue
                showsTemplateImportConfirmation = true
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
        .confirmationDialog(
            L10n.text("compositionImportTemplateTitle"),
            isPresented: $showsTemplateImportConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.text("compositionImportTemplateAction")) {
                applyTemplate(id: pendingTemplateId)
                pendingTemplateId = nil
            }
            Button(L10n.cancel, role: .cancel) {
                selectedTemplateId = nil
                pendingTemplateId = nil
            }
        } message: {
            Text(L10n.text("compositionImportTemplateConfirm"))
        }
    }

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tabs) { tab in
                    Button {
                        selectedTabId = tab.id
                    } label: {
                        Text(tab.displayLabel)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        selectedTabId == tab.id
                                            ? AppPalette.Primary.main
                                            : AppPalette.Neutral.surface
                                    )
                            )
                            .foregroundStyle(
                                selectedTabId == tab.id
                                    ? AppPalette.Primary.onMain
                                    : AppPalette.Neutral.textPrimary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func compositionForm(for tab: Binding<CompositionTabDraft>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            UGlassTextField(
                placeholder: L10n.text("compositionNamePlaceholder"),
                icon: "doc.text.fill",
                text: tab.name,
                autocapitalization: .words,
                focusTag: Field.name,
                focusedTag: $focusedField,
                usesSystemKeyboardToolbar: false
            )
            .disabled(!canEdit)

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("formation"))
                    .font(.subheadline.weight(.semibold))

                Picker(L10n.text("formation"), selection: tab.formationKey) {
                    ForEach(FormationCatalog.all) { formation in
                        Text(formation.displayName).tag(formation.id)
                    }
                }
                .pickerStyle(.menu)
                .disabled(!canEdit)
                .onChange(of: tab.wrappedValue.formationKey) { _, _ in
                    tab.wrappedValue.starterAssignments = [:]
                    tab.wrappedValue.captainMemberKey = nil
                    markTabsEdited()
                }
            }

            if tab.wrappedValue.isMain {
                CompositionCaptainSection(
                    members: members,
                    tab: tab.wrappedValue,
                    captainMemberKey: tab.captainMemberKey,
                    canEdit: canEdit,
                    onPersistCaptain: persistMatchCaptainIfNeeded
                )
            }

            if members.isEmpty {
                ProgressView(L10n.loading)
                    .frame(maxWidth: .infinity)
            } else {
                FormationFieldView(
                    formationKey: tab.wrappedValue.formationKey,
                    members: members,
                    assignments: tab.wrappedValue.starterAssignments,
                    onPositionTapped: { positionId in
                        guard canEdit else { return }
                        focusedField = nil
                        pickerContext = MatchCompositionPickerContext(
                            tabId: tab.wrappedValue.id,
                            positionId: positionId,
                            substituteIndex: nil
                        )
                    },
                    captainMemberKey: tab.wrappedValue.isMain
                        ? tab.wrappedValue.sanitizedCaptainMemberKey()
                        : nil
                )

                SubstitutesBenchView(
                    members: members,
                    substituteMemberIds: tab.wrappedValue.substituteMemberIds,
                    onBenchSlotTapped: { index in
                        guard canEdit else { return }
                        focusedField = nil
                        pickerContext = MatchCompositionPickerContext(
                            tabId: tab.wrappedValue.id,
                            positionId: nil,
                            substituteIndex: index
                        )
                    },
                    captainMemberKey: tab.wrappedValue.isMain
                        ? tab.wrappedValue.sanitizedCaptainMemberKey()
                        : nil
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("tacticalNotes"))
                    .font(.subheadline.weight(.semibold))

                TextField(
                    L10n.text("tacticalInstructionsPlaceholder"),
                    text: tab.tacticalNotes,
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
            requestSave()
        }
        .primarySheetButton(isLoading: compositionViewModel.isSavingComposition)
        .disabled(compositionViewModel.isSavingComposition)
        .confirmationDialog(
            L10n.text("save"),
            isPresented: $showsSaveAvailabilityConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.text("save")) {
                Task { await performSave() }
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.text("compositionSaveAvailabilityConflictConfirm"))
        }
    }

    private func compositionErrorBanner(message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundStyle(AppPalette.Semantic.error)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppPalette.Semantic.error.opacity(0.12))
            )
    }

    private func requestSave() {
        focusedField = nil
        sheetErrorMessage = nil

        if templateAvailabilityReview.hasConflicts {
            showsSaveAvailabilityConfirmation = true
        } else {
            Task { await performSave() }
        }
    }

    private func performSave() async {
        if await compositionViewModel.save(
            tabs: tabs,
            templateCompositionId: selectedTemplateId
        ) {
            dismiss()
        } else {
            sheetErrorMessage = viewModel.errorMessage
        }
    }

    private func markTabsEdited() {
        hasUserEditedTabs = true
        sheetErrorMessage = nil
    }

    private func applyTemplate(id: String?) {
        guard let id,
              let template = compositionViewModel.teamTemplates.first(where: { $0.id == id }) else {
            return
        }

        let importedTabs = CompositionTabDraft.from(composition: template)
        guard !importedTabs.isEmpty else { return }

        tabs = importedTabs
        if let mainIndex = tabs.firstIndex(where: \.isMain) {
            let matchTitle = viewModel.match?.title ?? template.name
            if tabs[mainIndex].name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                tabs[mainIndex].name = matchTitle
            }
        }
        selectedTabId = tabs.first(where: \.isMain)?.id ?? tabs.first?.id ?? ""
        markTabsEdited()
    }

    private func addAlternativeTab() {
        let tab = CompositionTabDraft(
            name: L10n.format("compositionNumber", tabs.count),
            isMain: false
        )
        tabs.append(tab)
        selectedTabId = tab.id
        markTabsEdited()
    }

    private func removeSelectedAlternativeTab() {
        guard let index = tabs.firstIndex(where: { $0.id == selectedTabId }),
              !tabs[index].isMain else { return }

        tabs.remove(at: index)
        selectedTabId = tabs.first(where: \.isMain)?.id ?? tabs.first?.id ?? ""
        markTabsEdited()
    }

    private func assignedMemberIds(excluding context: MatchCompositionPickerContext) -> Set<String> {
        guard let tab = tabs.first(where: { $0.id == context.tabId }) else { return [] }
        return CompositionEditorEngine.assignedMemberIds(
            in: tab,
            excluding: compositionContext(from: context)
        )
    }

    private func applySelection(member: TeamMember, context: MatchCompositionPickerContext) {
        guard let index = tabs.firstIndex(where: { $0.id == context.tabId }) else { return }
        CompositionEditorEngine.applySelection(
            member: member,
            context: compositionContext(from: context),
            to: &tabs[index]
        )
        markTabsEdited()
    }

    private func slotOccupant(for context: MatchCompositionPickerContext) -> TeamMember? {
        guard let tab = tabs.first(where: { $0.id == context.tabId }) else { return nil }
        return CompositionEditorEngine.slotOccupant(
            for: compositionContext(from: context),
            in: tab,
            members: members
        )
    }

    private func compositionContext(from context: MatchCompositionPickerContext) -> CompositionPickerContext {
        CompositionPickerContext(
            positionId: context.positionId,
            substituteIndex: context.substituteIndex
        )
    }

    private func clearSelection(context: MatchCompositionPickerContext) {
        guard let index = tabs.firstIndex(where: { $0.id == context.tabId }) else { return }
        CompositionEditorEngine.clearSelection(
            context: compositionContext(from: context),
            in: &tabs[index]
        )
        markTabsEdited()
    }

    private func removeAbsentMembersFromComposition() {
        CompositionEditorEngine.removeAbsentMembers(
            from: &tabs,
            members: members,
            availability: availabilityViewModel.availability
        )
        markTabsEdited()
    }

    private func persistMatchCaptainIfNeeded(_ captainId: String?) async -> Bool {
        guard viewModel.match?.composition != nil else { return true }
        let success = await compositionViewModel.setCaptain(captainId: captainId)
        if success {
            markTabsEdited()
        }
        return success
    }
}

private struct MatchCompositionPickerContext: Identifiable {
    let id = UUID()
    let tabId: String
    let positionId: String?
    let substituteIndex: Int?
}

#if DEBUG
#Preview("Édition") {
    MatchCompositionEditorSheet(viewModel: MatchDetailViewModel(matchId: "preview"))
        .teamPreviewEnvironment()
}
#endif
