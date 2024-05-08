import XCTest
@testable import AsyncPlus

final class SubjectTests: XCTestCase {
    
    func testSingleSubscriber() async throws {
        let subject = PassthroughAsyncSubject<Int>()
        
        let task1 = Task {
            var output: [Int] = []
            
            for await element in await subject.sink() {
                output.append(element)
            }
            
            return output
        }
        
        try await Task.sleep(nanoseconds: 500_000_000)
        await subject.yield(1)
        await subject.yield(2)
        await subject.yield(3)
        await subject.finish()
        let subscriberCount = await subject.subscriberCount()
        
        let values = await task1.value
        XCTAssertEqual(values.count, 3)
        XCTAssertEqual(values, [1, 2, 3])
        XCTAssertEqual(subscriberCount, 0)
    }
    
    func testMultipleSubscribers() async throws {
        let subject = PassthroughAsyncSubject<Int>()
        
        let task1 = Task {
            var output: [Int] = []
            
            for await element in await subject.sink() {
                output.append(element)
            }
            
            return output
        }
        
        try await Task.sleep(nanoseconds: 500_000_000)
        await subject.yield(1)
        
        let task2 = Task {
            var output: [Int] = []
            
            for await element in await subject.sink() {
                output.append(element)
            }
            
            return output
        }
        
        try await Task.sleep(nanoseconds: 500_000_000)
        await subject.yield(2)
        await subject.yield(3)
        await subject.finish()
        let subscriberCount = await subject.subscriberCount()
        
        let values1 = await task1.value
        XCTAssertEqual(values1.count, 3)
        XCTAssertEqual(values1, [1, 2, 3])
        
        let values2 = await task2.value
        XCTAssertEqual(values2.count, 2)
        XCTAssertEqual(values2, [2, 3])
        
        XCTAssertEqual(subscriberCount, 0)
    }
    
    func testCanceledTaskRemovesSubscriber() async throws {
        let subject = PassthroughAsyncSubject<Int>()
        
        let task1 = Task {
            var output: [Int] = []
            
            for await element in await subject.sink() {
                output.append(element)
            }
            
            return output
        }
        
        try await Task.sleep(nanoseconds: 500_000_000)
        await subject.yield(1)
        await subject.yield(2)
        
        task1.cancel()
        
        try await Task.sleep(nanoseconds: 500_000_000)
        let subscriberCount = await subject.subscriberCount()
        XCTAssertEqual(subscriberCount, 0)
        
        await subject.yield(3)
        await subject.finish()
        
        let values = await task1.value
        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(values, [1, 2])
    }
}
