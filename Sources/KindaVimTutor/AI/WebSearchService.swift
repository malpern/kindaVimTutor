import Foundation

struct WebResult: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let snippet: String
    let url: URL
    let host: String
    /// YouTube video ID when the result is a youtube.com/watch link.
    /// Used to render a thumbnail card instead of a text card.
    let youTubeVideoId: String?
}

/// Runs a DuckDuckGo HTML search and parses the result cards. No API
/// key — DDG's `/html/` endpoint returns server-rendered results we
/// can regex out. The host also detects YouTube watch URLs so the
/// caller can render thumbnail cards for those.
enum WebSearchService {
    static func search(_ query: String) async -> [WebResult] {
        guard var components = URLComponents(string: "https://duckduckgo.com/html/") else {
            return []
        }
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        guard let url = components.url else { return [] }

        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        request.timeoutInterval = 6

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let html = String(data: data, encoding: .utf8) else {
                AppLogger.shared.warn("chat.webSearch", "empty",
                                      fields: ["query": query, "reason": "non-utf8"])
                return []
            }
            let parsed = parse(html: html)
                .filter { !ContentRelevanceFilter.shouldDrop(title: $0.title) }
            let results = Array(parsed.prefix(3))
            if results.isEmpty {
                AppLogger.shared.warn("chat.webSearch", "empty",
                                      fields: ["query": query, "reason": "parser returned 0"])
            }
            return results
        } catch {
            AppLogger.shared.warn("chat.webSearch", "empty",
                                  fields: ["query": query,
                                           "reason": "network: \(error.localizedDescription)"])
            return []
        }
    }

    /// DDG wraps each result in `<a class="result__a" href="...">TITLE</a>`
    /// followed (in some position) by `<a class="result__snippet">SNIPPET</a>`.
    /// The href on result__a is a redirect — unwrap the `uddg` param.
    private static func parse(html: String) -> [WebResult] {
        let titlePattern = #"<a[^>]*class=\"result__a\"[^>]*href=\"([^\"]+)\"[^>]*>([\s\S]*?)</a>"#
        let snippetPattern = #"<a[^>]*class=\"result__snippet\"[^>]*>([\s\S]*?)</a>"#

        let titleMatches = regexMatches(in: html, pattern: titlePattern)
        let snippetMatches = regexMatches(in: html, pattern: snippetPattern)

        var results: [WebResult] = []
        for (i, m) in titleMatches.enumerated() {
            guard m.count >= 3 else { continue }
            let rawHref = m[1]
            let titleHTML = m[2]
            let snippetHTML = i < snippetMatches.count && snippetMatches[i].count >= 2
                ? snippetMatches[i][1] : ""

            guard let url = unwrap(rawHref) else { continue }
            let host = url.host?.lowercased() ?? ""
            let videoId = youTubeVideoId(in: url)

            let result = WebResult(
                title: strip(titleHTML),
                snippet: strip(snippetHTML),
                url: url,
                host: host.replacingOccurrences(of: "www.", with: ""),
                youTubeVideoId: videoId
            )
            if !result.title.isEmpty {
                results.append(result)
            }
        }
        return results
    }

    private static func unwrap(_ rawHref: String) -> URL? {
        let decoded = rawHref.replacingOccurrences(of: "&amp;", with: "&")
        // DDG redirector: //duckduckgo.com/l/?uddg=<encoded>&...
        if let range = decoded.range(of: "uddg=") {
            let tail = decoded[range.upperBound...]
            let end = tail.firstIndex(of: "&") ?? tail.endIndex
            let encoded = String(tail[..<end])
            if let decodedUrl = encoded.removingPercentEncoding,
               let url = URL(string: decodedUrl) {
                return url
            }
        }
        // Fallback: treat raw href as a URL (DDG may also embed direct links)
        if decoded.hasPrefix("//") {
            return URL(string: "https:" + decoded)
        }
        return URL(string: decoded)
    }

    private static func youTubeVideoId(in url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        if host.contains("youtube.com") {
            let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
            return comps?.queryItems?.first(where: { $0.name == "v" })?.value
        }
        if host.contains("youtu.be") {
            return url.pathComponents.last
        }
        return nil
    }

    private static func strip(_ html: String) -> String {
        let entityDecoded = html
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
        let tagPattern = #"<[^>]+>"#
        let noTags = entityDecoded.replacingOccurrences(
            of: tagPattern, with: "", options: .regularExpression
        )
        return noTags.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func regexMatches(in text: String, pattern: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, options: [], range: range).map { match in
            (0..<match.numberOfRanges).compactMap { i in
                guard let r = Range(match.range(at: i), in: text) else { return nil }
                return String(text[r])
            }
        }
    }
}
