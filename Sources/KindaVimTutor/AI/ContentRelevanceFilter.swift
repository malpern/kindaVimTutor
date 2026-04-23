import Foundation

/// Drops video and web search results whose titles clearly advertise
/// Vim features kindaVim doesn't implement (macros, splits, ex
/// commands, folds, etc.). Keywords are derived from the
/// `# keywords: ...` annotations in `kindavim-support.txt` — single
/// source of truth lives next to the unsupported command list.
///
/// Strictness is mild: title-only match, whole-word, case-insensitive.
/// A blog post about "split testing in Vim" still passes (no whole
/// word "split" in a navigation context); a video titled "Vim
/// macros tutorial" gets dropped.
enum ContentRelevanceFilter {
    /// Returns true when the title matches any unsupported-concept
    /// keyword as a whole word. Uses the support corpus's derived
    /// keyword list — no hardcoded taxonomy here, so adding a new
    /// unsupported group is a one-line edit in the support file.
    static func shouldDrop(title: String) -> Bool {
        let lowered = title.lowercased()
        for keyword in KindaVimSupportCorpus.shared.unsupportedKeywords {
            let needle = keyword.lowercased()
            if matchesAsWord(lowered, needle: needle) {
                AppLogger.shared.info(
                    "chat.filter", "dropped",
                    fields: ["title": title, "keyword": keyword]
                )
                return true
            }
        }
        return false
    }

    /// Returns true when `needle` appears in `haystack` with word
    /// boundaries on both sides — so `"split"` matches `"vim splits"`
    /// but not `"spitball"`. Keywords that already contain spaces
    /// (e.g. `"ex command"`, `"named register"`) still benefit since
    /// the boundary check runs on the whole needle.
    private static func matchesAsWord(_ haystack: String, needle: String) -> Bool {
        guard !needle.isEmpty else { return false }
        guard let range = haystack.range(of: needle) else { return false }

        let before: Character? = range.lowerBound == haystack.startIndex
            ? nil
            : haystack[haystack.index(before: range.lowerBound)]
        let after: Character? = range.upperBound == haystack.endIndex
            ? nil
            : haystack[range.upperBound]

        func isWordBoundary(_ c: Character?) -> Bool {
            guard let c else { return true }
            return !(c.isLetter || c.isNumber || c == "_")
        }

        return isWordBoundary(before) && isWordBoundary(after)
    }
}
