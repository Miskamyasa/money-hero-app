import SwiftUI

struct DashboardRefreshStatusView: View {
    let snapshot: MarketRefreshSnapshot
    let isInitialLoading: Bool
    let isRefreshing: Bool
    let errorMessage: String?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)

            Text(statusText)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Spacer(minLength: 8)

            if snapshot.progress.totalCount > 0 {
                Text("\(snapshot.progress.completedCount)/\(snapshot.progress.totalCount)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(DashboardPalette.muted)
            }
        }
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(DashboardPalette.muted)
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    private var statusIcon: String {
        if errorMessage != nil {
            return "exclamationmark.triangle.fill"
        }
        return isInitialLoading || isRefreshing || snapshot.progress.isActive ? "arrow.clockwise" : "clock"
    }

    private var statusColor: Color {
        errorMessage == nil ? DashboardPalette.action : DashboardPalette.negative
    }

    private var statusText: String {
        if let errorMessage {
            return "Refresh issue: \(errorMessage)"
        }
        if isInitialLoading {
            return "Loading market data"
        }
        if snapshot.progress.isActive || isRefreshing {
            return snapshot.progress.currentLabel ?? "Refreshing market data"
        }

        return "Last updated: \(lastUpdatedText(timestampMs: snapshot.lastUpdatedAtMs))"
    }
}
