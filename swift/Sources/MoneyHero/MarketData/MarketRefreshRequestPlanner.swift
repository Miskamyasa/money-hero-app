enum MarketRefreshTrackedSymbolKind: Sendable {
    case market
    case currency
}

struct MarketRefreshTrackedSymbolRequest: Sendable {
    let symbol: String
    let kind: MarketRefreshTrackedSymbolKind
}

enum MarketRefreshRequestPlanner {
    static func trackedSymbols(
        activeWidgets: [DashboardWidget],
        holdings: [Holding],
        currencySettings: CurrencyWidgetSetting,
        marketTickerSettings: MarketTickerSetting
    ) -> [String] {
        trackedRequests(
            activeWidgets: activeWidgets,
            holdings: holdings,
            currencySettings: currencySettings,
            marketTickerSettings: marketTickerSettings
        )
        .map(\.symbol)
    }

    static func trackedRequests(
        activeWidgets: [DashboardWidget],
        holdings: [Holding],
        currencySettings: CurrencyWidgetSetting,
        marketTickerSettings: MarketTickerSetting
    ) -> [MarketRefreshTrackedSymbolRequest] {
        var requests: [MarketRefreshTrackedSymbolRequest] = []

        if activeWidgets.contains(.keyMarkets) {
            requests.append(
                contentsOf: marketTickerSettings.symbols.compactMap { symbol in
                    guard let normalized = try? normalizeSymbol(symbol) else {
                        return nil
                    }
                    return MarketRefreshTrackedSymbolRequest(symbol: normalized, kind: .market)
                }
            )
        }

        if activeWidgets.contains(.currencies) {
            requests.append(
                contentsOf: currencySettings.symbols.compactMap { symbol in
                    guard let normalized = normalizedCurrencySymbol(symbol) else {
                        return nil
                    }
                    return MarketRefreshTrackedSymbolRequest(symbol: normalized, kind: .currency)
                }
            )
        }

        for holding in holdings {
            guard !holding.isHidden else {
                continue
            }
            if let normalized = try? normalizeSymbol(holding.symbol) {
                requests.append(MarketRefreshTrackedSymbolRequest(symbol: normalized, kind: .market))
            }
        }

        var seen: Set<String> = []
        return requests.filter { seen.insert($0.symbol).inserted }
    }

    private static func normalizedCurrencySymbol(_ symbol: String) -> String? {
        try? normalizeCurrencyCode(symbol)
    }
}
