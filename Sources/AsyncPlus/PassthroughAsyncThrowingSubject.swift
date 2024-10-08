import Foundation

/// An actor which maintains and yields output to multiple `AsyncThrowingStream` subscriptions.
public final actor PassthroughAsyncThrowingSubject<Output> {
    
    /// Function executed any time the number of subscribers reaches zero (0).
    public var onNoSubscriptions: (() -> Void)?
    
    #if swift(>=5.9)
    internal private(set) var subscriptions: [UUID: AsyncThrowingStream<Output, Error>.Continuation] = [:]
    #else
    internal private(set) var subscriptions: [UUID: PassthroughAsyncThrowingSequence<Output>] = [:]
    #endif
    
    /// Initialize a `PassthroughAsyncThrowingSubject`
    ///
    /// - parameters:
    ///   - onNoSubscription: Function executed any time the number of subscribers reaches zero (0).
    public init(onNoSubscriptions: (() -> Void)? =  nil) {
        self.onNoSubscriptions = onNoSubscriptions
    }
    
    /// Vends a new `AsyncThrowingStream` that will receive all future output/errors.
    ///
    /// The stream will be _alive_ as long as the downstream reference is maintained
    /// or the subject has not _finished_.
    public func sink() -> AsyncThrowingStream<Output, Error> {
        let id = UUID()
        
        #if swift(>=5.9)
        let sequence = AsyncThrowingStream.makeStream(of: Output.self, throwing: Error.self)
        sequence.continuation.onTermination = { [weak self] _ in
            guard let self else {
                return
            }
            
            Task {
                await self.terminate(id)
            }
        }
        subscriptions[id] = sequence.continuation
        #else
        let sequence = PassthroughAsyncThrowingSequence<Output> { [weak self] _ in
            guard let self else {
                return
            }
            
            Task {
                await self.terminate(id)
            }
        }
        subscriptions[id] = sequence
        #endif
        
        return sequence.stream
    }
    
    /// Resumes all subscriber tasks and sends the provided value.
    public func yield(_ value: Output) {
        guard !subscriptions.isEmpty else {
            return
        }
        
        for (_, continuation) in subscriptions {
            continuation.yield(value)
        }
    }
    
    /// Resumes all subscriber tasks with a `nil` value or `Error`
    /// indicating the termination of the stream.
    public func finish(throwing error: (any Error)? = nil) {
        guard !subscriptions.isEmpty else {
            return
        }
        
        for (_, continuation) in subscriptions {
            continuation.finish(throwing: error)
        }
        
        subscriptions.removeAll()
        onNoSubscriptions?()
    }
    
    private func terminate(_ id: UUID) {
        guard !subscriptions.isEmpty else {
            return
        }
        
        subscriptions[id] = nil
        
        if subscriptions.isEmpty {
            onNoSubscriptions?()
        }
    }
}
