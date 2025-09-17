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
}