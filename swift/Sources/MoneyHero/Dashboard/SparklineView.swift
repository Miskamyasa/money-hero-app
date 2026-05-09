import SwiftUI

struct SparklineView: View {
    let values: [Double]
    let positive: Bool

    var body: some View {
        SparklineShape(values: values)
            .stroke(positive ? DashboardPalette.positive : DashboardPalette.negative, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
            .background {
                SparklineShape(values: values)
                    .fill(
                        LinearGradient(
                            colors: [
                                (positive ? DashboardPalette.positive : DashboardPalette.negative).opacity(values.isEmpty ? 0 : 0.18),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
    }
}

private struct SparklineShape: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        guard values.count > 1, let minValue = values.min(), let maxValue = values.max() else {
            return Path()
        }

        let spread = max(maxValue - minValue, 0.0001)
        var path = Path()

        for index in values.indices {
            let progress = CGFloat(index) / CGFloat(values.count - 1)
            let normalized = CGFloat((values[index] - minValue) / spread)
            let point = CGPoint(
                x: rect.minX + progress * rect.width,
                y: rect.maxY - normalized * rect.height
            )

            if index == values.startIndex {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        return path
    }
}
