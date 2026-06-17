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
        case .right: return L10n.rightFoot
        case .left: return L10n.leftFoot
        case .both: return L10n.bothFeet
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
        case .premierLeague: return L10n.premierLeagueLabel
        case .ligue1: return L10n.ligue1Label
        case .bundesliga: return L10n.bundesligaLabel
        case .serieA: return L10n.serieALabel
        case .laLiga: return L10n.laLigaLabel
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
        case .goalkeeper: return L10n.goalkeeper
        case .centerBack: return L10n.centerBack
        case .rightBack: return L10n.rightBack
        case .leftBack: return L10n.leftBack
        case .defensiveMidfielder: return L10n.defensiveMidfielder
        case .centerMidfielder: return L10n.centerMidfielder
        case .attackingMidfielder: return L10n.attackingMidfielder
        case .rightWinger: return L10n.rightWinger
        case .leftWinger: return L10n.leftWinger
        case .striker: return L10n.striker
        case .secondStriker: return L10n.secondStriker
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
        case .beginner: return L10n.footballLevelBeginner
        case .intermediate: return L10n.footballLevelIntermediate
        case .advanced: return L10n.footballLevelAdvanced
        case .expert: return L10n.footballLevelExpert
        }
    }
}

enum Weekday: String, CaseIterable, Identifiable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .monday: return L10n.monday
        case .tuesday: return L10n.tuesday
        case .wednesday: return L10n.wednesday
        case .thursday: return L10n.thursday
        case .friday: return L10n.friday
        case .saturday: return L10n.saturday
        case .sunday: return L10n.sunday
        }
    }
}
