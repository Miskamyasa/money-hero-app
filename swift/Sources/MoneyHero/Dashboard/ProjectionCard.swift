import SwiftUI

struct ProjectionCard: View {
    let title: String
    let amount: String
    let change: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(DashboardPalette.positive.opacity(0.14))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(DashboardPalette.positive)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(DashboardPalette.deepInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("Conservative")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DashboardPalette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }

            VStack(spacing: 10) {
                Text(amount)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(DashboardPalette.deepInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                Text(change)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(change == "--" ? DashboardPalette.muted : DashboardPalette.positive)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 154, alignment: .topLeading)
        .dashboardCard()
    }
}
