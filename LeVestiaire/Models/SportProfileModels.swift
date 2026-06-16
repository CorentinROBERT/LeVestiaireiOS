//
//  SportProfileModels.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import Foundation

enum StrongFoot: String, CaseIterable, Identifiable {
    case right
    case left
    case both

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .right: return "Droit"
        case .left: return "Gauche"
        case .both: return "Ambidextre"
        }
    }
}

enum FootballLeague: String, CaseIterable, Identifiable {
    case ligue1 = "ligue-1"
    case premierLeague = "premier-league"
    case bundesliga
    case serieA = "serie-a"
    case laLiga = "la-liga"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .premierLeague: return "Premier League"
        case .ligue1: return "Ligue 1"
        case .bundesliga: return "Bundesliga"
        case .serieA: return "Serie A"
        case .laLiga: return "La Liga"
        }
    }
}

enum PlayerPosition: String, CaseIterable, Identifiable {
    case goalkeeper
    case centerBack
    case rightBack
    case leftBack
    case defensiveMidfielder
    case centerMidfielder
    case attackingMidfielder
    case rightWinger
    case leftWinger
    case striker
    case secondStriker

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .goalkeeper: return "Gardien"
        case .centerBack: return "Défenseur central"
        case .rightBack: return "Défenseur droit"
        case .leftBack: return "Défenseur gauche"
        case .defensiveMidfielder: return "Milieu défensif"
        case .centerMidfielder: return "Milieu central"
        case .attackingMidfielder: return "Milieu offensif"
        case .rightWinger: return "Ailier droit"
        case .leftWinger: return "Ailier gauche"
        case .striker: return "Attaquant"
        case .secondStriker: return "Second attaquant"
        }
    }
}

enum ExperienceLevel: Int, CaseIterable, Identifiable {
    case beginner = 0
    case intermediate = 1
    case advanced = 2
    case expert = 3

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .beginner: return "Débutant"
        case .intermediate: return "Intermédiaire"
        case .advanced: return "Avancé"
        case .expert: return "Expert"
        }
    }
}

enum Weekday: String, CaseIterable, Identifiable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .monday: return "Lundi"
        case .tuesday: return "Mardi"
        case .wednesday: return "Mercredi"
        case .thursday: return "Jeudi"
        case .friday: return "Vendredi"
        case .saturday: return "Samedi"
        case .sunday: return "Dimanche"
        }
    }
}
