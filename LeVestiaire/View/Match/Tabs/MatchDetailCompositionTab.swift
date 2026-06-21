//
//  MatchDetailCompositionTab.swift
//  LeVestaire
//

import SwiftUI

struct MatchDetailCompositionTab: View {
    @ObservedObject var viewModel: MatchDetailViewModel
    let match: MatchDetail

    var body: some View {
        Group {
            if let composition = match.composition {
                MatchCompositionPreviewView(
                    composition: composition,
                    members: viewModel.editorMembers,
                    isCompositionLocked: match.isCompositionLocked,
                    style: .compact
                )
            } else {
                TeamEmptyState(
                    icon: "person.3.fill",
                    title: L10n.text("noCompositionAvailable"),
                    message: emptyMessage
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            await viewModel.loadSelectablePlayers()
        }
    }

    private var emptyMessage: String {
        switch match.status {
        case .upcoming, .ongoing, .finished:
            return L10n.text("compositionWillBeAvailable")
        case .cancelled:
            return L10n.text("matchCancelledBeforeStart")
        default:
            return L10n.text("compositionWillBeAvailable")
        }
    }
}

#if DEBUG
#Preview("Composition") {
    MatchDetailCompositionTab(
        viewModel: .preview(),
        match: MatchPreviewData.detail()
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
