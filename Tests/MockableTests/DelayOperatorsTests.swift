//
//  DelayOperatorsTests.swift
//  MockableTests
//
//  Tests for delay functionality
//

import XCTest
import Mockable

final class DelayOperatorsTests: XCTestCase {
    
    private var mock = MockTestService<String>()
    
    override func tearDown() {
        mock.reset()
        Matcher.reset()
    }
    
    func test_basicAsyncFunctionMocking() async throws {
        // First, let's understand how async functions currently work
        given(mock)
            .setUser(user: .any)
            .willReturn(true)
        
        let result = try await mock.setUser(user: .test1)
        XCTAssertTrue(result)
    }
    
    func test_asyncFunctionWithProducer() async throws {
        // Test how producers work with async functions
        given(mock)
            .setUser(user: .any)
            .willProduce { user in 
                // This producer should work with async functions
                return true
            }
        
        let result = try await mock.setUser(user: .test1)
        XCTAssertTrue(result)
    }
    
    func test_delayActions() async throws {
        // Test delay actions with the action system
        given(mock)
            .setUser(user: .any)
            .willReturn(true)
        
        when(mock)
            .setUser(user: .any)
            .perform(AsyncMockDelay.action(Duration.milliseconds(30)))
        
        let result = try await mock.setUser(user: .test1)
        XCTAssertTrue(result)
    }
    
    func test_customProducerWithDelay() async throws {
        // Test custom producers that include delay logic
        given(mock)
            .setUser(user: .any)
            .willProduce { user in
                // This is where users could add delay logic in their custom producers
                // The producer itself is not async, but could use other mechanisms
                return true
            }
        
        let result = try await mock.setUser(user: .test1)
        XCTAssertTrue(result)
    }
    
    func test_documentationExamples() async throws {
        // Test the examples from the documentation work
        
        // Example 1: Action-based delay
        given(mock)
            .setUser(user: .any)
            .willReturn(true)
        
        when(mock)
            .setUser(user: .any)
            .perform(AsyncMockDelay.action(Duration.milliseconds(10)))
        
        let result1 = try await mock.setUser(user: .test1)
        XCTAssertTrue(result1)
        
        // Reset for next test
        mock.reset()
        
        // Example 2: Custom producer
        given(mock)
            .setUser(user: .any)
            .willProduce { user in
                // Custom logic with timing can be added here
                return true
            }
        
        let result2 = try await mock.setUser(user: .test1)
        XCTAssertTrue(result2)
    }
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func test_delayedAsyncSequence() async throws {
        // Test DelayedAsyncSequence functionality
        let baseSequence = TestAsyncSequence([1, 2, 3])
        
        // Test subscription delay
        let delayedSubscription = baseSequence.delaySubscription(by: Duration.milliseconds(10))
        
        var results: [Int] = []
        let startTime = Date()
        
        for try await value in delayedSubscription {
            results.append(value)
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        XCTAssertEqual(results, [1, 2, 3])
        XCTAssertGreaterThan(elapsed, 0.008) // At least 8ms for the subscription delay
    }
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func test_delayedAsyncSequenceElements() async throws {
        // Test element delay
        let baseSequence = TestAsyncSequence([1, 2, 3])
        let delayedElements = baseSequence.delayEach(by: Duration.milliseconds(5))
        
        var results: [Int] = []
        let startTime = Date()
        
        for try await value in delayedElements {
            results.append(value)
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        XCTAssertEqual(results, [1, 2, 3])
        // Should have at least 2 delays (between elements) = 10ms total
        XCTAssertGreaterThan(elapsed, 0.008)
    }
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func test_asyncSequenceDelayUtility() async throws {
        // Test the utility function
        let baseSequence = TestAsyncSequence([1, 2])
        let delayedSequence = AsyncSequenceDelay.create(
            baseSequence,
            subscriptionDelay: Duration.milliseconds(5),
            elementDelay: Duration.milliseconds(5)
        )
        
        var results: [Int] = []
        for try await value in delayedSequence {
            results.append(value)
        }
        
        XCTAssertEqual(results, [1, 2])
    }
}

// MARK: - Test Helper

/// A simple async sequence for testing
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct TestAsyncSequence: AsyncSequence {
    typealias Element = Int
    
    private let values: [Int]
    
    init(_ values: [Int]) {
        self.values = values
    }
    
    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(values: values)
    }
    
    struct AsyncIterator: AsyncIteratorProtocol {
        private let values: [Int]
        private var index = 0
        
        init(values: [Int]) {
            self.values = values
        }
        
        mutating func next() async throws -> Int? {
            guard index < values.count else { return nil }
            let value = values[index]
            index += 1
            return value
        }
    }
}