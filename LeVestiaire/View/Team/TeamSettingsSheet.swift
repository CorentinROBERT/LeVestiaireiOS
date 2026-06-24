//
//  TeamSettingsSheet.swift
//  LeVestaire
//

import SwiftUI
import UIKit

struct TeamSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TeamViewModel

    @State private var showsDeleteConfirmation = false
    @State private var showsLeaveConfirmation = false
    @State private var showsTransferSheet = false

    private var role: TeamRole? { viewModel.currentUserRole }

    var body: some View {
        NavigationStack {
            List {
                if role?.canManageTeam == true {
                    Section(L10n.text("teamInformation")) {
                        NavigationLink(L10n.text("modifyTeamInformation")) {
                            EditTeamInfoView(viewModel: viewModel)
                        }
                        Button(L10n.text("invitePlayer")) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                viewModel.invitationsViewModel.presentInvitePlayerSheet()
                            }
                        }
                        Button(L10n.text("shareTeamInviteLink")) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                viewModel.presentShareTeamInviteSheet()
                            }
                        }
                    }
                }

                if role == .admin {
                    Section(L10n.text("teamSettings")) {
                        Button(L10n.text("transferAdministration")) {
                            showsTransferSheet = true
                        }
                        Button(L10n.text("deleteTeam"), role: .destructive) {
                            showsDeleteConfirmation = true
                        }
                    }
                }

                Section {
                    Button(L10n.text("leaveTeam"), role: .destructive) {
                        showsLeaveConfirmation = true
                    }
                }
            }
            .navigationTitle(L10n.text("teamOptions"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showsTransferSheet) {
            TransferAdminSheet(viewModel: viewModel)
        }
        .alert(L10n.text("deleteTeam"), isPresented: $showsDeleteConfirmation) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.text("deleteTeam"), role: .destructive) {
                Task {
                    if await viewModel.deleteSelectedTeam() {
                        dismiss()
                    }
                }
            }
        } message: {
            Text(
                L10n.format(
                    "confirmerSuppressionEquipe",
                    viewModel.selectedTeam?.name ?? ""
                )
            )
        }
        .alert(L10n.text("leaveTeam"), isPresented: $showsLeaveConfirmation) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.text("leaveTeam"), role: .destructive) {
                Task {
                    if await viewModel.leaveSelectedTeam() {
                        dismiss()
                    }
                }
            }
        } message: {
            Text(
                L10n.format(
                    "confirmerQuitterEquipe",
                    viewModel.selectedTeam?.name ?? ""
                )
            )
        }
    }
}

private struct EditTeamInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TeamViewModel

    @State private var name: String
    @State private var description: String
    @State private var logoImage: UIImage?

    init(viewModel: TeamViewModel) {
        self.viewModel = viewModel
        _name = State(initialValue: viewModel.selectedTeam?.name ?? "")
        _description = State(initialValue: viewModel.selectedTeam?.description ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProfilePhotoPicker(
                    selectedImage: $logoImage,
                    remoteImageURL: RemoteMediaURL.resolve(viewModel.selectedTeam?.logoUrl),
                    initials: String(name.prefix(1)).uppercased(),
                    isUploading: false
                )

                UGlassTextField(
                    placeholder: L10n.text("teamName"),
                    icon: "person.3.fill",
                    text: $name,
                    autocapitalization: .words
                )

                UGlassTextField(
                    placeholder: L10n.text("teamDescription"),
                    icon: "text.alignleft",
                    text: $description,
                    autocapitalization: .sentences
                )

                Button(L10n.validate) {
                    Task {
                        let success = await viewModel.updateTeam(
                            name: name,
                            description: description,
                            logo: logoImage
                        )
                        if success { dismiss() }
                    }
                }
                .primarySheetButton(isLoading: viewModel.isSubmitting)
                .disabled(viewModel.isSubmitting)
            }
            .padding(20)
        }
        .background(AuthScreenBackground())
        .navigationTitle(L10n.text("modifyTeamInformation"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TransferAdminSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TeamViewModel
    @State private var selectedMemberId = ""

    private var candidates: [TeamMember] {
        viewModel.selectedTeam?.resolvedMembers.filter {
            $0.role != .admin
        } ?? []
    }

    var body: some View {
        NavigationStack {
            List(candidates) { member in
                Button {
                    selectedMemberId = member.roleUpdateUserId
                } label: {
                    HStack {
                        Text(member.displayName)
                        Spacer()
                        if selectedMemberId == member.roleUpdateUserId {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppPalette.Primary.main)
                        }
                    }
                }
            }
            .navigationTitle(L10n.text("transferAdministration"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.confirm) {
                        Task {
                            if await viewModel.rosterViewModel.transferAdministration(to: selectedMemberId) {
                                dismiss()
                            }
                        }
                    }
                    .disabled(selectedMemberId.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#if DEBUG
#Preview("Admin") {
    TeamSettingsSheet(viewModel: .preview(role: .admin))
        .teamPreviewEnvironment()
}

#Preview("Joueur") {
    TeamSettingsSheet(viewModel: .preview(role: .player))
        .teamPreviewEnvironment()
}
#endif
