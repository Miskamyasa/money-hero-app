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
