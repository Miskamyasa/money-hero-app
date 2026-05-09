import SwiftUI

struct MarketIcon: View {
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
