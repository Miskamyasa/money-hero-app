import SwiftUI

struct DashboardExpectedBalanceSection: View {
    let hasHoldings: Bool
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NumberedSectionHeader(number: 3, title: "Expected Balance")

            HStack(spacing: 12) {
                ProjectionCard(title: "In 1 Year", amount: amountText, change: changeText)
                ProjectionCard(title: "In 5 Years", amount: amountText, change: changeText)
            }
        }
    }

    private var amountText: String {
        hasHoldings && isLoading ? "Loading" : "ILS --"
    }

    private var changeText: String {
        "--"
    }
}
