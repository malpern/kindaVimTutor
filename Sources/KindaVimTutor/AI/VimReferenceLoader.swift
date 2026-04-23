import Foundation

/// Loads the bundled Vim help files once and assembles them into the
/// grounding block we feed the LLM. The files are the authoritative
/// Vim manual (`motion.txt`, `change.txt`, `index.txt`) fetched from
/// the vim/vim runtime and bundled as resources. Using the canonical
/// text keeps the on-device model from inventing motions that don't
/// exist or misremembering option names.
enum VimReferenceLoader {
    static let shared = load()

    private static func load() -> String {
        let files = ["motion", "change", "index"]
        var out = "# Vim reference (authoritative)\n\n"
        for name in files {
            guard let url = Bundle.module.url(
                forResource: name,
                withExtension: "txt",
                subdirectory: "vim-reference"
            ), let text = try? String(contentsOf: url, encoding: .utf8)
            else { continue }
            out.append("## \(name).txt\n\n\(text)\n\n")
        }
        return out
    }
}
