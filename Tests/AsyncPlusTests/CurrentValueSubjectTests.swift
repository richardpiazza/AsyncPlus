@testable import AsyncPlus
import Mutex
import Testing

struct CurrentValueSubjectTests {

    /// Verify that a _new_ subscriber receives the _current_ value from the subject.
    ///
    /// This also validates that canceling a subscription `Task` will also remove the subscriber.
    @Test func singleSubscriber() async throws {
        let subject = CurrentValueAsyncSubject(0)
        var value = subject.value
        #expect(value == 0)

        let subscription1 = Task {
            var output: [Int] = []

            for await element in subject.sink() {
                output.append(element)
            }

            return output
        }

        try await Task.sleep(for: .seconds(0.1))
        subject.yield(1)
        value = subject.value
        #expect(value == 1)

        var subscriberCount = subject.subscribers
        #expect(subscriberCount == 1)

        subscription1.cancel()
        try await Task.sleep(for: .seconds(0.1))

        subscriberCount = subject.subscribers
        #expect(subscriberCount == 0)

        let values = await subscription1.value
        #expect(values == [0, 1])
    }

    /// Verify that a _new_ subscriber receives the _current_ and future values from the subject.
    @Test func multipleSubscribers() async throws {
        let subject = CurrentValueAsyncSubject(0)

        let subscription1 = Task {
            var output: [Int] = []

            for await element in subject.sink() {
                output.append(element)
            }

            return output
        }

        try await Task.sleep(for: .seconds(0.1))
        subject.yield(1)

        subscription1.cancel()
        try await Task.sleep(for: .seconds(0.1))

        let subscription2 = Task {
            var output: [Int] = []

            for await element in subject.sink() {
                output.append(element)
            }

            return output
        }

        try await Task.sleep(for: .seconds(0.1))
        subject.yield(2)

        subscription2.cancel()
        try await Task.sleep(for: .seconds(0.1))

        let subscription1Values = await subscription1.value
        let subscription2Values = await subscription2.value

        #expect(subscription1Values == [0, 1])
        #expect(subscription2Values == [1, 2])
    }

    /// Verify that subscriber tasks terminate with errors.
    ///
    /// This also validates that the `onNoSubscription` handler executes as expected.
    @Test func throwingTerminatesSubscribers() async throws {
        struct ExpectedError: Error {}

        let noSubscribersIndicated = Mutex(false)

        let subject: CurrentValueAsyncThrowingSubject<Int> = CurrentValueAsyncThrowingSubject(0) {
            noSubscribersIndicated.withLock {
                $0 = true
            }
        }

        let subscription1 = Task {
            var output: [Int] = []

            for try await element in subject.sink() {
                output.append(element)
            }

            return output
        }

        let subscription2 = Task {
            var output: [Int] = []

            for try await element in subject.sink() {
                output.append(element)
            }

            return output
        }

        try await Task.sleep(for: .seconds(0.1))
        subject.yield(1)

        subject.finish(throwing: ExpectedError())
        try await Task.sleep(for: .seconds(0.1))

        do {
            _ = try await subscription1.value
            Issue.record("Error Expected")
        } catch _ as ExpectedError {}

        do {
            _ = try await subscription2.value
            Issue.record("Error Expected")
        } catch _ as ExpectedError {}

        #expect(noSubscribersIndicated.withLock { $0 })
    }
}
