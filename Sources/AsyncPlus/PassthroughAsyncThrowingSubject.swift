import Foundation

public final actor PassthroughAsyncThrowingSubject<Output> {
    
    private var subscriptions: [UUID: PassthroughAsyncThrowingSequence<Output>] = [:]
    
    public init() {
    }
    
    public func sink() -> AsyncThrowingStream<Output, Error> {
        let id = UUID()
        let sequence = PassthroughAsyncThrowingSequence<Output> { _ in
            Task {
                await self.terminate(id)
            }
        }
        
        subscriptions[id] = sequence
        
        return sequence.stream
    }
    
    public func yield(_ value: Output) {
        guard !subscriptions.isEmpty else {
            return
        }
        
        for (_, sequence) in subscriptions {
            sequence.yield(value)
        }
    }
    
    public func finish(throwing error: (any Error)? = nil) {
        guard !subscriptions.isEmpty else {
            return
        }
        
        for (_, sequence) in subscriptions {
            sequence.finish(throwing: error)
        }
        
        subscriptions.removeAll()
    }
    
    internal func subscriberCount() -> Int {
        subscriptions.count
    }
    
    private func terminate(_ id: UUID) {
        subscriptions[id] = nil
    }
}
