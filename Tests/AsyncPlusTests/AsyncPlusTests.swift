import XCTest
@testable import AsyncPlus

final class AsyncPlusTests: XCTestCase {
    
    func testAsyncSequence() async throws {
        let sequence = PassthroughAsyncSequence<Int>()
        
        var elements = [Int]()
        
        Task {
            try await Task.sleep(nanoseconds: 500_000)
            sequence.yield(1)
            sequence.yield(2)
            sequence.yield(3)
            sequence.finish()
        }
        
        for await element in sequence {
            elements.append(element)
        }
        
        XCTAssertEqual(elements, [1, 2, 3])
    }
    
    func testAsyncThrowingSequence() async throws {
        struct ExpectedError: Error {}
        
        let sequence = PassthroughAsyncThrowingSequence<Int>()
        
        var elements = [Int]()
        
        Task {
            try await Task.sleep(nanoseconds: 500_000)
            sequence.yield(1)
            sequence.yield(2)
            sequence.finish(throwing: ExpectedError())
        }
        
        do {
            for try await element in sequence {
                elements.append(element)
            }
        } catch is ExpectedError {
            
        }
        
        XCTAssertEqual(elements, [1, 2])
    }
}
