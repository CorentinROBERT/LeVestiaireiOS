//
//  MatchCompositionSummarySection.swift
//  LeVestaire
//

import SwiftUI

struct MatchCompositionSummarySection: View {
    @ObservedObject var viewModel: MatchDetailViewModel
    let match: MatchDetail

    var body: some View {
        if let composition = match.composition {
            UCard(title: L10n.text("composition"), icon: "person.3.fill") {
                MatchCompositionPreviewView(
                    composition: composition,
                    members: viewModel.editorMembers,
                    isCompositionLocked: match.isCompositionLocked,
                    style: .compact
                )
            }
            .task {
                await viewModel.loadSelectablePlayers()
            }
        }
    }
}

#if DEBUG
#Preview {
    MatchCompositionSummarySection(
        viewModel: .preview(),
        match: MatchPreviewData.detail()
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
