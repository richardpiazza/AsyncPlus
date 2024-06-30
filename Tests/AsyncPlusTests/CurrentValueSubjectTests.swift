import XCTest
@testable import AsyncPlus

final class CurrentValueSubjectTests: XCTestCase {
    
    /// Verify that a _new_ subscriber receives the _current_ value from the subject.
    ///
    /// This also validates that canceling a subscription `Task` will also remove the subscriber.
    func testSingleSubscriber() async throws {
        let subject = CurrentValueAsyncSubject(0)
        var value = await subject.value
        XCTAssertEqual(value, 0)
        
        let subscription1 = Task {
            var output: [Int] = []
            
            for await element in await subject.sink() {
                output.append(element)
            }
            
            return output
        }
        
        try await Task.sleep(for: .seconds(0.1))
        await subject.yield(1)
        value = await subject.value
        XCTAssertEqual(value, 1)
        
        var subscriberCount = await subject.subscriptions.count
        XCTAssertEqual(subscriberCount, 1)
        
        subscription1.cancel()
        try await Task.sleep(for: .seconds(0.1))
        
        subscriberCount = await subject.subscriptions.count
        XCTAssertEqual(subscriberCount, 0)
        
        let values = await subscription1.value
        XCTAssertEqual(values, [0, 1])
    }
    
    /// Verify that a _new_ subscriber receives the _current_ and future values from the subject.
    func testMultipleSubscribers() async throws {
        let subject = CurrentValueAsyncSubject(0)
        
        let subscription1 = Task {
            var output: [Int] = []
            
            for await element in await subject.sink() {
                output.append(element)
            }
            
            return output
        }
        
        try await Task.sleep(for: .seconds(0.1))
        await subject.yield(1)
        
        subscription1.cancel()
        try await Task.sleep(for: .seconds(0.1))
        
        let subscription2 = Task {
            var output: [Int] = []
            
            for await element in await subject.sink() {
                output.append(element)
            }
            
            return output
        }
        
        try await Task.sleep(for: .seconds(0.1))
        await subject.yield(2)
        
        subscription2.cancel()
        try await Task.sleep(for: .seconds(0.1))
        
        let subscription1Values = await subscription1.value
        let subscription2Values = await subscription2.value
        
        XCTAssertEqual(subscription1Values, [0, 1])
        XCTAssertEqual(subscription2Values, [1, 2])
    }
    
    func testThrowingTerminatesSubscribers() async throws {
        struct ExpectedError: Error {}
        
        let subject = CurrentValueAsyncThrowingSubject(0)
        
        let subscription1 = Task {
            var output: [Int] = []
            
            for try await element in await subject.sink() {
                output.append(element)
            }
            
            return output
        }
        
        let subscription2 = Task {
            var output: [Int] = []
            
            for try await element in await subject.sink() {
                output.append(element)
            }
            
            return output
        }
        
        try await Task.sleep(for: .seconds(0.1))
        await subject.yield(1)
        
        await subject.finish(throwing: ExpectedError())
        try await Task.sleep(for: .seconds(0.1))
        
        do {
            _ = try await subscription1.value
            XCTFail("Error Expected")
        } catch _ as ExpectedError {
        }
        
        do {
            _ = try await subscription2.value
            XCTFail("Error Expected")
        } catch _ as ExpectedError {
        }
    }
}
