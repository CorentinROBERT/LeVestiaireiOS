//
//  MatchQuizStatementRow.swift
//  LeVestaire
//

import SwiftUI

struct MatchQuizStatementRow: View {
    let index: Int
    let text: String
    @Binding var selection: Bool?
    var isEditable: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(index). \(text)")
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isEditable {
                USegmentedPicker(
                    title: L10n.text("trueFalse"),
                    selection: bindingSelection
                ) {
                    Text(L10n.text("undefinedAnswer")).tag(Optional<Bool>.none)
                    Text(L10n.text("trueValue")).tag(Optional(true))
                    Text(L10n.text("falseValue")).tag(Optional(false))
                }
            } else if let selection {
                Text(selection ? L10n.text("trueValue") : L10n.text("falseValue"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.Primary.main)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppPalette.Neutral.surface)
        )
    }

    private var bindingSelection: Binding<Bool?> {
        Binding(
            get: { selection },
            set: { selection = $0 }
        )
    }
}

#if DEBUG
#Preview {
    MatchQuizStatementRow(
        index: 1,
        text: "Le match s'est terminé sur une victoire.",
        selection: .constant(true)
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
