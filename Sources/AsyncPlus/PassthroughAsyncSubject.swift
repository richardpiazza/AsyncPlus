import Foundation

public final actor PassthroughAsyncSubject<Output> {
    
    private var subscriptions: [UUID: PassthroughAsyncSequence<Output>] = [:]
    
    public init() {
    }
    
    public func sink() -> AsyncStream<Output> {
        let id = UUID()
        let sequence = PassthroughAsyncSequence<Output> { _ in
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
    
    public func finish() {
        guard !subscriptions.isEmpty else {
            return
        }
        
        for (_, sequence) in subscriptions {
            sequence.finish()
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
