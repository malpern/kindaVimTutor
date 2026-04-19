import SwiftUI

/// A one-beat page: an animated arrow extends from the caption up-and-right
/// toward where the live mode chip lives in the toolbar, with a soft
/// breathing pulse on the arrowhead once it lands.
///
/// The arrow exits this view's top-right corner — the real chip sits just
/// beyond in the same direction, so the gesture lands on it visually even
/// though we're not plumbing coordinates.
struct ModeIndicatorSpotlightView: View {
    @State private var drawProgress: CGFloat = 0
    @State private var pulse: Bool = false
    @State private var showHead: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Arrow body — draws in over ~0.8s using trim, so the
                // line appears to be sketched out toward the chip.
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

                // Arrowhead appears once the trail reaches its tip.
                // Breathes gently so it holds attention if the learner
                // lingers on the page.
                if showHead {
                    ArrowHead()
                        .fill(Color.accentColor)
                        .frame(width: 20, height: 20)
                        .position(SpotlightArrow.endPoint(in: geo.size))
                        .scaleEffect(pulse ? 1.15 : 1.0)
                        .shadow(color: .accentColor.opacity(pulse ? 0.5 : 0.2),
                                radius: pulse ? 10 : 6)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                }

                // Caption — bottom-left of the spotlight area, leaving
                // the upper-right clear so the arrow has room to sweep.
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your live mode indicator lives here.")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Glance up while you practice — it turns green when you're in Normal and blue when you're typing.")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: geo.size.width * 0.58, alignment: .leading)
                .position(
                    x: geo.size.width * 0.30,
                    y: geo.size.height * 0.72
                )
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .onAppear(perform: runSequence)
        .onDisappear {
            drawProgress = 0
            showHead = false
            pulse = false
        }
    }

    private func runSequence() {
        withAnimation(.easeOut(duration: 0.85).delay(0.2)) {
            drawProgress = 1
        }
        // Land the arrowhead when the trail reaches the tip, then start
        // the breathing loop.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_050_000_000)
            withAnimation(.spring(duration: 0.35, bounce: 0.35)) {
                showHead = true
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Arrow path

/// Quadratic bezier from lower-left to upper-right of the given frame.
/// Exits the top-right edge so the arrowhead gestures OUT of the
/// content area, toward the real chip in the toolbar.
private struct SpotlightArrow: Shape {
    let size: CGSize

    static func startPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.44, y: size.height * 0.55)
    }

    static func controlPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.70, y: size.height * 0.25)
    }

    static func endPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.94, y: size.height * 0.10)
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
        // Triangle pointing up-and-right, roughly aligned with the
        // bezier's tangent at the end point. Not exact — a small
        // rotation beats computing the precise tangent.
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.95, y: h * 0.05))   // tip (upper-right)
        p.addLine(to: CGPoint(x: w * 0.10, y: h * 0.35))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.55))
        p.addLine(to: CGPoint(x: w * 0.35, y: h * 0.95))
        p.closeSubpath()
        return p
    }
}
