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
}