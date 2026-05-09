import SwiftUI

struct DashboardTotalBalanceSection: View {
    let hasHoldings: Bool
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NumberedSectionHeader(number: 2, title: "Total Balance")

            VStack(spacing: 12) {
                Text(amountText)
                    .font(.system(size: 39, weight: .heavy, design: .rounded))
                    .foregroundStyle(DashboardPalette.deepInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                HStack(spacing: 12) {
                    Text(changeText)
                        .foregroundStyle(DashboardPalette.positive)
                        .fontWeight(.bold)
                    Text("in 1 Year")
                        .foregroundStyle(DashboardPalette.muted)
                }
                .font(.system(size: 17, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .dashboardCard()
        }
    }

    private var amountText: String {
        hasHoldings && isLoading ? "Loading" : "ILS --"
    }

    private var changeText: String {
        "--"
    }
}
