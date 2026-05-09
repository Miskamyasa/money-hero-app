import SwiftUI

struct DashboardCurrenciesSection: View {
    let snapshot: MarketRefreshSnapshot
    let currencySettings: CurrencyWidgetSetting
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NumberedSectionHeader(number: 1, title: "Currencies")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(currencySettings.symbols.enumerated()), id: \.offset) { _, symbol in
                        CurrencyDashboardCard(
                            symbol: symbol,
                            quote: quote(for: symbol),
                            isLoading: isLoading
                        )
                    }
                }
                .padding(.horizontal, 1)
                .padding(.bottom, 4)
            }
            .scrollClipDisabled()
        }
    }

    private func quote(for symbol: String) -> CachedMarketQuote? {
        snapshot.quotesBySymbol[normalizedDashboardSymbol(symbol)]
    }
}
