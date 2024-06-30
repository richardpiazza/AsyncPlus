import Foundation

/// An actor which maintains and yeilds output to multiple `AsyncStream` subscriptions.
///
/// Unlike `CurrentValueAsyncSubject`, a `PassthroughAsyncSubject` doesn’t have an
/// initial value or a buffer of the most recently-published element.
public final actor PassthroughAsyncSubject<Output> {
    
    internal private(set) var subscriptions: [UUID: AsyncStream<Output>.Continuation] = [:]
    
    public init() {
    }
    
    /// Vends a new `AsyncStream` that will recieve all future output.
    ///
    /// The stream will be _alive_ as long as the downstream reference is maintained
    /// or the subject has not _finished_.
    public func sink() -> AsyncStream<Output> {
        let id = UUID()
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
    }
}
