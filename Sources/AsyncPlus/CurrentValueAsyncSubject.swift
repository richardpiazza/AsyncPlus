import Foundation

/// An actor which maintains and yields output to multiple `AsyncStream` subscriptions.
///
/// Unlike a `PassthroughAsyncSubject` a initial/last output is available as reference and
/// automatically yielded on any new subscription.
public final actor CurrentValueAsyncSubject<Output> {
    
    /// The initial or last `Output` to be yielded to subscribers.
    public private(set) var value: Output
    
    /// Function executed any time the number of subscribers reaches zero (0).
    public var onNoSubscriptions: (() -> Void)?
    
    #if swift(>=5.9)
    internal private(set) var subscriptions: [UUID: AsyncStream<Output>.Continuation] = [:]
    #else
    internal private(set) var subscriptions: [UUID: PassthroughAsyncSequence<Output>] = [:]
    #endif
    
    /// Initialize a `CurrentValueAsyncSubject`.
    ///
    /// - parameters:
    ///   - value: The initial `Output` that will stored.
    ///   - onNoSubscription: Function executed any time the number of subscribers reaches zero (0).
    public init(_ value: Output, onNoSubscriptions: (() -> Void)? =  nil) {
        self.value = value
        self.onNoSubscriptions = onNoSubscriptions
    }
    
    /// Vends a new `AsyncStream` that will receive the current `value` and all future output.
    ///
    /// The stream will be _alive_ as long as the downstream reference is maintained
    /// or the subject has not _finished_.
    public func sink() -> AsyncStream<Output> {
        let id = UUID()
        
        #if swift(>=5.9)
        let sequence = AsyncStream.makeStream(of: Output.self)
        sequence.continuation.onTermination = { [weak self] _ in
            guard let self else {
                return
            }
            
            Task {
                await self.terminate(id)
            }
        }
        subscriptions[id] = sequence.continuation
        
        defer {
            sequence.continuation.yield(value)
        }
        #else
        let sequence = PassthroughAsyncSequence<Output> { [weak self] _ in
            guard let self else {
                return
            }
            
            Task {
                await self.terminate(id)
            }
        }
        subscriptions[id] = sequence
        
        defer {
            sequence.yield(value)
        }
        #endif
        
        return sequence.stream
    }
    
    /// Resumes all subscriber tasks and sends the provided value.
    public func yield(_ value: Output) {
        self.value = value
        
        guard !subscriptions.isEmpty else {
            return
        }
        
        for (_, continuation) in subscriptions {
            continuation.yield(value)
        }
    }
    
    /// Resumes all subscriber tasks with a `nil` value indicating the termination of the stream.
    public func finish() {
        guard !subscriptions.isEmpty else {
            return
        }
        
        for (_, continuation) in subscriptions {
            continuation.finish()
        }
        
        subscriptions.removeAll()
    }
    
    private func terminate(_ id: UUID) {
        subscriptions[id] = nil
        
        if subscriptions.isEmpty {
            onNoSubscriptions?()
        }
    }
}
