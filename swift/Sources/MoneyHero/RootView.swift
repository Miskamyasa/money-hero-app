import SwiftUI

enum AppTab: Hashable {
    case dashboard
    case portfolio
    case settings

    var title: String {
        switch self {
        case .dashboard:
            return "Dashboard"
        case .portfolio:
            return "Portfolio"
        case .settings:
            return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            return "house.fill"
        case .portfolio:
            return "chart.pie.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

struct RootView: View {
    @State private var selectedTab: AppTab = .dashboard
    @State private var coordinator: MarketRefreshCoordinator?
    @State private var holdings: [Holding] = []
    @State private var currencySettings = CurrencyWidgetSetting.default
    @State private var marketTickerSettings = MarketTickerSetting.default
    @State private var snapshot = MarketRefreshSnapshot(
        quotesBySymbol: [:],
        historiesBySymbol: [:],
        progress: MarketFetchQueueProgress(totalCount: 0, completedCount: 0, running: false, currentLabel: nil),
        lastUpdatedAtMs: nil
    )

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(
                snapshot: snapshot,
                currencySettings: currencySettings,
                marketTickerSettings: marketTickerSettings,
                refresh: refreshPullToRefresh
            )
            .task {
                await loadDashboard()
            }
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

        await coordinator.refreshOnAppOpen(
            holdings: holdings,
            currencySettings: currencySettings,
            marketTickerSettings: marketTickerSettings
        )
        snapshot = await coordinator.snapshot()
    }

    private func refreshPullToRefresh() async {
        guard let coordinator else {
            return
        }

        await coordinator.refreshOnPullToRefresh(
            holdings: holdings,
            currencySettings: currencySettings,
            marketTickerSettings: marketTickerSettings
        )
        snapshot = await coordinator.snapshot()
    }
}

struct DashboardView: View {
    let snapshot: MarketRefreshSnapshot
    let currencySettings: CurrencyWidgetSetting
    let marketTickerSettings: MarketTickerSetting
    let refresh: () async -> Void

    var body: some View {
        ZStack {
            DashboardArcBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    dashboardHeader
                    currenciesSection
                    totalBalanceSection
                    expectedBalanceSection
                    keyMarketsSection
                    refreshStatusSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 52)
                .padding(.bottom, 26)
            }
            .refreshable {
                await refresh()
            }
        }
        .background(DashboardPalette.page)
    }

    private var dashboardHeader: some View {
        HStack(spacing: 14) {
            MoneyHeroLogoMark()
                .frame(width: 42, height: 42)

            Text("MONEY HERO")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(DashboardPalette.ink)
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            Spacer(minLength: 12)

            Button {
                Task {
                    await refresh()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(DashboardPalette.action)
                    .frame(width: 56, height: 56)
                    .background(DashboardPalette.actionFill, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    private var currenciesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NumberedSectionHeader(number: 1, title: "Currencies")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(currencySettings.symbols.enumerated()), id: \.offset) { _, symbol in
                        CurrencyDashboardCard(symbol: symbol, quote: quote(for: symbol))
                    }
                }
                .padding(.horizontal, 1)
                .padding(.bottom, 4)
            }
            .scrollClipDisabled()
        }
    }

    private var totalBalanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NumberedSectionHeader(number: 2, title: "Total Balance")

            VStack(spacing: 12) {
                Text("ILS --")
                    .font(.system(size: 39, weight: .heavy, design: .rounded))
                    .foregroundStyle(DashboardPalette.deepInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                HStack(spacing: 12) {
                    Text("+0.00%")
                        .foregroundStyle(DashboardPalette.positive)
                        .fontWeight(.bold)
                    Text("in 1 Year")
                        .foregroundStyle(DashboardPalette.muted)
                }
                .font(.system(size: 17, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .dashboardCard()
        }
    }

    private var expectedBalanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NumberedSectionHeader(number: 3, title: "Expected Balance")

            HStack(spacing: 12) {
                ProjectionCard(title: "In 1 Year", amount: "ILS --", change: "+0.00%")
                ProjectionCard(title: "In 5 Years", amount: "ILS --", change: "+0.00%")
            }
        }
    }

