import Foundation

public final actor CurrentValueAsyncSubject<Output> {
    
    public private(set) var value: Output
    
    private var subscriptions: [UUID: AsyncStream<Output>.Continuation] = [:]
    
    public init(_ value: Output) {
        self.value = value
    }
    
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
        
        defer {
            sequence.continuation.yield(value)
        }
        
        return sequence.stream
    }
    
    public func yield(_ value: Output) {
        self.value = value
        
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
