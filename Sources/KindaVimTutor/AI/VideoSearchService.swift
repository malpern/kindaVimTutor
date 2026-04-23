import Foundation

struct VideoResult: Identifiable, Equatable {
    let id = UUID()
    let videoId: String
    let title: String
    let channel: String
    let duration: String?   // "3:42"
    let viewCount: String?  // "123K views"
    let isShort: Bool

    var url: URL {
        if isShort {
            return URL(string: "https://www.youtube.com/shorts/\(videoId)")!
        }
        return URL(string: "https://www.youtube.com/watch?v=\(videoId)")!
    }

    var thumbnailURL: URL {
        URL(string: "https://img.youtube.com/vi/\(videoId)/mqdefault.jpg")!
    }
}

/// Scrapes YouTube's search results page for videos + shorts. Pure
/// Swift — parses the `ytInitialData` JSON blob embedded in the
/// page. No API key, no Python dependency. If YouTube ever breaks
/// the HTML shape, the fix lives entirely in this file.
enum VideoSearchService {
    /// Channel handles / display-name fragments to exclude from
    /// results. Matched case-insensitively against both the channel
    /// name and the canonical URL (/@handle) of each hit.
    private static let blockedChannels: [String] = [
        "@vimindiaofficial",
        "vim india",
    ]

    private static func isBlocked(channelName: String, channelURL: String) -> Bool {
        let haystack = (channelName + " " + channelURL).lowercased()
        return blockedChannels.contains { haystack.contains($0.lowercased()) }
    }

