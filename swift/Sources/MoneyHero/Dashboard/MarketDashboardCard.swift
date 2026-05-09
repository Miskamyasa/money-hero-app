import SwiftUI

struct MarketDashboardCard: View {
    let symbol: String
    let title: String
    let quote: CachedMarketQuote?
    let history: [Double]
    let isLoading: Bool

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                MarketIcon(symbol: symbol)
                    .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 5) {
                    Text("\(title) (\(symbol))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(DashboardPalette.deepInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(priceText)
                        .font(.system(size: 22, weight: .regular, design: .rounded).monospacedDigit())
                        .foregroundStyle(priceColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 12)

                SparklineView(values: history, positive: isPositive)
                    .frame(width: 116, height: 42)

                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DashboardPalette.muted)
            }

            Divider()

            HStack {
                PeriodChangeLabel(label: "1M", value: periodValue(quote?.data.change1m ?? quote?.data.changePercent))
                Spacer()
                Divider().frame(height: 22)
                Spacer()
                PeriodChangeLabel(label: "6M", value: periodValue(quote?.data.change6m))
                Spacer()
                Divider().frame(height: 22)
                Spacer()
                PeriodChangeLabel(label: "2Y", value: periodValue(quote?.data.change2y))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(18)
        .dashboardCard()
    }

    private var state: MarketDataDisplayState {
        displayState(quote: quote, isLoading: isLoading)
    }

    private var priceText: String {
        switch state {
        case .loading:
            return "Fetching"
        case .error:
            return "Error"
        case .noData:
            return "No data"
        case .ready:
            guard let quote else {
                return "--"
            }
            return formatPrice(quote.data.price, currency: quote.data.currency)
        }
    }

    private var priceColor: Color {
        state == .ready ? DashboardPalette.deepInk : DashboardPalette.muted
    }

    private var isPositive: Bool {
        (quote?.data.changePercent ?? fallbackChange(for: symbol)) >= 0
    }

    private func periodValue(_ value: Double?) -> Double? {
        state == .ready ? value : nil
    }
}
