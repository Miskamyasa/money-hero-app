import SwiftUI

struct RootView: View {
    @State private var coordinator: MarketRefreshCoordinator?
    @State private var holdings: [Holding] = []
    @State private var snapshot = MarketRefreshSnapshot(
        quotesBySymbol: [:],
        historiesBySymbol: [:],
        progress: MarketFetchQueueProgress(totalCount: 0, completedCount: 0, running: false, currentLabel: nil),
        lastUpdatedAtMs: nil
    )

    var body: some View {
        NavigationStack {
            List {
                Section("Current Balance") {
                    if hasHoldings {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Portfolio")
                                .font(.headline)
                            Text("--")
                                .font(.title3)
                            Text("Expected balance placeholders are shown when holdings exist")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Currencies") {
                    currencyRow(symbol: "USD", displayName: "US Dollar", fixedPrice: 1)
                    currencyRow(symbol: "EUR", displayName: "Euro")
                    currencyRow(symbol: "GBP", displayName: "British Pound")
                }

                Section("Markets") {
                    marketRow(symbol: YahooFinanceClient.goldSymbol, title: "Gold")
                    marketRow(symbol: YahooFinanceClient.sp500Symbol, title: "S&P 500")
                }

                if hasHoldings {
                    Section("Expected Balance") {
                        placeholderProjection(title: "1 Year Projection")
                        placeholderProjection(title: "5 Year Projection")
                    }
                }

                Section("Fetch Progress") {
                    let progress = snapshot.progress
                    Text("\(progress.completedCount)/\(progress.totalCount)")
                        .font(.body.monospacedDigit())

                    if progress.running {
                        Text(progress.currentLabel ?? "Refreshing market data")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Idle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Last Updated") {
                    Text(lastUpdatedText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await refreshPullToRefresh()
            }
            .task {
                await loadDashboard()
            }
        }
    }

    private var hasHoldings: Bool {
        !holdings.isEmpty
    }

    private var lastUpdatedText: String {
        guard let timestampMs = snapshot.lastUpdatedAtMs else {
            return "No market data yet"
        }

        let date = Date(timeIntervalSince1970: TimeInterval(timestampMs) / 1000)
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }

    private func marketRow(symbol: String, title: String) -> some View {
        let cached = snapshot.quotesBySymbol[symbol]

        return VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.body)

            if let cached {
                if cached.metadata.status == .error {
                    Text(cached.metadata.error ?? "Data unavailable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(formatPrice(cached.data.price, currency: cached.data.currency))
                        .font(.subheadline)
                    Text(formatPercent(cached.data.changePercent))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func currencyRow(symbol: String, displayName: String, fixedPrice: Double? = nil) -> some View {
        let cached = snapshot.quotesBySymbol[symbol]

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(symbol)
                    .font(.body)
                Text(displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let fixedPrice {
                Text(String(format: "%.2f", fixedPrice))
                    .font(.subheadline.monospacedDigit())
            } else if let cached {
                if cached.metadata.status == .error {
                    Text("Error")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(String(format: "%.4f", cached.data.price))
                        .font(.subheadline.monospacedDigit())
                }
            } else {
                Text("--")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func placeholderProjection(title: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.body)
            Text("--")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func formatPrice(_ price: Double, currency: String) -> String {
        "\(String(format: "%.2f", price)) \(currency)"
    }

    private func formatPercent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", value))%"
    }

    private func loadDashboard() async {
        if coordinator == nil {
            coordinator = try? MarketRefreshCoordinator(cacheStore: LocalJSONCacheStore())
        }

        await refreshOnAppOpen()
    }

    private func refreshOnAppOpen() async {
        guard let coordinator else {
            return
        }

        await coordinator.refreshOnAppOpen(holdings: holdings)
        snapshot = await coordinator.snapshot()
    }

    private func refreshPullToRefresh() async {
        guard let coordinator else {
            return
        }

        await coordinator.refreshOnPullToRefresh(holdings: holdings)
        snapshot = await coordinator.snapshot()
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
