import Combine
import Foundation

@MainActor
final class DashboardState: ObservableObject {
    @Published var snapshot: MarketRefreshSnapshot
    @Published var isAppOpenLoading: Bool
    @Published var isInitialLoading: Bool
    @Published var isRefreshing: Bool
    @Published var refreshErrorMessage: String?

    let currencySettings: CurrencyWidgetSetting
    let marketTickerSettings: MarketTickerSetting

    private let coordinator: MarketRefreshCoordinator?
    private let holdings: [Holding]
    private var snapshotsTask: Task<Void, Never>?
    private var awaitingRefreshProgress: Bool
    private var hasStartedAppOpenRefresh: Bool

    init(
        coordinator: MarketRefreshCoordinator?,
        holdings: [Holding] = [],
        currencySettings: CurrencyWidgetSetting = .default,
        marketTickerSettings: MarketTickerSetting = .default,
        startupErrorMessage: String? = nil
    ) {
        self.coordinator = coordinator
        self.holdings = holdings
        self.currencySettings = currencySettings
        self.marketTickerSettings = marketTickerSettings
        self.refreshErrorMessage = startupErrorMessage
        self.snapshot = .empty
        self.isAppOpenLoading = true
        self.isInitialLoading = false
        self.isRefreshing = false
        self.awaitingRefreshProgress = false
        self.hasStartedAppOpenRefresh = false

        observeSnapshots()
    }

    deinit {
        snapshotsTask?.cancel()
    }

    static func live() -> DashboardState {
        do {
            let cacheStore = try LocalJSONCacheStore()
            return DashboardState(coordinator: MarketRefreshCoordinator(cacheStore: cacheStore))
        } catch {
            return DashboardState(
                coordinator: nil,
                startupErrorMessage: "Cache unavailable: \(String(describing: error))"
            )
        }
    }

    var hasHoldings: Bool {
        holdings.contains { !$0.isHidden }
    }

    func refreshOnAppOpen() async {
        guard !hasStartedAppOpenRefresh else {
            return
        }

        hasStartedAppOpenRefresh = true
        isAppOpenLoading = true
        guard shouldStartRefresh else {
            isAppOpenLoading = false
            return
        }

        isInitialLoading = !hasAnyMarketData
        await refresh { coordinator in
            await coordinator.refreshOnAppOpen(
                holdings: holdings,
                currencySettings: currencySettings,
                marketTickerSettings: marketTickerSettings
            )
        }
    }

    func refreshOnPullToRefresh() async {
        guard shouldStartRefresh else {
            return
        }

        await refresh { coordinator in
            await coordinator.refreshOnPullToRefresh(
                holdings: holdings,
                currencySettings: currencySettings,
                marketTickerSettings: marketTickerSettings
            )
        }
    }

    private var shouldStartRefresh: Bool {
        !isRefreshing && coordinator != nil
    }

    private var hasAnyMarketData: Bool {
        !snapshot.quotesBySymbol.isEmpty || !snapshot.historiesBySymbol.isEmpty || snapshot.lastUpdatedAtMs != nil
    }

    private func refresh(_ operation: (MarketRefreshCoordinator) async -> Void) async {
        guard let coordinator else {
            refreshErrorMessage = refreshErrorMessage ?? "Market data is unavailable."
            isInitialLoading = false
            isRefreshing = false
            isAppOpenLoading = false
            return
        }

        isRefreshing = true
        awaitingRefreshProgress = true
        refreshErrorMessage = nil
        await operation(coordinator)

        snapshot = await coordinator.snapshot()
        awaitingRefreshProgress = false
        applyProgress(snapshot.progress)
    }

    private func observeSnapshots() {
        guard let coordinator else {
            return
        }

        snapshotsTask = Task { [weak self, coordinator] in
            for await snapshot in coordinator.snapshots() {
                guard let self else {
                    return
                }

                self.snapshot = snapshot
                self.refreshErrorMessage = Self.errorMessage(from: snapshot)
                self.applyProgress(snapshot.progress)
            }
        }
    }

    private func applyProgress(_ progress: MarketFetchQueueProgress) {
        if progress.isActive {
            awaitingRefreshProgress = false
            isRefreshing = true
            return
        }

        if progress.totalCount > 0 {
            awaitingRefreshProgress = false
            isRefreshing = false
            isInitialLoading = false
            isAppOpenLoading = false
            return
        }

        guard !awaitingRefreshProgress else {
            return
        }

        isRefreshing = false
        isInitialLoading = false
        isAppOpenLoading = false
    }

    private static func errorMessage(from snapshot: MarketRefreshSnapshot) -> String? {
        let quoteError = snapshot.quotesBySymbol.values.first { $0.metadata.status == .error }?.metadata.error
        let historyError = snapshot.historiesBySymbol.values.first { $0.metadata.status == .error }?.metadata.error
        return snapshot.refreshErrorMessage ?? quoteError ?? historyError
    }
}