    static func search(_ query: String) async -> (shorts: [VideoResult], videos: [VideoResult]) {
        guard var components = URLComponents(string: "https://www.youtube.com/results") else {
            return ([], [])
        }
        components.queryItems = [URLQueryItem(name: "search_query", value: query)]
        guard let url = components.url else { return ([], []) }

        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.timeoutInterval = 8

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let html = String(data: data, encoding: .utf8) else {
                logEmpty(query: query, reason: "non-utf8 response")
                return ([], [])
            }
            guard let json = extractInitialData(from: html) else {
                logEmpty(query: query, reason: "ytInitialData not found")
                return ([], [])
            }
            let parsed = parse(json: json)
            if parsed.shorts.isEmpty && parsed.videos.isEmpty {
                logEmpty(query: query, reason: "parser returned 0 results")
            }
            return parsed
        } catch {
            logEmpty(query: query, reason: "network error: \(error.localizedDescription)")
            return ([], [])
        }
    }

    /// Emits a warning when the scraper returns nothing so we notice
    /// if YouTube changes its HTML shape. The chat still degrades
    /// gracefully; this just surfaces breakage in the app log.
    private static func logEmpty(query: String, reason: String) {
        AppLogger.shared.warn("chat.videoSearch", "empty",
                              fields: ["query": query, "reason": reason])
    }

    // MARK: - Extract ytInitialData

    private static func extractInitialData(from html: String) -> [String: Any]? {
        guard let range = html.range(of: "var ytInitialData = ") else { return nil }
        let tail = html[range.upperBound...]
        // Scan forward tracking brace depth to find the terminating `}`.
        var depth = 0
        var inString = false
        var escape = false
        var endIndex: String.Index?
        for idx in tail.indices {
            let ch = tail[idx]
            if escape { escape = false; continue }
            if ch == "\\" { escape = true; continue }
            if ch == "\"" { inString.toggle(); continue }
            if inString { continue }
            if ch == "{" { depth += 1 }
            else if ch == "}" {
                depth -= 1
                if depth == 0 { endIndex = tail.index(after: idx); break }
            }
        }
        guard let end = endIndex else { return nil }
        let jsonString = String(tail[..<end])
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    // MARK: - Parse

    private static func parse(json: [String: Any]) -> (shorts: [VideoResult], videos: [VideoResult]) {
        var shorts: [VideoResult] = []
        var videos: [VideoResult] = []
        var seenShortIds: Set<String> = []
        var seenVideoIds: Set<String> = []

        // YouTube shuffles the JSON shape per release. Walk the
        // whole tree and harvest anything that looks like a video
        // or short — more tolerant than hard-coded paths.
        walk(json, collect: { node in
            if let videoRenderer = node["videoRenderer"] as? [String: Any],
               let v = parseVideo(videoRenderer),
               seenVideoIds.insert(v.videoId).inserted {
                videos.append(v)
                return
            }
            if let model = node["shortsLockupViewModel"] as? [String: Any],
               let s = parseShort(from: ["shortsLockupViewModel": model]),
               seenShortIds.insert(s.videoId).inserted {
                shorts.append(s)
                return
            }
            if let reel = node["reelItemRenderer"] as? [String: Any],
               let s = parseShort(from: ["reelItemRenderer": reel]),
               seenShortIds.insert(s.videoId).inserted {
                shorts.append(s)
                return
            }
        })

        // Drop anything whose title advertises an unsupported Vim
        // feature (macros, splits, folds, …) so the "learn more"
        // rail stays aligned with what kindaVim actually does.
        let filteredShorts = shorts.filter { !ContentRelevanceFilter.shouldDrop(title: $0.title) }
        let filteredVideos = videos.filter { !ContentRelevanceFilter.shouldDrop(title: $0.title) }
        return (shorts: Array(filteredShorts.prefix(4)),
                videos: Array(filteredVideos.prefix(3)))
    }

    /// Depth-first traversal of the ytInitialData tree. Calls
    /// `collect` with every dictionary node it visits so the caller
    /// can pattern-match on whichever renderer keys are present.
    private static func walk(_ value: Any, collect: ([String: Any]) -> Void) {
        if let dict = value as? [String: Any] {
            collect(dict)
            for v in dict.values { walk(v, collect: collect) }
        } else if let array = value as? [Any] {
            for v in array { walk(v, collect: collect) }
        }
    }

    private static func parseVideo(_ r: [String: Any]) -> VideoResult? {
        guard let videoId = r["videoId"] as? String else { return nil }
        let title = firstRun(r["title"]) ?? ""
        let ownerText = (r["ownerText"] as? [String: Any])
            ?? (r["longBylineText"] as? [String: Any])
            ?? [:]
        let channel = firstRun(ownerText as Any) ?? ""
        let channelURL = channelCanonicalURL(ownerText)
        if isBlocked(channelName: channel, channelURL: channelURL) { return nil }

        let duration = (r["lengthText"] as? [String: Any])?["simpleText"] as? String
        let views = (r["viewCountText"] as? [String: Any])?["simpleText"] as? String
            ?? firstRun(r["viewCountText"])
        return VideoResult(
            videoId: videoId,
            title: title,
            channel: channel,
            duration: duration,
            viewCount: views,
            isShort: false
        )
    }

    private static func channelCanonicalURL(_ ownerText: [String: Any]) -> String {
        guard let runs = ownerText["runs"] as? [[String: Any]],
              let first = runs.first,
              let nav = first["navigationEndpoint"] as? [String: Any],
              let browse = nav["browseEndpoint"] as? [String: Any],
              let url = browse["canonicalBaseUrl"] as? String else { return "" }
        return url
    }

    private static func parseShort(from item: [String: Any]) -> VideoResult? {
        if let model = item["shortsLockupViewModel"] as? [String: Any] {
            // YouTube stores the real video ID in multiple places.
            // `entityId` sometimes looks like "shortsLockupViewModel-XXXX"
            // and sometimes carries metadata prefixes we can't
            // predict, so prefer the explicit watch endpoint when
            // we can find it — the fallback is the stripped
            // entityId, validated as an 11-char YouTube ID.
            let videoId = videoIdFromOnTap(model)
                ?? stripEntityId(model["entityId"] as? String ?? "")
                ?? ""
            guard isValidVideoId(videoId) else { return nil }

            let overlay = model["overlayMetadata"] as? [String: Any]
            let primary = (overlay?["primaryText"] as? [String: Any])?["content"] as? String ?? ""
            let secondary = (overlay?["secondaryText"] as? [String: Any])?["content"] as? String
            let serialized = (try? JSONSerialization.data(withJSONObject: model))
                .flatMap { String(data: $0, encoding: .utf8) } ?? ""
            if isBlocked(channelName: "", channelURL: serialized) { return nil }
            return VideoResult(
                videoId: videoId,
                title: primary,
                channel: "",
                duration: nil,
                viewCount: secondary,
                isShort: true
            )
        }
        if let reel = item["reelItemRenderer"] as? [String: Any],
           let videoId = reel["videoId"] as? String,
           isValidVideoId(videoId) {
            let title = firstRun(reel["headline"]) ?? ""
            let views = firstRun(reel["viewCountText"])
            let serialized = (try? JSONSerialization.data(withJSONObject: reel))
                .flatMap { String(data: $0, encoding: .utf8) } ?? ""
            if isBlocked(channelName: "", channelURL: serialized) { return nil }
            return VideoResult(
                videoId: videoId,
                title: title,
                channel: "",
                duration: nil,
                viewCount: views,
                isShort: true
            )
        }
        return nil
    }

    /// Walks `onTap.innertubeCommand.reelWatchEndpoint.videoId` or
    /// the nearby `watchEndpoint.videoId`, whichever YouTube has
    /// populated for this lockup. Returns nil when neither is present.
    private static func videoIdFromOnTap(_ model: [String: Any]) -> String? {
        let onTap = model["onTap"] as? [String: Any]
        let cmd = onTap?["innertubeCommand"] as? [String: Any]
        if let reel = cmd?["reelWatchEndpoint"] as? [String: Any],
           let id = reel["videoId"] as? String { return id }
        if let watch = cmd?["watchEndpoint"] as? [String: Any],
           let id = watch["videoId"] as? String { return id }
        return nil
    }

    private static func stripEntityId(_ raw: String) -> String? {
        let stripped = raw.replacingOccurrences(
            of: "shortsLockupViewModel-", with: ""
        )
        return stripped.isEmpty ? nil : stripped
    }

    /// YouTube video IDs are 11 characters of `[A-Za-z0-9_-]`.
    /// Guarding against anything else keeps garbage IDs from
    /// producing broken img.youtube.com URLs.
    private static func isValidVideoId(_ id: String) -> Bool {
        guard id.count == 11 else { return false }
        return id.allSatisfy {
            $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-"
        }
    }

    /// Extracts the first text run from a `{runs:[{text:...}]}` or
    /// `{simpleText:...}` shaped node, which YouTube uses in both
    /// places depending on version.
    private static func firstRun(_ value: Any?) -> String? {
        guard let dict = value as? [String: Any] else { return nil }
        if let simple = dict["simpleText"] as? String { return simple }
        if let runs = dict["runs"] as? [[String: Any]] {
            return runs.compactMap { $0["text"] as? String }.joined()
        }
        return nil
    }
}
