import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

/// Maps the icons in Finder's focused window to (row, col) grid
/// coordinates by reading their AX positions and clustering. Works
/// in icon view; unreliable in list/column view (callers should
/// ensure icon view first, e.g. by posting ⌘1).
enum FinderGrid {
    struct Cell: Equatable {
        let name: String
        let row: Int
        let col: Int
        let frame: CGRect
    }

    struct Layout {
        /// Row-major: `cells[row][col]`. Missing slots are nil when
        /// the grid is sparse.
        let cells: [[Cell?]]
        let rowCount: Int
        let colCount: Int
        /// Flat list of filled cells, useful for logging.
        let filled: [Cell]

        func cell(named name: String) -> Cell? {
            filled.first { $0.name == name }
        }
    }

    /// Programmatically selects the file whose name matches `filename`
    /// in the focused Finder window. Activates Finder first so the
    /// selection actually sticks (Finder otherwise accepts the AX
    /// write silently but doesn't repaint).
    ///
    /// Tries three strategies in order, returning true on first one
    /// that results in the target actually being selected:
    ///   1. Set `AXSelectedAttribute = true` on the icon element.
    ///   2. Set the icon's parent's `AXSelectedChildren` to `[icon]`.
    ///   3. Perform `AXPress` on the icon (acts like a click).
    @discardableResult
    static func selectFile(named filename: String) -> Bool {
        guard let window = focusedFinderWindow() else { return false }
        activateFinder()

        guard let (icon, parent) = findIconWithParent(
            in: window, matching: filename, parent: nil, depth: 0
        ) else { return false }

        // 1. AXSelected on the icon itself.
        _ = AXUIElementSetAttributeValue(
            icon, kAXSelectedAttribute as CFString, kCFBooleanTrue
        )
        if verifySelection(matches: filename) { return true }

        // 2. AXSelectedChildren on the parent.
        if let parent {
            let arr = [icon] as CFArray
            _ = AXUIElementSetAttributeValue(
                parent, kAXSelectedChildrenAttribute as CFString, arr
            )
            if verifySelection(matches: filename) { return true }
        }

        // 3. AXPress (acts like a click).
        _ = AXUIElementPerformAction(icon, kAXPressAction as CFString)
        if verifySelection(matches: filename) { return true }

        // 4. Fallback: synthesize a click at the icon's screen center.
        if let frame = frameOf(icon) {
            clickAt(CGPoint(x: frame.midX, y: frame.midY))
            if verifySelection(matches: filename) { return true }
        }
        return false
    }

    private static func clickAt(_ point: CGPoint) {
        let src = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(mouseEventSource: src, mouseType: .leftMouseDown,
                           mouseCursorPosition: point, mouseButton: .left)
        let up = CGEvent(mouseEventSource: src, mouseType: .leftMouseUp,
                         mouseCursorPosition: point, mouseButton: .left)
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    private static func activateFinder() {
        guard let finder = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.finder"
        ).first else { return }
        finder.activate(options: [.activateAllWindows])
        Thread.sleep(forTimeInterval: 0.12)
    }

    private static func verifySelection(matches name: String) -> Bool {
        Thread.sleep(forTimeInterval: 0.08)
        return FinderDrillPrototype.readFinderSelection() == name
    }

