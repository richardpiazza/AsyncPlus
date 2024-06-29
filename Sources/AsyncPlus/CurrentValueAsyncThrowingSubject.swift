import Foundation

public final actor CurrentValueAsyncThrowingSubject<Output, Failure> where Failure: Error {
    
    public private(set) var value: Output
    
    private var subscriptions: [UUID: AsyncThrowingStream<Output, Failure>.Continuation] = [:]
    
    public init(_ value: Output, throwing: Failure.Type) where Failure == any Error {
        self.value = value
    }
    
    public func sink() -> AsyncThrowingStream<Output, Failure> where Failure == any Error {
        let id = UUID()
        let sequence = AsyncThrowingStream.makeStream(of: Output.self, throwing: Failure.self)
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
    
    public func finish(throwing error: Failure? = nil) {
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
