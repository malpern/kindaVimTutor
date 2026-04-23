# Feedback Assistant radar: NavigationSplitView sidebar scroll-shift on detail state changes (macOS 26)

Paste the sections below into the matching fields at
<https://feedbackassistant.apple.com>. Attach the minimal-repro zip
built from the sample project at the end.

---

## Title

SwiftUI: `NavigationSplitView` sidebar scrolls its selected row out of
view when detail-pane state changes on macOS 26

## Area / Framework

SwiftUI (macOS). Likely also AppKit bridge for `NSSplitViewController`
/ sidebar `NSTableView`.

## Which beta / OS

- macOS 26.3.1 (shipping) and earlier 26.x
- Xcode 26 (shipping)

## What

In a SwiftUI `NavigationSplitView` with `List(selection:)` or
`ScrollView { VStack }` in the sidebar, any state change in the detail
pane that triggers a layout pass (e.g. a SwiftUI `.transition`, a
view-identity swap via `.id()`, or appearance of a view using a
custom `Layout` protocol implementation) causes the sidebar's
currently-selected row to scroll vertically — typically into the
window's toolbar strip, where it becomes partially or fully hidden
behind the title bar.

The sidebar view's `body` is **not re-evaluated** during the shift
(confirmed via `Self._printChanges()` and a logged counter in
`body` — 0 invocations between the user-initiated detail change and
the visible sidebar movement). The scroll change therefore originates
below SwiftUI's view-update machinery — most likely inside the
`NSSplitViewController` / sidebar `NSTableView` that backs
`NavigationSplitView` on macOS.

Pressing the reverse navigation key (going back in the detail) restores
the correct scroll position. The bug does not occur on iOS / iPadOS
with the same view tree.

## Steps to reproduce

1. Create a SwiftUI macOS app (macOS 26, Xcode 26).
2. Build a `NavigationSplitView` with:
   - Sidebar: `List(selection:)` or `ScrollView { LazyVStack }` of
     row buttons; programmatic selection bound to a published
     identifier.
   - Detail: a view whose body contains a custom `Layout` (e.g. a
     simple word-wrapping layout) rendering inline text runs.
3. Include a `.toolbar { ... }` on the window to get the OS 26
     unified title bar.
4. Run the app on macOS 26.x.
5. Make a single programmatic change in the detail view that triggers
     SwiftUI to re-lay out that column (e.g. advance a step counter
     that causes a different child view to render under `.id(...)`).

## Expected result

Sidebar remains visually stationary. Selected row stays at its
established scroll position.

## Actual result

Sidebar scrolls upward such that the selected row slides into (and
partially behind) the window's toolbar strip. Chapter headers /
section headings above the selection are pushed off-screen. The
sidebar's `body` never re-evaluates — the shift happens entirely
inside the split-view container's layout pass.

## What we tried that does NOT fix it

- Caching `Layout.sizeThatFits` results via `Layout.Cache` keyed by
  proposal width.
- `.fixedSize(horizontal: false, vertical: true)` on the custom
  `Layout` host.
- Pinning the toolbar background to `.visible`.
- Removing `sharedBackgroundVisibility(.hidden)` on the toolbar.
- Replacing `List(selection:)` with `ScrollView { LazyVStack }` in the
  sidebar.
- Removing `.id(step.id)` from the detail's view-identity swap.
- Removing `.transition(...)` from the detail container.
- Removing `.animation(_:value:)` from the detail container.
- Counter-scrolling via `ScrollViewReader.scrollTo` on a
  `NotificationCenter` signal (doesn't fire because the sidebar's
  `body` doesn't re-evaluate).

## What DOES work

Replacing `NavigationSplitView` with a plain `HStack { sidebar |
Divider | detail }` — the bug disappears completely, including for
detail views that use custom `Layout`. This strongly suggests the
issue lives in SwiftUI's `NavigationSplitView` implementation for
macOS 26, not in the detail view's own layout.

## Context / related issues

Similar-shape `NavigationSplitView` regressions already reported for
macOS 26 / Tahoe:

- Detail-pane buttons not clickable in safe area (macOS 26). Apple
  Developer Forums: <https://developer.apple.com/forums/thread/740035>
- Nested `NavigationSplitView` layout regression in macOS 26.3.
  Apple Developer Forums:
  <https://developer.apple.com/forums/thread/815650>
- `NavigationSplitView` + `.toolbar` duplicate `splitViewSeparator`
  identifier error. Apple Developer Forums:
  <https://developer.apple.com/forums/thread/759875>
- Tahoe sidebar icon sizing wrong in SwiftUI
  `NavigationSplitView`. Apple Developer Forums:
  <https://developer.apple.com/forums/thread/812205>
- "Mutually exclusive constraint error in SwiftUI view only on macOS
  26". Hacking with Swift Forums:
  <https://www.hackingwithswift.com/forums/swiftui/mutually-exclusive-constraint-error-in-swiftui-view-only-on-macos-26/30137>

## Minimal reproducing project

See attached `NSVSidebarShiftRepro.zip`. Relevant shape:

```swift
import SwiftUI

@main
struct ReproApp: App {
    @State private var selected: Int? = 1
    @State private var step = 0

    var body: some Scene {
        Window("Repro", id: "main") {
            NavigationSplitView {
                List(selection: $selected) {
                    ForEach(0..<12, id: \.self) { i in
                        Text("Row \(i)").tag(Int?.some(i))
                    }
                }
                .frame(minWidth: 200)
            } detail: {
                VStack {
                    Button("Advance (press space)") { step += 1 }
                        .keyboardShortcut(.space, modifiers: [])
                    WrappingText(text: "word1 word2 word3 word4 word5 \(step)")
                        .id(step)                       // force rebuild
                }
                .padding(40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 900, minHeight: 600)
            .toolbar {
                ToolbarItem { Text("Step \(step)") }
            }
        }
    }
}

private struct WrappingText: View {
    let text: String
    var body: some View {
        WrapLayout {
            ForEach(text.split(separator: " ").map(String.init), id: \.self) { w in
                Text(w).padding(2)
            }
        }
    }
}

private struct WrapLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews,
                      cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var rowW: CGFloat = 0, rowH: CGFloat = 0
        var totalH: CGFloat = 0, totalW: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if rowW + s.width > maxW, rowW > 0 {
                totalH += rowH; totalW = max(totalW, rowW)
                rowW = 0; rowH = 0
            }
            rowW += s.width; rowH = max(rowH, s.height)
        }
        totalH += rowH; totalW = max(totalW, rowW)
        return CGSize(width: min(totalW, maxW), height: totalH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowH; rowH = 0
            }
            sv.place(at: CGPoint(x: x, y: y), anchor: .topLeading,
                     proposal: .unspecified)
            x += s.width; rowH = max(rowH, s.height)
        }
    }
}
```

## Impact

Forces macOS-26 apps that want a native unified toolbar, the
system-drawn sidebar toggle, and `⌘⌃S` View-menu integration to
either:

1. Ship with a visible sidebar shift on every detail-pane advance —
   visibly broken UX — or
2. Abandon `NavigationSplitView` for a custom split implementation,
   losing all the platform-provided toolbar / menu integration.

For our app (a keyboard-motion tutor that advances detail state on
every user keypress), (1) is not acceptable and (2) is a multi-day
refactor and a permanent regression in OS integration.