    private static func findIconWithParent(
        in element: AXUIElement,
        matching name: String,
        parent: AXUIElement?,
        depth: Int
    ) -> (AXUIElement, AXUIElement?)? {
        guard depth < 10 else { return nil }
        if let title = titleOf(element), title == name {
            return (element, parent)
        }
        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element, kAXChildrenAttribute as CFString, &children
        ) == .success, let kids = children as? [AXUIElement] else {
            return nil
        }
        for kid in kids {
            if let hit = findIconWithParent(in: kid, matching: name,
                                            parent: element, depth: depth + 1) {
                return hit
            }
        }
        return nil
    }

    /// Resizes the focused Finder window via AX to a fixed size. Makes
    /// icon layout deterministic (the icon view reflows on resize).
    static func resizeFocusedFinderWindow(to size: CGSize,
                                          origin: CGPoint = CGPoint(x: 100, y: 100)) {
        guard let window = focusedFinderWindow() else { return }
        setWindowFrame(window, size: size, origin: origin)
    }

    /// Moves the focused Finder window without changing its size.
    /// Safer than `resizeFocusedFinderWindow` because shrinking the
    /// window clips icons in icon view (Finder doesn't reflow on
    /// resize).
    static func moveFocusedFinderWindow(to origin: CGPoint) {
        guard let window = focusedFinderWindow() else { return }
        var pt = origin
        if let posValue = AXValueCreate(.cgPoint, &pt) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        }
    }

    /// Returns the focused Finder window's current frame in AX
    /// (top-left origin) coordinates, or nil if unavailable.
    static func focusedFinderWindowFrame() -> CGRect? {
        guard let window = focusedFinderWindow() else { return nil }
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let posRef, let sizeRef else { return nil }
        var pt = CGPoint.zero
        var sz = CGSize.zero
        guard AXValueGetValue(posRef as! AXValue, .cgPoint, &pt),
              AXValueGetValue(sizeRef as! AXValue, .cgSize, &sz) else { return nil }
        return CGRect(origin: pt, size: sz)
    }

    private static func setWindowFrame(_ window: AXUIElement,
                                       size: CGSize,
                                       origin: CGPoint) {
        var sz = size
        if let sizeValue = AXValueCreate(.cgSize, &sz) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
        var pt = origin
        if let posValue = AXValueCreate(.cgPoint, &pt) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        }
    }

    /// Enumerates icons in the focused Finder window and returns a
    /// row/col mapping. Rows and columns are derived by clustering
    /// the icons' AXPosition values: y-clustering → rows, x-clustering
    /// within each row → columns.
    static func readLayout() -> Layout? {
        guard let window = focusedFinderWindow() else { return nil }
        let icons = findIcons(in: window, depth: 0)
        guard !icons.isEmpty else { return nil }

        // Cluster y-coordinates into rows using a simple threshold on
        // half the median icon height — robust to minor pixel jitter.
        let heights = icons.compactMap { $0.frame.height }.sorted()
        let rowTol = (heights[heights.count / 2]) / 2.0
        let colTol = rowTol // icons are ~square

        let rows = cluster(values: icons.map { $0.frame.midY }, tolerance: rowTol)
            .sorted(by: <) // top to bottom
        let cols = cluster(values: icons.map { $0.frame.midX }, tolerance: colTol)
            .sorted(by: <) // left to right

        var grid = Array(repeating: Array<Cell?>(repeating: nil, count: cols.count),
                         count: rows.count)
        var filled: [Cell] = []
        for icon in icons {
            let row = nearestIndex(of: icon.frame.midY, in: rows)
            let col = nearestIndex(of: icon.frame.midX, in: cols)
            let cell = Cell(name: icon.name, row: row, col: col, frame: icon.frame)
            grid[row][col] = cell
            filled.append(cell)
        }
        return Layout(cells: grid,
                      rowCount: rows.count,
                      colCount: cols.count,
                      filled: filled)
    }

    // MARK: - AX traversal

    private struct Icon {
        let name: String
        let frame: CGRect
    }

    private static func focusedFinderWindow() -> AXUIElement? {
        guard let finder = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.finder"
        ).first else { return nil }
        let app = AXUIElementCreateApplication(finder.processIdentifier)
        var w: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            app, kAXFocusedWindowAttribute as CFString, &w
        ) == .success, let w else { return nil }
        return (w as! AXUIElement)
    }

    private static func findIcons(in element: AXUIElement, depth: Int) -> [Icon] {
        guard depth < 10 else { return [] }

        var results: [Icon] = []
        var role: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        let roleStr = role as? String ?? ""

        // Finder icons report as AXImage (rare) or AXStaticText, but
        // the containing element is typically AXGroup. The reliable
        // leaf signal is: element has a position + a non-empty title
        // that ends in .txt (our known file extension) — or, more
        // generally, has both a position and a title string.
        if roleStr != "AXWindow",
           let frame = frameOf(element),
           let name = titleOf(element),
           !name.isEmpty,
           name.contains(".") // filter to filename-like titles
        {
            results.append(Icon(name: name, frame: frame))
            return results // don't descend into an icon
        }

        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element, kAXChildrenAttribute as CFString, &children
        ) == .success, let kids = children as? [AXUIElement] else {
            return results
        }
        for kid in kids {
            results.append(contentsOf: findIcons(in: kid, depth: depth + 1))
        }
        return results
    }

    private static func titleOf(_ element: AXUIElement) -> String? {
        for attr in [kAXTitleAttribute, kAXDescriptionAttribute] {
            var v: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, attr as CFString, &v) == .success,
               let s = v as? String, !s.isEmpty { return s }
        }
        return nil
    }

    private static func frameOf(_ element: AXUIElement) -> CGRect? {
        var pos: CFTypeRef?
        var size: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &pos)
        AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &size)
        guard let pos, let size else { return nil }
        var p = CGPoint.zero
        var s = CGSize.zero
        guard AXValueGetValue(pos as! AXValue, .cgPoint, &p),
              AXValueGetValue(size as! AXValue, .cgSize, &s) else { return nil }
        return CGRect(origin: p, size: s)
    }

    // MARK: - Clustering

    /// Reduces a list of floats to cluster centers, where any pair
    /// within `tolerance` is considered the same cluster. Returns
    /// one center per cluster.
    private static func cluster(values: [CGFloat], tolerance: CGFloat) -> [CGFloat] {
        let sorted = values.sorted()
        var centers: [CGFloat] = []
        var current: [CGFloat] = []
        for v in sorted {
            if current.isEmpty || abs(v - current.last!) <= tolerance {
                current.append(v)
            } else {
                centers.append(current.reduce(0, +) / CGFloat(current.count))
                current = [v]
            }
        }
        if !current.isEmpty {
            centers.append(current.reduce(0, +) / CGFloat(current.count))
        }
        return centers
    }

    private static func nearestIndex(of value: CGFloat, in centers: [CGFloat]) -> Int {
        var bestIdx = 0
        var bestDist = CGFloat.infinity
        for (i, c) in centers.enumerated() {
            let d = abs(value - c)
            if d < bestDist { bestDist = d; bestIdx = i }
        }
        return bestIdx
    }
}

