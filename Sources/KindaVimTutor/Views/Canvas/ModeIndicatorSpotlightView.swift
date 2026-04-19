import SwiftUI

/// A one-beat page: an animated arrow sweeps from the lower-left of
/// the content area up and out the upper-right, aimed at the live
/// mode chip in the toolbar. The bezier curve and the arrowhead
/// chevrons share a single Path; `Path.trim` reveals the whole
/// stroke as one drawing gesture, so the head rides the tip rather
/// than popping in separately.
///
/// Obeys `AnimationReplayTracker` — on return visits within a
/// session the final state appears instantly, no redraw.
struct ModeIndicatorSpotlightView: View {
    private static let animationID = "spotlight.modeChip"

    @State private var drawProgress: CGFloat = 0
    @State private var pulse: Bool = false
    @State private var captionVisible: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Single stroked path — bezier + arrowhead chevrons
                // live in the same Path, so trim animates them together
                // as one pointing gesture.
                SpotlightArrow(size: geo.size)
                    .trim(from: 0, to: drawProgress)
                    .stroke(
                        Color.accentColor.opacity(pulse ? 1.0 : 0.85),
                        style: StrokeStyle(
                            lineWidth: 2.6,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .shadow(
                        color: .accentColor.opacity(pulse ? 0.45 : 0.12),
                        radius: pulse ? 10 : 4
                    )
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                               value: pulse)

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
            drawProgress = 0
            pulse = false
            captionVisible = false
        }
    }

    private func handleAppear() {
        let tracker = AnimationReplayTracker.shared
        if tracker.hasPlayed(Self.animationID) {
            drawProgress = 1
            captionVisible = true
            pulse = true
            return
        }
        tracker.markPlayed(Self.animationID)
        runSequence()
    }

    private func runSequence() {
        // Draws the whole curve + arrowhead as one continuous stroke.
        withAnimation(.easeOut(duration: 0.95).delay(0.1)) {
            drawProgress = 1
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
            captionVisible = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            pulse = true
        }
    }
}

// MARK: - Arrow geometry

/// Swooping cubic bezier from the lower-left of the view up and over
/// to the upper-right, landing just above the view's own top edge
/// where the live mode chip sits in the toolbar. Cubic (two control
/// points) rather than quadratic gives a properly swoopy arc — the
/// stroke rises steeply before sweeping right into the tip rather
/// than tracing a near-straight diagonal.
///
/// The arrowhead chevrons are appended to the same Path so trim
/// reveals them together with the curve as one pointing gesture.
private struct SpotlightArrow: Shape {
    let size: CGSize

    /// Length of each arrowhead chevron leg, in points.
    private static let headLen: CGFloat = 14

    static func startPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.30, y: size.height * 0.75)
    }

    /// First control point — directly above the start. Pulls the
    /// curve STRAIGHT UP out of the tail.
    static func control1(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.32, y: size.height * 0.15)
    }

    /// Second control point — up and left of the tip. Pulls the curve
    /// OVER toward the right to glide into the arrowhead.
    static func control2(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.70, y: -60)
    }

    /// The tip lands slightly above the spotlight's own top edge so
    /// the stroke extends into the toolbar strip and reads as
    /// pointing AT the chip — not overshooting above it.
    static func endPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.92, y: -18)
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let start = Self.startPoint(in: size)
        let c1 = Self.control1(in: size)
        let c2 = Self.control2(in: size)
        let end = Self.endPoint(in: size)

        p.move(to: start)
        p.addCurve(to: end, control1: c1, control2: c2)

        // Arrowhead chevrons — legs from the tip angled back along
        // the curve's end tangent. Tangent of a cubic bezier at t=1
        // is (end - c2).
        let dx = end.x - c2.x
        let dy = end.y - c2.y
        let len = max(sqrt(dx * dx + dy * dy), 0.001)
        let ux = dx / len, uy = dy / len

        let angle: CGFloat = .pi * (140.0 / 180.0)
        let cosA = cos(angle), sinA = sin(angle)
        let leftDX  = ux * cosA - uy * sinA
        let leftDY  = ux * sinA + uy * cosA
        let rightDX = ux * cosA + uy * sinA
        let rightDY = -ux * sinA + uy * cosA

        let leftLeg  = CGPoint(x: end.x + leftDX  * Self.headLen,
                               y: end.y + leftDY  * Self.headLen)
        let rightLeg = CGPoint(x: end.x + rightDX * Self.headLen,
                               y: end.y + rightDY * Self.headLen)

        p.addLine(to: leftLeg)
        p.move(to: end)
        p.addLine(to: rightLeg)
        return p
    }
}
