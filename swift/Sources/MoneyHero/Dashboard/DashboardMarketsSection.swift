import SwiftUI

struct DashboardMarketsSection: View {
    let snapshot: MarketRefreshSnapshot
    let marketTickerSettings: MarketTickerSetting
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NumberedSectionHeader(number: 4, title: "Key Markets")

            VStack(spacing: 12) {
                ForEach(Array(marketTickerSettings.symbols.enumerated()), id: \.offset) { _, symbol in
                    marketCard(symbol: symbol)
                }
            }
        }
    }

    private func marketCard(symbol: String) -> MarketDashboardCard {
        let normalized = normalizedDashboardSymbol(symbol)
        let quote = quote(for: normalized)

        return MarketDashboardCard(
            symbol: normalized,
            title: marketTitle(symbol: normalized, quote: quote),
            quote: quote,
            history: historyValues(for: normalized),
            isLoading: isLoading
        )
    }

    private func quote(for symbol: String) -> CachedMarketQuote? {
        snapshot.quotesBySymbol[normalizedDashboardSymbol(symbol)]
    }

    private func historyValues(for symbol: String) -> [Double] {
        if let prices = snapshot.historiesBySymbol[normalizedDashboardSymbol(symbol)]?.data.prices.suffix(28), prices.count > 2 {
            return prices.map(\.close)
        }

        return isLoading ? [] : fallbackSparklineValues(for: symbol)
    }
}
