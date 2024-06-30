/// Wrapper around `AsyncThrowingStream` which maintains references to the stream and continuation.
///
/// This is primarily used with Swift 5.8 and lower.
public final class PassthroughAsyncThrowingSequence<Element>: AsyncSequence {
    
    public private(set) var stream: AsyncThrowingStream<Element, Error>!
    private var continuation: AsyncThrowingStream<Element, Error>.Continuation!
    private lazy var iterator = stream.makeAsyncIterator()
    
    public init(onTermination: (@Sendable (AsyncThrowingStream<Element, Error>.Continuation.Termination) -> Void)? = nil) {
        stream = AsyncThrowingStream<Element, Error> { token in
            token.onTermination = onTermination
            continuation = token
        }
    }
    
    public func makeAsyncIterator() -> AsyncThrowingStream<Element, Error>.Iterator {
        iterator
    }
    
    public func yield(_ element: Element) {
        continuation.yield(element)
    }
    
    public func finish(throwing error: Error? = nil) {
        continuation.finish(throwing: error)
    }
}
