import Foundation

/// An actor which maintains and yeilds output to multiple `AsyncThrowingStream` subscriptions.
public final actor CurrentValueAsyncThrowingSubject<Output> {
    
    public private(set) var value: Output
    
    #if swift(>=5.9)
    internal private(set) var subscriptions: [UUID: AsyncThrowingStream<Output, Error>.Continuation] = [:]
    #else
    internal private(set) var subscriptions: [UUID: PassthroughAsyncThrowingSequence<Output>] = [:]
    #endif
    
    public init(_ value: Output) {
        self.value = value
    }
    
    /// Vends a new `AsyncThrowingStream` that will recieve the current `value` all future output/errors.
    ///
    /// The stream will be _alive_ as long as the downstream reference is maintained
    /// or the subject has not _finished_.
    public func sink() -> AsyncThrowingStream<Output, Error> {
        let id = UUID()
        
        #if swift(>=5.9)
        let sequence = AsyncThrowingStream.makeStream(of: Output.self)
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
        let sequence = PassthroughAsyncThrowingSequence<Output> { [weak self] _ in
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
    
    /// Resumes all subscriber tasks with a `nil` value or `Error`
    /// indicating the termination of the stream.
    public func finish(throwing error: Error? = nil) {
        guard !subscriptions.isEmpty else {
            return
        }
        
        for (_, continuation) in subscriptions {
            continuation.finish(throwing: error)
        }
        
        subscriptions.removeAll()
    }
    
    private func terminate(_ id: UUID) {
        subscriptions[id] = nil
    }
}