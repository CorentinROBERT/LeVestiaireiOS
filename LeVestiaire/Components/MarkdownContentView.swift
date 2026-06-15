//
//  MarkdownContentView.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import SwiftUI

private enum MarkdownBlock: Identifiable {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case listItem(text: String)

    var id: String {
        switch self {
        case .heading(let level, let text):
            return "h\(level)-\(text)"
        case .paragraph(let text):
            return "p-\(text)"
        case .listItem(let text):
            return "li-\(text)"
        }
    }
}

private enum MarkdownParser {
    static func parse(_ markdown: String) -> [MarkdownBlock] {
        let normalized = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else { return [] }

        var blocks: [MarkdownBlock] = []

        for rawBlock in normalized.components(separatedBy: "\n\n") {
            let trimmed = rawBlock.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let lines = trimmed.components(separatedBy: "\n")

            if lines.allSatisfy(isListLine) {
                lines.forEach { line in
                    blocks.append(.listItem(text: listItemText(from: line)))
                }
                continue
            }

            if lines.count == 1, let heading = parseHeading(lines[0]) {
                blocks.append(heading)
                continue
            }

            var paragraphLines: [String] = []

            func flushParagraph() {
                guard !paragraphLines.isEmpty else { return }
                blocks.append(.paragraph(text: paragraphLines.joined(separator: "\n")))
                paragraphLines = []
            }

            for line in lines {
                if let heading = parseHeading(line) {
                    flushParagraph()
                    blocks.append(heading)
                } else if isListLine(line) {
                    flushParagraph()
                    blocks.append(.listItem(text: listItemText(from: line)))
                } else {
                    paragraphLines.append(line)
                }
            }

            flushParagraph()
        }

        return blocks
    }

    private static func isListLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ")
    }

    private static func listItemText(from line: String) -> String {
        String(line.trimmingCharacters(in: .whitespaces).dropFirst(2))
    }

    private static func parseHeading(_ line: String) -> MarkdownBlock? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("#") else { return nil }

        var level = 0
        for character in trimmed where character == "#" {
            level += 1
        }

        guard (1...6).contains(level), trimmed.count > level else { return nil }

        let afterHashes = trimmed.dropFirst(level)
        guard afterHashes.first == " " else { return nil }

        let text = String(afterHashes.dropFirst()).trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }

        return .heading(level: level, text: text)
    }
}

struct MarkdownContentView: View {
    let markdown: String

    private var blocks: [MarkdownBlock] {
        MarkdownParser.parse(markdown)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                blockView(block)
                    .padding(.top, topSpacing(for: block, at: index))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            inlineMarkdownText(text)
                .font(fontForHeading(level))
                .fontWeight(.semibold)
                .foregroundStyle(level <= 2 ? AppPalette.Primary.dark : AppPalette.Neutral.textPrimary)

        case .paragraph(let text):
            inlineMarkdownText(text)
                .font(.body)
                .foregroundStyle(AppPalette.Neutral.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

        case .listItem(let text):
            HStack(alignment: .top, spacing: 10) {
                Text("•")
                    .font(.body)
                    .foregroundStyle(AppPalette.Primary.main)
                    .padding(.top, 1)

                inlineMarkdownText(text)
                    .font(.body)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func topSpacing(for block: MarkdownBlock, at index: Int) -> CGFloat {
        guard index > 0 else { return 0 }

        switch block {
        case .heading(let level, _):
            return level == 1 ? 8 : 20
        case .paragraph, .listItem:
            return 10
        }
    }

    private func fontForHeading(_ level: Int) -> Font {
        switch level {
        case 1:
            return .title2
        case 2:
            return .title3
        case 3:
            return .headline
        default:
            return .subheadline
        }
    }

    private func inlineMarkdownText(_ source: String) -> Text {
        if let attributed = try? AttributedString(
            markdown: source,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            return Text(attributed)
        }

        return Text(source)
    }
}

#Preview {
    ScrollView {
        MarkdownContentView(markdown: """
        # Titre principal

        **Date :** 12 octobre 2025

        ## Section

        Paragraphe avec du *texte* et du **gras**.

        - Premier élément
        - Deuxième élément
        """)
        .padding()
    }
}
