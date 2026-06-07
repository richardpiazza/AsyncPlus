@testable import AsyncPlus
import Mutex
import Testing

struct PassthroughSubjectTests {

    /// Verify that a single subscriber task behaves as expected.
    ///
    /// This also validates the `onNoSubscribers` implementation.
    @Test func singleSubscriber() async throws {
        let noSubscribersIndicated = Mutex(false)

        let subject: PassthroughAsyncSubject<Int> = PassthroughAsyncSubject {
            noSubscribersIndicated.withLock {
                $0 = true
            }
        }

        let task1 = Task {
            var output: [Int] = []

            for await element in subject.sink() {
                output.append(element)
            }

            return output
        }

        try await Task.sleep(for: .seconds(0.5))
        subject.yield(1)
        subject.yield(2)
        subject.yield(3)
        subject.finish()
        let subscriberCount = subject.subscribers

        let values = await task1.value
        #expect(values.count == 3)
        #expect(values == [1, 2, 3])
        #expect(subscriberCount == 0)
        #expect(noSubscribersIndicated.withLock { $0 })
    }

    /// Verify that multiple subscriber tasks receive the same output.
    @Test func multipleSubscribers() async throws {
        let subject = PassthroughAsyncSubject<Int>()

        let task1 = Task {
            var output: [Int] = []

            for await element in subject.sink() {
                output.append(element)
            }

            return output
        }

        try await Task.sleep(for: .seconds(0.5))
        subject.yield(1)

        let task2 = Task {
            var output: [Int] = []

            for await element in subject.sink() {
                output.append(element)
            }

            return output
        }

        try await Task.sleep(for: .seconds(0.5))
        subject.yield(2)
        subject.yield(3)
        subject.finish()
        let subscriberCount = subject.subscribers

        let values1 = await task1.value
        #expect(values1.count == 3)
        #expect(values1 == [1, 2, 3])

        let values2 = await task2.value
        #expect(values2.count == 2)
        #expect(values2 == [2, 3])

        #expect(subscriberCount == 0)
    }

    /// Verify a canceled subscriber task is removed from the subject.
    @Test func canceledTaskRemovesSubscriber() async throws {
        let subject = PassthroughAsyncSubject<Int>()

        let task1 = Task {
            var output: [Int] = []

            for await element in subject.sink() {
                output.append(element)
            }

            return output
        }

        try await Task.sleep(for: .seconds(0.5))
        subject.yield(1)
        subject.yield(2)

        task1.cancel()

        try await Task.sleep(for: .seconds(0.5))
        let subscriberCount = subject.subscribers
        #expect(subscriberCount == 0)

        subject.yield(3)
        subject.finish()

        let values = await task1.value
        #expect(values.count == 2)
        #expect(values == [1, 2])
    }
}
