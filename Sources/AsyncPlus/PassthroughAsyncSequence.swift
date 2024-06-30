/// Wrapper around `AsyncStream` which maintains references to the stream and continuation.
///
/// This is primarily used with Swift 5.8 and lower.
public final class PassthroughAsyncSequence<Element>: AsyncSequence {
    
    public private(set) var stream: AsyncStream<Element>!
    private var continuation: AsyncStream<Element>.Continuation!
    private lazy var iterator = stream.makeAsyncIterator()
    
    public init(onTermination: (@Sendable (AsyncStream<Element>.Continuation.Termination) -> Void)? = nil) {
        stream = AsyncStream<Element> { token in
            token.onTermination = onTermination
            continuation = token
        }
    }
    
    public func makeAsyncIterator() -> AsyncStream<Element>.Iterator {
        iterator
    }
    
    public func yield(_ element: Element) {
        continuation.yield(element)
    }
    
    public func finish() {
        continuation.finish()
    }
}
