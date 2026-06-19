//
//  FormationCatalog.swift
//  LeVestaire
//

import CoreGraphics
import Foundation

struct FormationPosition: Identifiable, Equatable {
    let id: String
    let label: String
    let normalizedPoint: CGPoint

    var localizedMarkerLabel: String {
        FormationPositionLabels.localizedMarker(for: label)
    }
}

struct FormationTemplate: Identifiable, Equatable {
    let id: String
    let displayName: String
    let positions: [FormationPosition]

    func slotIds(forCategory category: String) -> [String] {
        switch category {
        case "Goalkeeper":
            return positions.filter { $0.id == "GK" || $0.label == "GB" }.map(\.id)
        case "Defense":
            return positions.filter { $0.label == "D" }.map(\.id)
        case "Midfield":
            return positions.filter { $0.label == "M" }.map(\.id)
        case "Attack":
            return positions.filter { $0.label == "A" }.map(\.id)
        default:
            return []
        }
    }
}

enum FormationCatalog {
    static let defaultFormationKey = "1-3-2-1"

    static var all: [FormationTemplate] {
        [
            template(
                id: "1-3-2-1",
                positions: [
                    ("GK", "GB", 0.50, 0.90),
                    ("D1", "D", 0.20, 0.72),
                    ("D2", "D", 0.50, 0.74),
                    ("D3", "D", 0.80, 0.72),
                    ("M1", "M", 0.35, 0.52),
                    ("M2", "M", 0.65, 0.52),
                    ("A1", "A", 0.50, 0.28)
                ]
            ),
            template(
                id: "1-2-3-1",
                positions: [
                    ("GK", "GB", 0.50, 0.90),
                    ("D1", "D", 0.32, 0.72),
                    ("D2", "D", 0.68, 0.72),
                    ("M1", "M", 0.22, 0.52),
                    ("M2", "M", 0.50, 0.50),
                    ("M3", "M", 0.78, 0.52),
                    ("A1", "A", 0.50, 0.26)
                ]
            ),
            template(
                id: "1-2-2-2",
                positions: [
                    ("GK", "GB", 0.50, 0.90),
                    ("D1", "D", 0.32, 0.72),
                    ("D2", "D", 0.68, 0.72),
                    ("M1", "M", 0.38, 0.52),
                    ("M2", "M", 0.62, 0.52),
                    ("A1", "A", 0.35, 0.28),
                    ("A2", "A", 0.65, 0.28)
                ]
            ),
            template(
                id: "1-3-1-2",
                positions: [
                    ("GK", "GB", 0.50, 0.90),
                    ("D1", "D", 0.20, 0.72),
                    ("D2", "D", 0.50, 0.74),
                    ("D3", "D", 0.80, 0.72),
                    ("M1", "M", 0.50, 0.52),
                    ("A1", "A", 0.35, 0.28),
                    ("A2", "A", 0.65, 0.28)
                ]
            ),
            template(
                id: "1-4-1-1",
                positions: [
                    ("GK", "GB", 0.50, 0.90),
                    ("D1", "D", 0.15, 0.72),
                    ("D2", "D", 0.38, 0.74),
                    ("D3", "D", 0.62, 0.74),
                    ("D4", "D", 0.85, 0.72),
                    ("M1", "M", 0.50, 0.52),
                    ("A1", "A", 0.50, 0.26)
                ]
            )
        ]
    }

    static func template(for key: String) -> FormationTemplate? {
        all.first { $0.id == key }
    }

    private static func template(
        id: String,
        positions: [(String, String, CGFloat, CGFloat)]
    ) -> FormationTemplate {
        FormationTemplate(
            id: id,
            displayName: id,
            positions: positions.map { key, label, x, y in
                FormationPosition(
                    id: key,
                    label: label,
                    normalizedPoint: CGPoint(x: x, y: y)
                )
            }
        )
    }
}

enum FormationPositionLabels {
    static func localizedMarker(for code: String) -> String {
        switch code {
        case "GB":
            return L10n.text("positionCodeGK")
        case "D":
            return L10n.text("positionCodeDEF")
        case "M":
            return L10n.text("positionCodeMID")
        case "A":
            return L10n.text("positionCodeATT")
        default:
            return code
        }
    }
}
