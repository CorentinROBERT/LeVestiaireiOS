//
//  DeepLinkParser.swift
//  LeVestaire
//

import Foundation

enum DeepLinkParser {
    static func teamInviteCode(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        if let code = queryCode(from: components), isJoinDestination(components) {
            return code
        }

        // Universal links sometimes arrive with only query items on the root path.
        if let code = queryCode(from: components), components.host?.contains("squad-locker") == true {
            return code
        }

        return nil
    }

    private static func isJoinDestination(_ components: URLComponents) -> Bool {
        let host = components.host?.lowercased() ?? ""
        let path = components.path
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if host == "join" || path == "join" {
            return true
        }

        return path.hasSuffix("/join")
    }

    private static func queryCode(from components: URLComponents) -> String? {
        guard let raw = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return nil
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
