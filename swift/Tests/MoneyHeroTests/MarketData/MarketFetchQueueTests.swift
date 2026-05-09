import Testing
@testable import MoneyHero

@Test func fetchQueueDeduplicatesByCacheKey() async throws {
    let queue = MarketFetchQueue()
    let counter = InvocationCounter()

    _ = await queue.enqueue(
        task: MarketFetchQueueTask(
            cacheKey: "quote:AAPL",
            label: "first"
        ) {
            await counter.increment()
        }
    )

    _ = await queue.enqueue(
        task: MarketFetchQueueTask(
            cacheKey: " quote:AAPL ",
            label: "duplicate"
        ) {
            await counter.increment()
        }
    )

    _ = await queue.enqueue(
        task: MarketFetchQueueTask(
            cacheKey: "history:AAPL",
            label: "history"
        ) {
            await counter.increment()
        }
    )

    try await Task.sleep(for: .seconds(3))

    let invocations = await counter.value
    #expect(invocations == 2)
    let progress = await queue.progress
    #expect(progress.running == false)
    #expect(progress.completedCount == 2)
}
