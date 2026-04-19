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
                // Small filled dot at the arrow's origin — anchors the
                // start of the gesture. Appears with the stroke so it
                // reads as "the line emerges from here".
                Circle()
                    .fill(Color.accentColor.opacity(0.9))
                    .frame(width: 9, height: 9)
                    .position(SpotlightArrow.startPoint(in: geo.size))
                    .opacity(drawProgress > 0.02 ? 1 : 0)
                    .scaleEffect(drawProgress > 0.02 ? 1 : 0.2)
                    .animation(.spring(duration: 0.3, bounce: 0.35), value: drawProgress > 0.02)

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

/// Hockey-stick curve: mostly horizontal along the bottom, then
/// hooks UP sharply near the end to land on the chip. Single control
/// point placed near the END's x at the START's y — keeps the bezier
/// hugging the bottom-horizontal for most of its length, then the
/// attractor to the high tip pulls it into a sharp upward bend at the
/// very end. Reads as "sweep across, then point up" instead of the
/// smoother diagonal the cubic was giving.
///
/// Arrowhead chevrons are appended to the same Path so trim reveals
/// them with the curve as one pointing gesture. The tangent at t=1 is
/// (end - control), which for this control-point layout points almost
/// straight up — so the chevrons naturally aim at the chip.
private struct SpotlightArrow: Shape {
    let size: CGSize

    /// Length of each arrowhead chevron leg, in points.
    private static let headLen: CGFloat = 14

    static func startPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.28, y: size.height * 0.72)
    }

    /// Far-right, near-start-y. Keeps the curve low and near-horizontal
    /// for most of its length, then the high tip pulls it into a
    /// sharp upward hook.
    static func controlPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.88, y: size.height * 0.68)
    }

    /// The tip lands slightly above the spotlight's own top edge so
    /// the stroke extends into the toolbar strip and reads as
    /// pointing AT the chip — not overshooting past it.
    static func endPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.92, y: -18)
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let start = Self.startPoint(in: size)
        let control = Self.controlPoint(in: size)
        let end = Self.endPoint(in: size)

        p.move(to: start)
        p.addQuadCurve(to: end, control: control)

        // Arrowhead chevrons — from the tip, angled back along the
        // curve's end tangent. Tangent of a quadratic bezier at t=1
        // is (end - control). With this layout it points nearly
        // straight up, so the chevrons face the chip.
        let dx = end.x - control.x
        let dy = end.y - control.y
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