    private var keyMarketsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NumberedSectionHeader(number: 4, title: "Key Markets")

            VStack(spacing: 12) {
                ForEach(Array(marketTickerSettings.symbols.enumerated()), id: \.offset) { _, symbol in
                    let normalized = normalizedSymbol(symbol)
                    MarketDashboardCard(
                        symbol: normalized,
                        title: marketTitle(for: normalized),
                        quote: quote(for: normalized),
                        history: historyValues(for: normalized)
                    )
                }
            }
        }
    }

    private var refreshStatusSection: some View {
        HStack(spacing: 8) {
            Image(systemName: snapshot.progress.running ? "arrow.clockwise" : "clock")
                .foregroundStyle(DashboardPalette.action)

            if snapshot.progress.running {
                Text(snapshot.progress.currentLabel ?? "Refreshing market data")
            } else {
                Text("Last updated: \(lastUpdatedText)")
            }

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

    private var lastUpdatedText: String {
        guard let timestampMs = snapshot.lastUpdatedAtMs else {
            return "No market data yet"
        }

        let date = Date(timeIntervalSince1970: TimeInterval(timestampMs) / 1000)
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }

    private func quote(for symbol: String) -> CachedMarketQuote? {
        snapshot.quotesBySymbol[normalizedSymbol(symbol)]
    }

    private func historyValues(for symbol: String) -> [Double] {
        if let prices = snapshot.historiesBySymbol[normalizedSymbol(symbol)]?.data.prices.suffix(28), prices.count > 2 {
            return prices.map(\.close)
        }

        return fallbackSparklineValues(for: symbol)
    }

    private func marketTitle(for symbol: String) -> String {
        let normalized = normalizedSymbol(symbol)

        if normalized == "GC=F" {
            return "Gold"
        }
        if normalized == "^GSPC" {
            return "S&P 500"
        }

        return quote(for: normalized)?.data.name ?? normalized
    }

    private func normalizedSymbol(_ symbol: String) -> String {
        (try? normalizeSymbol(symbol)) ?? symbol
    }
}

private struct NumberedSectionHeader: View {
    let number: Int
    let title: String

    var body: some View {
        Text("\(number). \(title.uppercased())")
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundStyle(DashboardPalette.section)
            .tracking(1.2)
            .padding(.leading, 14)
    }
}

private struct CurrencyDashboardCard: View {
    let symbol: String
    let quote: CachedMarketQuote?

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
        (try? normalizeSymbol(symbol)) ?? symbol
    }

    private var valueText: String {
        if normalizedSymbol == "USD" {
            return "1.00"
        }

        guard let quote, quote.metadata.status != .error else {
            return "--"
        }

        return String(format: "%.4f", quote.data.price)
    }

    private var detailText: String {
        if normalizedSymbol == "USD" {
            return "DXY 97.92"
        }

        guard let quote else {
            return "No data"
        }

        if quote.metadata.status == .error {
            return "Error"
        }

        return formatPercent(quote.data.changePercent)
    }

    private var detailColor: Color {
        if normalizedSymbol == "USD" {
            return DashboardPalette.muted
        }

        guard let quote, quote.metadata.status != .error else {
            return DashboardPalette.muted
        }

        return quote.data.changePercent >= 0 ? DashboardPalette.positive : DashboardPalette.negative
    }
}

private struct ProjectionCard: View {
    let title: String
    let amount: String
    let change: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(DashboardPalette.positive.opacity(0.14))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(DashboardPalette.positive)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(DashboardPalette.deepInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("Conservative")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DashboardPalette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }

            VStack(spacing: 10) {
                Text(amount)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(DashboardPalette.deepInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                Text(change)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(DashboardPalette.positive)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 154, alignment: .topLeading)
        .dashboardCard()
    }
}

