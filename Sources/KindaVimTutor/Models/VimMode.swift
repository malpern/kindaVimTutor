import SwiftUI

enum VimMode: String, Sendable {
    case normal
    case insert
    case visual
    case unknown

    var displayName: String {
        switch self {
        case .normal: "NORMAL"
        case .insert: "INSERT"
        case .visual: "VISUAL"
        case .unknown: "—"
        }
    }

    var color: Color {
        switch self {
        case .normal: .green
        case .insert: .blue
        case .visual: .purple
        case .unknown: .secondary
        }
    }

    var systemImage: String {
        switch self {
        case .normal: "command"
        case .insert: "character.cursor.ibeam"
        case .visual: "selection.pin.in.out"
        case .unknown: "questionmark.circle"
        }
    }
}
