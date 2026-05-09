import Testing
@testable import MoneyHero

@MainActor
@Test func rootViewCanInitialize() {
    _ = RootView()
}
