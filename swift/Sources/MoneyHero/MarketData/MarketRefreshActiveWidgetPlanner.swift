enum MarketRefreshActiveWidgetPlanner {
    static func activeWidgets(from settings: [WidgetSetting], hasHoldings: Bool) -> [DashboardWidget] {
        settings
            .filter { !$0.isHidden }
            .sorted { $0.order < $1.order }
            .map(\.widget)
            .filter { hasHoldings || !$0.requiresHoldings }
    }
}
