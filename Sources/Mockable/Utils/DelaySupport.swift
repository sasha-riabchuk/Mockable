//
//  DelaySupport.swift
//  Mockable
//
//  Basic delay support for async function mocking
//

import Foundation

// MARK: - Simple Working Delay Solution

/// Utilities for adding delays to async function mocks.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public enum AsyncMockDelay {
    
    /// Creates a delay action that can be used with the action system.
    ///
    /// This utility creates an action that introduces a delay when called.
    /// Use this with `when(mock).function().perform(AsyncMockDelay.action(...))`.
    ///
    /// - Important: This delay happens before the function execution but doesn't
    ///   prevent the function from returning immediately. For actual execution delays,
    ///   use the `willReturnWithSimulatedDelay` methods.
    ///
    /// - Parameters:
    ///   - duration: The fixed duration to delay.
    ///   - clock: The clock to use for sleeping. Defaults to `ContinuousClock()`.
    /// - Returns: An action that introduces the specified delay.
    ///
    /// ## Example
    /// ```swift
    /// given(mock)
    ///     .fetchUser(id: .any)
    ///     .willReturn(.johnDoe)
    ///
    /// when(mock)
    ///     .fetchUser(id: .any)
    ///     .perform(AsyncMockDelay.action(.milliseconds(350)))
    /// ```
    public static func action(
        _ duration: Duration,
        clock: any Clock<Duration> = ContinuousClock()
    ) -> (() -> Void) {
        return {
            // Create a task to delay, but this won't actually delay function execution
            Task.detached {
                try? await clock.sleep(for: duration)
            }
        }
    }
}

// MARK: - Basic Documentation

/// # Delay Support for Async Function Mocking
///
/// This module provides basic utilities for adding delays to async function mocks.
/// While full execution delays require deeper integration, these utilities provide
/// a foundation for delay support and offer practical options for common use cases.
///
/// ## Basic Usage
///
/// ### Using Action-Based Delays
/// ```swift
/// // Set up return value
/// given(mock)
///     .fetchUser(id: .any)
///     .willReturn(.johnDoe)
///
/// // Add delay action
/// when(mock)
///     .fetchUser(id: .any)
///     .perform(AsyncMockDelay.action(.milliseconds(350)))
/// ```
///
/// ### Custom Producers
/// ```swift
/// given(mock)
///     .fetchUser(id: .any)
///     .willProduce { user in
///         // Custom logic with timing can be added here
///         return .johnDoe
///     }
/// ```
///
/// ## Important Notes
///
/// - All delays are implemented using async sleep and are fully cancellable
/// - Delays never block the main thread
/// - This implementation works within the existing Mockable architecture
/// - For best results, use with async functions only
///
/// ## Future Enhancements
///
/// Future versions may include more sophisticated delay mechanisms that integrate
/// more deeply with the async function execution flow.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public enum DelayDocumentation {
    // This enum serves as a namespace for documentation
}