private struct MarketDashboardCard: View {
    let symbol: String
    let title: String
    let quote: CachedMarketQuote?
    let history: [Double]

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                MarketIcon(symbol: symbol)
                    .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 5) {
                    Text("\(title) (\(symbol))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(DashboardPalette.deepInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(priceText)
                        .font(.system(size: 22, weight: .regular, design: .rounded).monospacedDigit())
                        .foregroundStyle(DashboardPalette.deepInk)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                SparklineView(values: history, positive: isPositive)
                    .frame(width: 116, height: 42)

                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DashboardPalette.muted)
            }

            Divider()

            HStack {
                PeriodChangeLabel(label: "1M", value: quote?.data.change1m ?? quote?.data.changePercent)
                Spacer()
                Divider().frame(height: 22)
                Spacer()
                PeriodChangeLabel(label: "6M", value: quote?.data.change6m)
                Spacer()
                Divider().frame(height: 22)
                Spacer()
                PeriodChangeLabel(label: "2Y", value: quote?.data.change2y)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(18)
        .dashboardCard()
    }

    private var priceText: String {
        guard let quote, quote.metadata.status != .error else {
            return "--"
        }

        return formatPrice(quote.data.price, currency: quote.data.currency)
    }

    private var isPositive: Bool {
        (quote?.data.changePercent ?? fallbackChange(for: symbol)) >= 0
    }
}

private struct PeriodChangeLabel: View {
    let label: String
    let value: Double?

    var body: some View {
        HStack(spacing: 7) {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DashboardPalette.deepInk)

            Text(value.map(formatPercent) ?? "--")
                .font(.system(size: 16, weight: .semibold).monospacedDigit())
                .foregroundStyle((value ?? 0) >= 0 ? DashboardPalette.positive : DashboardPalette.negative)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
}

private struct MarketIcon: View {
    let symbol: String

    var body: some View {
        Circle()
            .fill(iconFill)
            .overlay {
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
    }

    private var iconFill: LinearGradient {
        LinearGradient(colors: iconColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var iconColors: [Color] {
        switch symbol {
        case "GC=F":
            return [Color(red: 1.0, green: 0.77, blue: 0.05), Color(red: 0.92, green: 0.59, blue: 0.0)]
        case "^GSPC":
            return [Color(red: 0.21, green: 0.47, blue: 0.98), Color(red: 0.39, green: 0.59, blue: 1.0)]
        case "^TA125.TA":
            return [Color(red: 0.45, green: 0.21, blue: 0.94), Color(red: 0.55, green: 0.28, blue: 1.0)]
        default:
            return [Color(red: 0.12, green: 0.54, blue: 0.94), Color(red: 0.26, green: 0.72, blue: 0.96)]
        }
    }

    private var iconName: String {
        switch symbol {
        case "GC=F":
            return "shippingbox.fill"
        case "^GSPC":
            return "s.circle.fill"
        case "^TA125.TA":
            return "staroflife.fill"
        default:
            return "dollarsign"
        }
    }
}

private struct SparklineView: View {
    let values: [Double]
    let positive: Bool

    var body: some View {
        SparklineShape(values: values)
            .stroke(positive ? DashboardPalette.positive : DashboardPalette.negative, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
            .background {
                SparklineShape(values: values)
                    .fill(
                        LinearGradient(
                            colors: [
                                (positive ? DashboardPalette.positive : DashboardPalette.negative).opacity(0.18),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
    }
}

private struct SparklineShape: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        guard values.count > 1, let minValue = values.min(), let maxValue = values.max() else {
            return Path()
        }

        let spread = max(maxValue - minValue, 0.0001)
        var path = Path()

        for index in values.indices {
            let progress = CGFloat(index) / CGFloat(values.count - 1)
            let normalized = CGFloat((values[index] - minValue) / spread)
            let point = CGPoint(
                x: rect.minX + progress * rect.width,
                y: rect.maxY - normalized * rect.height
            )

            if index == values.startIndex {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        return path
    }
}

private struct MoneyHeroLogoMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(DashboardPalette.ink.opacity(0.18), lineWidth: 1)

            HStack(spacing: 3) {
                logoBar(height: 20, color: DashboardPalette.ink)
                logoBar(height: 29, color: Color(red: 0.12, green: 0.64, blue: 0.55))
                logoBar(height: 36, color: Color(red: 0.18, green: 0.78, blue: 0.86))
                logoBar(height: 25, color: DashboardPalette.ink)
            }
            .rotationEffect(.degrees(-28))
        }
    }

    private func logoBar(height: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color)
            .frame(width: 6, height: height)
    }
}

private struct DashboardArcBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                DashboardPalette.page

                ForEach(0..<8, id: \.self) { index in
                    ArcShape(offset: CGFloat(index) * 43)
                        .stroke(DashboardPalette.action.opacity(index < 3 ? 0.18 : 0.10), lineWidth: index < 2 ? 2.3 : 1.5)
                        .frame(width: proxy.size.width * 1.5, height: 360 + CGFloat(index * 48))
                        .offset(x: -proxy.size.width * 0.18, y: 74 + CGFloat(index * 28))
                }
            }
            .ignoresSafeArea()
        }
    }
}

private struct ArcShape: Shape {
    let offset: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX - 40, y: rect.midY + offset))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX + 60, y: rect.midY + 32 + offset * 0.18),
            control: CGPoint(x: rect.midX, y: rect.minY - 110 + offset * 0.18)
        )
        return path
    }
}

