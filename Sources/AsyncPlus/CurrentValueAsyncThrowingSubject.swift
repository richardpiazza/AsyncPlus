import Foundation
import Mutex

/// Type which maintains and yields output to multiple `AsyncThrowingStream` subscriptions.
public final class CurrentValueAsyncThrowingSubject<Output: Sendable>: Sendable {

    /// The initial or last `Output` to be yielded to subscribers.
    public var value: Output {
        currentValue.withLock { $0 }
    }

    /// The number of subscribers.
    public var subscribers: Int {
        subscriptions.withLock { $0.count }
    }

    private let currentValue: Mutex<Output>
    private let subscriptions: Mutex<[UUID: AsyncThrowingStream<Output, any Error>.Continuation]>
    private let onNoSubscriptions: Mutex<(() -> Void)?>

    /// Initialize a `CurrentValueAsyncThrowingSubject`.
    ///
    /// - parameters:
    ///   - value: The initial `Output` that will stored.
    ///   - onNoSubscription: Function executed any time the number of subscribers reaches zero (0).
    public init(_ value: Output, onNoSubscriptions: (@Sendable () -> Void)? = nil) {
        currentValue = Mutex(value)
        subscriptions = Mutex([:])
        self.onNoSubscriptions = Mutex(onNoSubscriptions)
    }

    /// Vends a new `AsyncThrowingStream` that will receive the current `value` all future output/errors.
    ///
    /// The stream will be _alive_ as long as the downstream reference is maintained
    /// or the subject has not _finished_.
    public func sink() -> AsyncThrowingStream<Output, any Error> {
        let id = UUID()

        let sequence = AsyncThrowingStream.makeStream(of: Output.self)
        sequence.continuation.onTermination = { [weak self] _ in
            self?.terminate(id)
        }

        subscriptions.withLock {
            $0[id] = sequence.continuation
        }

        defer {
            sequence.continuation.yield(value)
        }

        return sequence.stream
    }

    public func setOnNoSubscriptions(_ handler: (@Sendable () -> Void)?) {
        onNoSubscriptions.withLock {
            $0 = handler
        }
    }

    /// Resumes all subscriber tasks and sends the provided value.
    public func yield(_ value: Output) {
        currentValue.withLock {
            $0 = value
        }

        let subs = subscriptions.withLock { $0 }

        guard !subs.isEmpty else {
            return
        }

        for (_, continuation) in subs {
            continuation.yield(value)
        }
    }

    /// Resumes all subscriber tasks with a `nil` value or `Error`
    /// indicating the termination of the stream.
    public func finish(throwing error: (any Error)? = nil) {
        let subs = subscriptions.withLock { $0 }

        guard !subs.isEmpty else {
            notifyNoSubscriptions()
            return
        }

        for (_, continuation) in subs {
            continuation.finish(throwing: error)
        }

        subscriptions.withLock {
            $0.removeAll()
        }

        notifyNoSubscriptions()
    }

    private func terminate(_ id: UUID) {
        subscriptions.withLock {
            $0[id] = nil

            if $0.isEmpty {
                notifyNoSubscriptions()
            }
        }
    }

    private func notifyNoSubscriptions() {
        onNoSubscriptions.withLock {
            $0?()
        }
    }
}
