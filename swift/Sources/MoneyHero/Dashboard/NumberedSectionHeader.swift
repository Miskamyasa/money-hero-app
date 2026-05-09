import SwiftUI

struct NumberedSectionHeader: View {
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
