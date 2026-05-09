import SwiftUI

@MainActor
struct RootView: View {
    @StateObject private var dashboardState: DashboardState
    @State private var selectedTab: AppTab = .dashboard

    init() {
        _dashboardState = StateObject(wrappedValue: DashboardState.live())
    }

    init(dashboardState: DashboardState) {
        _dashboardState = StateObject(wrappedValue: dashboardState)
    }

    var body: some View {
        Group {
            if dashboardState.isAppOpenLoading {
                AppLoadingView(errorMessage: dashboardState.refreshErrorMessage)
            } else {
                appContent
            }
        }
        .task {
            await dashboardState.refreshOnAppOpen()
        }
    }

    private var appContent: some View {
        TabView(selection: $selectedTab) {
            DashboardView(state: dashboardState)
                .tabItem {
                    Label(AppTab.dashboard.title, systemImage: AppTab.dashboard.systemImage)
                }
                .tag(AppTab.dashboard)

            NavigationStack {
                PortfolioPlaceholderView()
                    .navigationTitle(AppTab.portfolio.title)
            }
            .tabItem {
                Label(AppTab.portfolio.title, systemImage: AppTab.portfolio.systemImage)
            }
            .tag(AppTab.portfolio)

            NavigationStack {
                SettingsPlaceholderView()
                    .navigationTitle(AppTab.settings.title)
            }
            .tabItem {
                Label(AppTab.settings.title, systemImage: AppTab.settings.systemImage)
            }
            .tag(AppTab.settings)
        }
    }
}

private struct AppLoadingView: View {
    let errorMessage: String?

    var body: some View {
        ZStack {
            DashboardArcBackground()

            VStack(spacing: 18) {
                MoneyHeroLogoMark()
                    .frame(width: 58, height: 58)

                ProgressView()
                    .controlSize(.large)

                Text(errorMessage ?? "Loading market data")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(errorMessage == nil ? DashboardPalette.muted : DashboardPalette.negative)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 28)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DashboardPalette.page)
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
