import SwiftUI

struct DashboardView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        ZStack {
            DashboardArcBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    DashboardHeaderView(
                        isRefreshing: state.isRefreshing,
                        refresh: refresh
                    )
                    DashboardCurrenciesSection(
                        snapshot: state.snapshot,
                        currencySettings: state.currencySettings,
                        isLoading: state.isInitialLoading || state.isRefreshing
                    )
                    DashboardTotalBalanceSection(
                        hasHoldings: state.hasHoldings,
                        isLoading: state.isInitialLoading
                    )
                    DashboardExpectedBalanceSection(
                        hasHoldings: state.hasHoldings,
                        isLoading: state.isInitialLoading
                    )
                    DashboardMarketsSection(
                        snapshot: state.snapshot,
                        marketTickerSettings: state.marketTickerSettings,
                        isLoading: state.isInitialLoading || state.isRefreshing
                    )
                    DashboardRefreshStatusView(
                        snapshot: state.snapshot,
                        isInitialLoading: state.isInitialLoading,
                        isRefreshing: state.isRefreshing,
                        errorMessage: state.refreshErrorMessage
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 52)
                .padding(.bottom, 26)
            }
            .refreshable {
                await state.refreshOnPullToRefresh()
            }
        }
        .background(DashboardPalette.page)
    }

    private func refresh() {
        Task {
            await state.refreshOnPullToRefresh()
        }
    }
}
