import SwiftUI

struct DashboardArcBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                DashboardPalette.page

                ForEach(0..<8, id: \.self) { index in
                    ArcShape(offset: CGFloat(index) * 43)
                        .stroke(DashboardPalette.action.opacity(index < 3 ? 0.18 : 0.10), lineWidth: index < 2 ? 2.3 : 1.5)
                        .frame(width: proxy.size.width * 1.5, height: 360 + CGFloat(index * 48))
                        .offset(x: -proxy.size.width * 0.18, y: 74 + CGFloat(index * 28))
                }
            }
            .ignoresSafeArea()
        }
    }
}

private struct ArcShape: Shape {
    let offset: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX - 40, y: rect.midY + offset))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX + 60, y: rect.midY + 32 + offset * 0.18),
            control: CGPoint(x: rect.midX, y: rect.minY - 110 + offset * 0.18)
        )
        return path
    }
}
