//
//  MatchCompositionViewerSheet.swift
//  LeVestaire
//

import SwiftUI

struct MatchCompositionViewerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MatchDetailViewModel
    @ObservedObject var compositionViewModel: MatchDetailCompositionViewModel

    init(viewModel: MatchDetailViewModel) {
        self.viewModel = viewModel
        self.compositionViewModel = viewModel.compositionViewModel
    }

    private var composition: TeamComposition? { viewModel.match?.composition }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if let composition {
                    MatchCompositionPreviewView(
                        composition: composition,
                        members: viewModel.editorMembers,
                        isCompositionLocked: viewModel.match?.isCompositionLocked == true,
                        style: .full
                    )
                    .padding(20)
                }
            }
            .background(AuthScreenBackground())
            .navigationTitle(L10n.text("composition"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.close) { dismiss() }
                }
            }
        }
        .task {
            await compositionViewModel.loadSelectablePlayers()
        }
    }
}

#if DEBUG
#Preview("Compo verrouillée") {
    MatchCompositionViewerSheet(viewModel: MatchDetailViewModel(matchId: "preview"))
        .teamPreviewEnvironment()
}
#endif
