import Foundation

enum ContentBlock: Sendable {
    case text(String)
    case heading(String)
    case tip(String)
    case important(String)
    case keyCommand(keys: [String], description: String)
    case codeExample(before: String, after: String, motion: String)
    case spacer
}
