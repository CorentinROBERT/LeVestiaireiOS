//
//  CompositionEditorSheet.swift
//  LeVestaire
//

import SwiftUI

struct CompositionEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TeamViewModel
    @ObservedObject var compositionsViewModel: TeamCompositionsViewModel
    let composition: TeamComposition?

    @State private var tabs: [CompositionTabDraft] = []
    @State private var selectedTabId = ""
    @State private var deletedAlternativeIds: [String] = []
    @State private var showsDeleteAlternativeConfirmation = false
    @State private var showsDeleteCompositionConfirmation = false
    @State private var pickerContext: PickerContext?
    @FocusState private var focusedField: Int?

    private enum Field {
        static let name = 1
        static let notes = 2
    }

    init(viewModel: TeamViewModel, composition: TeamComposition?) {
        self.viewModel = viewModel
        self.compositionsViewModel = viewModel.compositionsViewModel
        self.composition = composition
    }

    private var members: [TeamMember] {
        viewModel.selectedTeam?.resolvedMembers ?? []
    }

    private var canEdit: Bool {
        viewModel.canManageTeam
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

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if let saveError = compositionsViewModel.lastSaveError {
                        compositionSaveErrorBanner(message: saveError)
                    }

                    tabSelector
                    if tabs.indices.contains(selectedTabIndex) {
                        compositionForm(for: $tabs[selectedTabIndex])
                    }
                    if canEdit {
                        saveButton

                        if composition != nil {
                            deleteCompositionButton
                        }
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AuthScreenBackground())
            .navigationTitle(
                composition == nil
                    ? L10n.text("creerComposition")
                    : L10n.text("composition")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.cancel) { dismiss() }
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
                        tabLabel(for: selectedTab)
                    )
                )
            }
        }
        .alert(L10n.confirmDeletion, isPresented: $showsDeleteCompositionConfirmation) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.text("delete"), role: .destructive) {
                deleteComposition()
            }
        } message: {
            Text(L10n.confirmDeletionMessage)
        }
        .onAppear(perform: bootstrapTabs)
        .onReceive(
            Foundation.NotificationCenter.default.publisher(
                for: UIResponder.keyboardWillHideNotification
            )
        ) { _ in
            focusedField = nil
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
    }

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tabs) { tab in
                    Button {
                        selectedTabId = tab.id
                    } label: {
                        Text(tabLabel(for: tab))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedTabId == tab.id ? AppPalette.Primary.main : AppPalette.Neutral.surface)
                            )
                            .foregroundStyle(selectedTabId == tab.id ? .white : AppPalette.Neutral.textPrimary)
                    }
                    .buttonStyle(.fullTap)
                }
            }
        }
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

            UMenuPicker(
                title: L10n.text("formation"),
                selection: tab.formationKey,
                isDisabled: !canEdit,
                onChange: {
                    tab.wrappedValue.starterAssignments = [:]
                    tab.wrappedValue.captainMemberKey = nil
                }
            ) {
                ForEach(FormationCatalog.all) { formation in
                    Text(formation.displayName).tag(formation.id)
                }
            }

            if tab.wrappedValue.isMain {
                CompositionCaptainSection(
                    members: members,
                    tab: tab.wrappedValue,
                    captainMemberKey: tab.captainMemberKey,
                    canEdit: canEdit,
                    onPersistCaptain: persistTeamCaptainIfNeeded
                )
            }

            FormationFieldView(
                formationKey: tab.wrappedValue.formationKey,
                members: members,
                assignments: tab.wrappedValue.starterAssignments,
                onPositionTapped: { positionId in
                    guard canEdit else { return }
                    focusedField = nil
                    pickerContext = PickerContext(
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
                    pickerContext = PickerContext(
                        tabId: tab.wrappedValue.id,
                        positionId: nil,
                        substituteIndex: index
                    )
                },
                captainMemberKey: tab.wrappedValue.isMain
                    ? tab.wrappedValue.sanitizedCaptainMemberKey()
                    : nil
            )

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
            focusedField = nil
            Task {
                let didSave = await compositionsViewModel.save(
                    tabs: tabs,
                    deletedAlternativeIds: deletedAlternativeIds
                )
                guard didSave else { return }
                viewModel.showSuccess(
                    composition == nil
                        ? L10n.text("compositionCreatedSuccessfully")
                        : L10n.text("compositionModifiedSuccessfully")
                )
                viewModel.activeSheet = nil
            }
        }
        .primarySheetButton(isLoading: compositionsViewModel.isSubmitting)
        .disabled(compositionsViewModel.isSubmitting)
    }

    private func compositionSaveErrorBanner(message: String) -> some View {
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

    private var deleteCompositionButton: some View {
        Button(L10n.deleteComposition) {
            focusedField = nil
            showsDeleteCompositionConfirmation = true
        }
        .destructiveSheetButton()
        .disabled(compositionsViewModel.isSubmitting)
    }

    private func deleteComposition() {
        guard let composition else { return }

        Task {
            if await compositionsViewModel.delete(composition) {
                dismiss()
            }
        }
    }

    private func tabLabel(for tab: CompositionTabDraft) -> String {
        tab.displayLabel
    }

    private func bootstrapTabs() {
        if let composition {
            tabs = CompositionTabDraft.from(composition: composition)
        } else {
            tabs = [CompositionTabDraft(name: "", isMain: true)]
        }
        deletedAlternativeIds = []
        selectedTabId = tabs.first?.id ?? ""
    }

    private func addAlternativeTab() {
        let tab = CompositionTabDraft(
            name: L10n.format("compositionNumber", tabs.count),
            isMain: false
        )
        tabs.append(tab)
        selectedTabId = tab.id
    }

    private func removeSelectedAlternativeTab() {
        guard let index = tabs.firstIndex(where: { $0.id == selectedTabId }),
              !tabs[index].isMain else { return }

        if let serverAlternativeId = tabs[index].serverAlternativeId {
            deletedAlternativeIds.append(serverAlternativeId)
        }

        tabs.remove(at: index)
        selectedTabId = tabs.first(where: \.isMain)?.id ?? tabs.first?.id ?? ""
    }

    private func assignedMemberIds(excluding context: PickerContext) -> Set<String> {
        guard let tab = tabs.first(where: { $0.id == context.tabId }) else { return [] }
        return CompositionEditorEngine.assignedMemberIds(
            in: tab,
            excluding: compositionContext(from: context)
        )
    }

    private func applySelection(member: TeamMember, context: PickerContext) {
        guard let index = tabs.firstIndex(where: { $0.id == context.tabId }) else { return }
        CompositionEditorEngine.applySelection(
            member: member,
            context: compositionContext(from: context),
            to: &tabs[index]
        )
    }

    private func clearMemberFromTab(
        _ tab: inout CompositionTabDraft,
        member: TeamMember,
        excludingPositionId: String? = nil,
        excludingSubstituteIndex: Int? = nil
    ) {
        CompositionEditorEngine.clearMemberFromTab(
            member: member,
            in: &tab,
            excludingPositionId: excludingPositionId,
            excludingSubstituteIndex: excludingSubstituteIndex
        )
    }

    private func slotOccupant(for context: PickerContext) -> TeamMember? {
        guard let tab = tabs.first(where: { $0.id == context.tabId }) else { return nil }
        return CompositionEditorEngine.slotOccupant(
            for: compositionContext(from: context),
            in: tab,
            members: members
        )
    }

    private func compositionContext(from context: PickerContext) -> CompositionPickerContext {
        CompositionPickerContext(
            positionId: context.positionId,
            substituteIndex: context.substituteIndex
        )
    }

    private func clearSelection(context: PickerContext) {
        guard let index = tabs.firstIndex(where: { $0.id == context.tabId }) else { return }
        CompositionEditorEngine.clearSelection(
            context: compositionContext(from: context),
            in: &tabs[index]
        )
    }

    private func persistTeamCaptainIfNeeded(_ captainId: String?) async -> Bool {
        guard let compositionId = composition?.id else { return true }
        return await compositionsViewModel.setCaptain(
            compositionId: compositionId,
            captainId: captainId
        )
    }
}

private struct PickerContext: Identifiable {
    let id = UUID()
    let tabId: String
    let positionId: String?
    let substituteIndex: Int?
}

#if DEBUG
#Preview("Création") {
    CompositionEditorSheet(viewModel: .preview(), composition: nil)
        .teamPreviewEnvironment()
}

#Preview("Édition") {
    CompositionEditorSheet(
        viewModel: .preview(),
        composition: TeamPreviewData.compositions[0]
    )
    .teamPreviewEnvironment()
}

#Preview("Lecture seule") {
    CompositionEditorSheet(
        viewModel: .preview(role: .player),
        composition: TeamPreviewData.compositions[0]
    )
    .teamPreviewEnvironment()
}
#endif
