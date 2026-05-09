import SwiftUI

struct CurrencyDashboardCard: View {
    let symbol: String
    let quote: CachedMarketQuote?
    let isLoading: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(normalizedSymbol)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(DashboardPalette.deepInk)
                .lineLimit(1)

            Text(valueText)
                .font(.system(size: 23, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(DashboardPalette.deepInk)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(detailText)
                .font(.system(size: 15, weight: .medium).monospacedDigit())
                .foregroundStyle(detailColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(width: 148, height: 118)
        .dashboardCard()
    }

    private var normalizedSymbol: String {
        (try? normalizeCurrencyCode(symbol)) ?? normalizedDashboardSymbol(symbol)
    }

    private var state: MarketDataDisplayState {
        normalizedSymbol == "USD" ? .ready : displayState(quote: quote, isLoading: isLoading)
    }

    private var valueText: String {
        if normalizedSymbol == "USD" {
            return "1.00"
        }

        switch state {
        case .loading:
            return "Loading"
        case .error, .noData:
            return "--"
        case .ready:
            return quote.map { String(format: "%.4f", $0.data.price) } ?? "--"
        }
    }

    private var detailText: String {
        if normalizedSymbol == "USD" {
            return "Base currency"
        }

        switch state {
        case .loading:
            return "Fetching"
        case .error:
            return "Error"
        case .noData:
            return "No data"
        case .ready:
            return quote.map { formatPercent($0.data.changePercent) } ?? "No data"
        }
    }

    private var detailColor: Color {
        guard normalizedSymbol != "USD", let quote, state == .ready else {
            return DashboardPalette.muted
        }

        return quote.data.changePercent >= 0 ? DashboardPalette.positive : DashboardPalette.negative
    }
}
