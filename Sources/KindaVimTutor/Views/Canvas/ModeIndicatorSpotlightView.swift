import SwiftUI

/// A one-beat page: an animated arrow sweeps from the lower-left of
/// the content area up and out the upper-right, aimed at the live
/// mode chip in the toolbar. The arrow endpoint is intentionally
/// placed ABOVE the view's own top edge — SwiftUI doesn't clip
/// stroked shapes by default, so the line extends into the toolbar
/// area and lands visually on the real chip.
///
/// Obeys `AnimationReplayTracker` — on return visits within a
/// session the final state appears instantly, no redraw.
struct ModeIndicatorSpotlightView: View {
    private static let animationID = "spotlight.modeChip"

    @State private var drawProgress: CGFloat = 0
    @State private var pulse: Bool = false
    @State private var showHead: Bool = false
    @State private var captionVisible: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Arrow body — sketches in over ~0.7s. The shape is
                // drawn outside the view's top edge; parent doesn't
                // clip, so the stroke continues into the toolbar.
                SpotlightArrow(size: geo.size)
                    .trim(from: 0, to: drawProgress)
                    .stroke(
                        Color.accentColor.opacity(0.85),
                        style: StrokeStyle(
                            lineWidth: 2.5,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )

                if showHead {
                    ArrowHead()
                        .fill(Color.accentColor)
                        .frame(width: 22, height: 22)
                        .position(SpotlightArrow.endPoint(in: geo.size))
                        .scaleEffect(pulse ? 1.18 : 1.0)
                        .shadow(color: .accentColor.opacity(pulse ? 0.55 : 0.25),
                                radius: pulse ? 12 : 6)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                }

                // Caption — lower-left, out of the arrow's way.
                if captionVisible {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your live mode indicator lives up there.")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("Glance up while you practice — green means Normal, blue means Insert.")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: min(geo.size.width * 0.55, 480), alignment: .leading)
                    .position(
                        x: min(geo.size.width * 0.30, 260),
                        y: max(geo.size.height * 0.78, geo.size.height - 140)
                    )
                    .transition(.opacity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: handleAppear)
        .onDisappear {
            // Keep the "played" flag — session-scoped so we respect
            // back-nav — but reset local state so the next fresh
            // animation (if any) starts clean.
            drawProgress = 0
            showHead = false
            pulse = false
            captionVisible = false
        }
    }

    private func handleAppear() {
        let tracker = AnimationReplayTracker.shared
        if tracker.hasPlayed(Self.animationID) {
            // Already seen — jump to final state with no motion.
            drawProgress = 1
            showHead = true
            pulse = true
            captionVisible = true
            startPulseLoop()
            return
        }
        tracker.markPlayed(Self.animationID)
        runSequence()
    }

    private func runSequence() {
        withAnimation(.easeOut(duration: 0.75).delay(0.1)) {
            drawProgress = 1
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.25)) {
            captionVisible = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 950_000_000)
            withAnimation(.spring(duration: 0.35, bounce: 0.35)) {
                showHead = true
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            startPulseLoop()
        }
    }

    private func startPulseLoop() {
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            pulse = true
        }
    }
}

// MARK: - Arrow geometry

/// Bezier from the lower-left-ish of the view up and out the
/// upper-right. Endpoint is deliberately ABOVE the view's top edge
/// so it lands on or near the toolbar chip — SwiftUI shapes render
/// outside their frame when the parent doesn't clip.
private struct SpotlightArrow: Shape {
    let size: CGSize

    static func startPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.42, y: size.height * 0.62)
    }

    static func controlPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.75, y: size.height * 0.20)
    }

    /// Lands ABOVE the spotlight's own top (negative y) so the arrow
    /// extends into the toolbar region, ending at approximately the
    /// chip's horizontal position.
    static func endPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.96, y: -52)
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: Self.startPoint(in: size))
        p.addQuadCurve(
            to: Self.endPoint(in: size),
            control: Self.controlPoint(in: size)
        )
        return p
    }
}

private struct ArrowHead: Shape {
    func path(in rect: CGRect) -> Path {
        // Kite pointing up-and-right, roughly tangent to the bezier's
        // end direction.
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.95, y: h * 0.05))   // tip
        p.addLine(to: CGPoint(x: w * 0.10, y: h * 0.35))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.55))
        p.addLine(to: CGPoint(x: w * 0.35, y: h * 0.95))
        p.closeSubpath()
        return p
    }
}
