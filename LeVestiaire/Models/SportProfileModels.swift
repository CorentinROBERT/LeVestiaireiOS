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
    case ambidextrous

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .right: return "Droit"
        case .left: return "Gauche"
        case .ambidextrous: return "Ambidextre"
        }
    }
}

enum FootballLeague: String, CaseIterable, Identifiable {
    case premierLeague
    case ligue1
    case bundesliga
    case serieA
    case laLiga

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .premierLeague: return "Premier League"
        case .ligue1: return "Ligue 1"
        case .bundesliga: return "Bundesliga"
        case .serieA: return "Serie A"
        case .laLiga: return "Liga"
        }
    }

    var teams: [String] {
        switch self {
        case .premierLeague:
            return [
                "Arsenal", "Aston Villa", "Brighton", "Chelsea", "Crystal Palace",
                "Everton", "Fulham", "Liverpool", "Manchester City", "Manchester United",
                "Newcastle", "Nottingham Forest", "Tottenham", "West Ham", "Wolverhampton",
            ]
        case .ligue1:
            return [
                "Paris SG", "Marseille", "Lyon", "Monaco", "Lille", "Nice", "Lens",
                "Rennes", "Strasbourg", "Nantes", "Montpellier", "Reims", "Toulouse",
            ]
        case .bundesliga:
            return [
                "Bayern Munich", "Borussia Dortmund", "Bayer Leverkusen", "RB Leipzig",
                "Stuttgart", "Eintracht Frankfurt", "Wolfsburg", "Freiburg", "Hoffenheim",
                "Werder Bremen", "Union Berlin", "Mainz",
            ]
        case .serieA:
            return [
                "Inter Milan", "AC Milan", "Juventus", "Napoli", "Roma", "Lazio",
                "Atalanta", "Fiorentina", "Torino", "Bologna", "Udinese", "Genoa",
            ]
        case .laLiga:
            return [
                "Real Madrid", "Barcelona", "Atletico Madrid", "Sevilla", "Villarreal",
                "Real Sociedad", "Athletic Bilbao", "Real Betis", "Valencia", "Girona",
                "Osasuna", "Celta Vigo",
            ]
        }
    }
}

enum PlayerPosition: String, CaseIterable, Identifiable {
    case goalkeeper
    case centerBack
    case fullBack
    case defensiveMidfielder
    case centralMidfielder
    case attackingMidfielder
    case winger
    case striker

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .goalkeeper: return "Gardien"
        case .centerBack: return "Défenseur central"
        case .fullBack: return "Défenseur latéral"
        case .defensiveMidfielder: return "Milieu défensif"
        case .centralMidfielder: return "Milieu central"
        case .attackingMidfielder: return "Milieu offensif"
        case .winger: return "Ailier"
        case .striker: return "Attaquant"
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
