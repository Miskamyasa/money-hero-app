import SwiftUI

struct PeriodChangeLabel: View {
    let label: String
    let value: Double?

    var body: some View {
        HStack(spacing: 7) {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DashboardPalette.deepInk)

            Text(value.map(formatPercent) ?? "--")
                .font(.system(size: 16, weight: .semibold).monospacedDigit())
                .foregroundStyle((value ?? 0) >= 0 ? DashboardPalette.positive : DashboardPalette.negative)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
}
