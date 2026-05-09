import SwiftUI

enum DashboardPalette {
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

extension View {
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
