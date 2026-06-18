//
//  AppPalette.swift
//  LeVestaire
//
//  Created by Corentin Robert on 12/06/2026.
//

import SwiftUI
import UIKit

/// Palette de couleurs de l'application.
/// Primaires : bleu & blanc. Secondaires : corail (accent chaud), ardoise (neutre), menthe (positif).
enum AppPalette {

    // MARK: - Primaires (bleu)

    enum Primary {
        /// Bleu principal — boutons, liens, icônes actives
        static let main = adaptive(
            light: rgb(0.15, 0.42, 0.88),
            dark: rgb(0.40, 0.65, 0.98)
        )
        /// Bleu foncé (light) / titres clairs (dark)
        static let dark = adaptive(
            light: rgb(0.10, 0.22, 0.48),
            dark: rgb(0.92, 0.95, 1.00)
        )
        /// Bleu clair — icônes, états survolés
        static let light = adaptive(
            light: rgb(0.18, 0.45, 0.88),
            dark: rgb(0.52, 0.72, 0.98)
        )
        /// Bleu atténué — placeholders, icônes secondaires dans les champs
        static let muted = adaptive(
            light: rgb(0.35, 0.55, 0.82),
            dark: rgb(0.58, 0.72, 0.90)
        )
        /// Bleu très pâle — halos et fonds décoratifs
        static let soft = adaptive(
            light: rgb(0.84, 0.91, 0.99),
            dark: rgb(0.14, 0.20, 0.32)
        )
        /// Texte sur bouton primaire
        static let onMain = Color.white
        /// Fond bouton d'action forte (ex. déconnexion) — ne pas confondre avec `dark` (titres)
        static let buttonStrong = adaptive(
            light: rgb(0.10, 0.22, 0.48),
            dark: rgb(0.40, 0.65, 0.98)
        )
    }

    // MARK: - Neutres (blanc & gris bleuté)

    enum Neutral {
        /// Fond principal quasi blanc / bleu nuit
        static let background = adaptive(
            light: rgb(0.98, 0.99, 1.00),
            dark: rgb(0.06, 0.08, 0.12)
        )
        /// Fond intermédiaire du dégradé
        static let backgroundMid = adaptive(
            light: rgb(0.92, 0.96, 1.00),
            dark: rgb(0.08, 0.12, 0.20)
        )
        /// Fond bas de dégradé
        static let backgroundDeep = adaptive(
            light: rgb(0.84, 0.91, 0.99),
            dark: rgb(0.10, 0.16, 0.28)
        )
        /// Surface carte / panneau glass
        static let surface = adaptive(
            light: rgb(1.00, 1.00, 1.00),
            dark: rgb(0.14, 0.18, 0.26)
        )
        /// Halo décoratif de fond
        static let decorativeGlow = adaptive(
            light: rgb(1.00, 1.00, 1.00),
            dark: rgb(0.22, 0.32, 0.48)
        )
        /// Texte principal
        static let textPrimary = adaptive(
            light: rgb(0.12, 0.18, 0.32),
            dark: rgb(0.94, 0.96, 1.00)
        )
        /// Texte secondaire, labels
        static let textSecondary = adaptive(
            light: rgb(0.10, 0.22, 0.48, alpha: 0.65),
            dark: rgb(0.78, 0.84, 0.92, alpha: 0.85)
        )
        /// Texte tertiaire, hints
        static let textTertiary = adaptive(
            light: rgb(0.10, 0.22, 0.48, alpha: 0.55),
            dark: rgb(0.62, 0.70, 0.82, alpha: 0.90)
        )
        /// Séparateurs, bordures légères
        static let border = adaptive(
            light: rgb(0.78, 0.86, 0.94),
            dark: rgb(0.28, 0.36, 0.48)
        )
    }

    // MARK: - Secondaires (complémentaires au bleu)

    enum Secondary {
        /// Corail — complémentaire chaud du bleu, badges, highlights, CTA secondaires
        static let coral = adaptive(
            light: rgb(0.96, 0.45, 0.36),
            dark: rgb(0.98, 0.58, 0.50)
        )
        /// Corail foncé — texte sur fond clair
        static let coralDark = adaptive(
            light: rgb(0.78, 0.28, 0.22),
            dark: rgb(0.92, 0.62, 0.56)
        )
        /// Ardoise — neutre froid, textes désactivés, fonds alternatifs
        static let slate = adaptive(
            light: rgb(0.42, 0.50, 0.62),
            dark: rgb(0.58, 0.66, 0.76)
        )
        /// Ardoise claire — fonds de section
        static let slateLight = adaptive(
            light: rgb(0.90, 0.93, 0.96),
            dark: rgb(0.18, 0.22, 0.30)
        )
        /// Menthe — succès, stats positives, validation sportive
        static let mint = adaptive(
            light: rgb(0.20, 0.72, 0.62),
            dark: rgb(0.36, 0.82, 0.72)
        )
        /// Menthe foncée — texte de succès
        static let mintDark = adaptive(
            light: rgb(0.10, 0.48, 0.42),
            dark: rgb(0.52, 0.88, 0.78)
        )
    }

    // MARK: - Sémantiques

    enum Semantic {
        static let success = Secondary.mint
        static let successDark = Secondary.mintDark
        static let warning = adaptive(
            light: rgb(0.95, 0.68, 0.22),
            dark: rgb(0.98, 0.78, 0.36)
        )
        static let error = adaptive(
            light: rgb(0.88, 0.24, 0.28),
            dark: rgb(0.98, 0.42, 0.46)
        )
        static let info = Primary.light
    }

    // MARK: - Helpers

    private static func rgb(_ red: Double, _ green: Double, _ blue: Double, alpha: Double = 1.0) -> Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    private static func adaptive(light: Color, dark: Color) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
