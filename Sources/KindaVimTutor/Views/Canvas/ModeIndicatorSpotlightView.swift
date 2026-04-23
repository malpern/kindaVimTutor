import SwiftUI
import AppKit

/// A one-beat page: an animated arrow sweeps from a dot in the
/// lower-left up and out the upper-right, aimed at the live mode
/// chip in the toolbar. Draws once on appear, then stays.
///
/// Kept deliberately simple: no pulse, no replay tracker, no
/// settle-then-loop. One gesture, one time.
struct ModeIndicatorSpotlightView: View {
    @State private var dotVisible: Bool = false
    @State private var drawProgress: CGFloat = 0
    @State private var captionVisible: Bool = false

    var body: some View {
        GeometryReader { geo in
            // Spotlight is nested inside a 640-wide content column with
            // horizontal padding, so `geo.size` is NOT the mainUI
            // size. The INSERT chip lives in an overlay at the outer
            // mainUI HStack's top-right, at approximately (width-148,
            // 28) in mainUI coords. mainUI fills the window content
            // area, so its width == the window's content width. Reach
            // into NSApp for the hosting window and convert the chip's
            // mainUI position into the spotlight's local space using
            // the spotlight's own frame in .named("mainUI") space.
            let spotlightFrameInMainUI = geo.frame(in: .named("mainUI"))
            let mainUIWidth = Self.hostWindowContentWidth() ?? (spotlightFrameInMainUI.minX + geo.size.width)
            // Chip left edge ≈ width − 148, chip width ≈ 96, so center
            // ≈ width − 100. Tip lands just below the chip (y ≈ 48)
            // so the arrowhead stops under the badge instead of
            // overlapping it.
            let chipEndPoint = CGPoint(
                x: mainUIWidth - 100 - spotlightFrameInMainUI.minX,
                y: 48 - spotlightFrameInMainUI.minY
            )

            ZStack(alignment: .topLeading) {
                // Origin dot — tail anchor for the arrow.
                Circle()
                    .fill(Color.accentColor.opacity(0.9))
                    .frame(width: 9, height: 9)
                    .position(SpotlightArrow.startPoint(in: geo.size))
                    .opacity(dotVisible ? 1 : 0)
                    .scaleEffect(dotVisible ? 1 : 0.2)

                // Bezier curve + arrowhead chevrons in one path. Trim
                // reveals them together from tail to tip as one
                // pointing gesture.
                SpotlightArrow(size: geo.size, endPointOverride: chipEndPoint)
                    .trim(from: 0, to: drawProgress)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(
                            lineWidth: 2.6,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )

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
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(0.15)) {
                dotVisible = true
            }
            withAnimation(.easeOut(duration: 0.85).delay(0.55)) {
                drawProgress = 1
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
                captionVisible = true
            }
        }
    }

    /// The main window's content width — what mainUI fills. Used to
    /// locate the INSERT chip (top-right overlay on mainUI) from
    /// inside the spotlight's local coordinate space. Filter by the
    /// explicit "main" identifier so transient About/Settings windows
    /// being key don't return the wrong width.
    private static func hostWindowContentWidth() -> CGFloat? {
        if let main = NSApp.windows.first(where: {
            $0.identifier?.rawValue == "main" && $0.contentView != nil
        }) {
            return main.contentView?.bounds.width
        }
        return nil
    }
}

// MARK: - Arrow geometry

/// Hockey-stick curve: mostly horizontal along the bottom, hooks up
/// sharply near the end to land on the toolbar chip. Single Path
/// with arrowhead chevrons baked in so trim animates them together.
private struct SpotlightArrow: Shape {
    let size: CGSize
    /// The INSERT chip position in the spotlight's own coordinate
    /// space, computed by the parent via the "mainUI" coordinate
    /// space. The spotlight is nested in a centered 640-wide column
    /// so its local geometry can't locate the chip on its own.
    let endPointOverride: CGPoint

    private static let headLen: CGFloat = 14

    static func startPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: 30, y: size.height * 0.64)
    }

    /// Control point sits a bit to the left and below the chip so the
    /// curve hooks up tight against the right edge regardless of how
    /// much width the caller passes us.
    func controlPoint() -> CGPoint {
        CGPoint(x: endPointOverride.x - 12, y: size.height * 0.64)
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let start = Self.startPoint(in: size)
        let control = controlPoint()
        let end = endPointOverride

        p.move(to: start)
        p.addQuadCurve(to: end, control: control)

        // Arrowhead chevrons — legs from the tip angled back along the
        // curve's end tangent (end - control for a quadratic).
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

        let leftLeg = CGPoint(x: end.x + leftDX * Self.headLen,
                              y: end.y + leftDY * Self.headLen)
        let rightLeg = CGPoint(x: end.x + rightDX * Self.headLen,
                               y: end.y + rightDY * Self.headLen)

        p.addLine(to: leftLeg)
        p.move(to: end)
        p.addLine(to: rightLeg)
        return p
    }
}
