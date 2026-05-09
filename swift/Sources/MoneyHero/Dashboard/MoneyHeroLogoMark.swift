import SwiftUI

struct MoneyHeroLogoMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(DashboardPalette.ink.opacity(0.18), lineWidth: 1)

            HStack(spacing: 3) {
                logoBar(height: 20, color: DashboardPalette.ink)
                logoBar(height: 29, color: Color(red: 0.12, green: 0.64, blue: 0.55))
                logoBar(height: 36, color: Color(red: 0.18, green: 0.78, blue: 0.86))
                logoBar(height: 25, color: DashboardPalette.ink)
            }
            .rotationEffect(.degrees(-28))
        }
    }

    private func logoBar(height: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color)
            .frame(width: 6, height: height)
    }
}
