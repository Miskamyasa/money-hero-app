import SwiftUI

struct DashboardHeaderView: View {
    let isRefreshing: Bool
    let refresh: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            MoneyHeroLogoMark()
                .frame(width: 42, height: 42)

            Text("MONEY HERO")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(DashboardPalette.ink)
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            Spacer(minLength: 12)

            RefreshButton(isRefreshing: isRefreshing, refresh: refresh)
        }
    }
}

private struct RefreshButton: View {
    let isRefreshing: Bool
    let refresh: () -> Void

    var body: some View {
        Button(action: refresh) {
            ZStack {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 24, weight: .semibold))
                    .opacity(isRefreshing ? 0 : 1)

                if isRefreshing {
                    ProgressView()
                        .controlSize(.regular)
                }
            }
            .foregroundStyle(DashboardPalette.action)
            .frame(width: 56, height: 56)
            .background(DashboardPalette.actionFill, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(isRefreshing)
        .accessibilityLabel(isRefreshing ? "Refreshing" : "Refresh")
    }
}
