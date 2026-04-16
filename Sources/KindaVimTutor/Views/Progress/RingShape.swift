import SwiftUI

struct RingShape: Shape {
    var progress: Double
    var startAngle: Angle = .degrees(-90)

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let endAngle = startAngle + .degrees(360 * min(max(progress, 0), 1))
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}