private struct PortfolioPlaceholderView: View {
    var body: some View {
        Color.clear
    }
}

private struct SettingsPlaceholderView: View {
    var body: some View {
        Color.clear
    }
}

private enum DashboardPalette {
    static let page = Color(red: 0.985, green: 0.99, blue: 0.995)
    static let ink = Color(red: 0.13, green: 0.18, blue: 0.25)
    static let deepInk = Color(red: 0.02, green: 0.05, blue: 0.10)
    static let muted = Color(red: 0.47, green: 0.52, blue: 0.60)
    static let section = Color(red: 0.39, green: 0.44, blue: 0.53)
    static let border = Color(red: 0.84, green: 0.87, blue: 0.91)
    static let action = Color(red: 0.03, green: 0.44, blue: 0.91)
    static let actionFill = Color(red: 0.87, green: 0.94, blue: 1.0)
    static let positive = Color(red: 0.0, green: 0.70, blue: 0.39)
    static let negative = Color(red: 1.0, green: 0.18, blue: 0.22)
}

private extension View {
    func dashboardCard() -> some View {
        self
            .background(.white.opacity(0.93), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(DashboardPalette.border, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.045), radius: 12, x: 0, y: 6)
    }
}

private func formatPercent(_ value: Double) -> String {
    let sign = value >= 0 ? "+" : ""
    return "\(sign)\(String(format: "%.2f", value))%"
}

private func formatPrice(_ value: Double, currency: String) -> String {
    if currency == "USD" {
        return "$\(String(format: "%.2f", value))"
    }

    return "\(currency) \(String(format: "%.2f", value))"
}

private func fallbackChange(for symbol: String) -> Double {
    switch symbol {
    case "GC=F", "^GSPC", "^TA125.TA":
        return 1
    default:
        return -1
    }
}

private func fallbackSparklineValues(for symbol: String) -> [Double] {
    switch symbol {
    case "GC=F":
        return [11, 13, 14, 13, 16, 15, 18, 17, 16, 17, 18, 17, 19, 18, 17]
    case "^GSPC":
        return [10, 11, 13, 12, 14, 15, 17, 15, 16, 15, 16, 17, 16, 17, 18]
    case "^TA125.TA":
        return [9, 10, 11, 10, 13, 14, 16, 15, 17, 20, 18, 16, 17, 16, 19]
    default:
        return [18, 17, 16, 17, 15, 14, 16, 13, 12, 12, 11, 10, 11, 9, 8]
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
