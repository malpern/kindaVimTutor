import Foundation

/// A single piece of lesson explanatory content. Cases map 1:1 onto renderable
/// UI elements in `ContentStepView` / `ExplanationView`.
public enum ContentBlock: Sendable {
    case text(String)
    case heading(String)
    case tip(String)
    case important(String)
    case keyCommand(keys: [String], description: String)
    case codeExample(before: String, after: String, motion: String)
    case spacer
}
