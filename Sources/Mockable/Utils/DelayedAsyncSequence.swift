//
//  DelayedAsyncSequence.swift
//  Mockable
//
//  Support for delayed async sequences
//

import Foundation

// MARK: - DelayedAsyncSequence for Streaming Support

/// An async sequence that applies delays to subscription and/or element delivery.
///
/// This async sequence wrapper enables simulation of slow network connections,
/// variable data transmission rates, and other streaming scenarios in SwiftUI previews and tests.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public struct DelayedAsyncSequence<Base: AsyncSequence>: AsyncSequence {
    public typealias Element = Base.Element
    
    private let base: Base
    private let subscriptionDelay: Duration?
    private let elementDelay: Duration?
    private let clock: any Clock<Duration>
    
    internal init(
        base: Base,
        subscriptionDelay: Duration? = nil,
        elementDelay: Duration? = nil,
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        self.base = base
        self.subscriptionDelay = subscriptionDelay
        self.elementDelay = elementDelay
        self.clock = clock
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(
            baseIterator: base.makeAsyncIterator(),
            subscriptionDelay: subscriptionDelay,
            elementDelay: elementDelay,
            clock: clock
        )
    }
    
    /// Iterator that handles delayed element delivery
    public struct AsyncIterator: AsyncIteratorProtocol {
        private var baseIterator: Base.AsyncIterator
        private let subscriptionDelay: Duration?
        private let elementDelay: Duration?
        private let clock: any Clock<Duration>
        private var isFirst = true
        
        internal init(
            baseIterator: Base.AsyncIterator,
            subscriptionDelay: Duration?,
            elementDelay: Duration?,
            clock: any Clock<Duration>
        ) {
            self.baseIterator = baseIterator
            self.subscriptionDelay = subscriptionDelay
            self.elementDelay = elementDelay
            self.clock = clock
        }
        
        public mutating func next() async throws -> Element? {
            // Apply subscription delay on first call
            if isFirst, let subscriptionDelay = subscriptionDelay {
                try await clock.sleep(for: subscriptionDelay)
                isFirst = false
            }
            
            // Get the next element
            let element = try await baseIterator.next()
            
            // Apply element delay if we have an element and it's not the first one
            if element != nil, !isFirst, let elementDelay = elementDelay {
                try await clock.sleep(for: elementDelay)
            }
            
            if isFirst {
                isFirst = false
            }
            
            return element
        }
    }
}

// MARK: - AsyncSequence Extensions

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension AsyncSequence {
    
    /// Returns a new async sequence that delays subscription by the specified duration.
    ///
    /// This method simulates slow connection establishment or server response times
    /// by delaying the subscription to the async sequence.
    ///
    /// - Important: The delay is applied once when the sequence is first accessed,
    ///   not for each element. The delay is fully cancellable.
    ///
    /// - Parameters:
    ///   - duration: The duration to delay before subscribing.
    ///   - clock: The clock to use for sleeping. Defaults to `ContinuousClock()`.
    /// - Returns: A delayed async sequence.
    ///
    /// ## Example
    /// ```swift
    /// let stream = MyAsyncSequence([1, 2, 3])
    ///     .delaySubscription(by: .milliseconds(150))
    /// 
    /// for await value in stream {
    ///     print(value) // First value appears after 150ms delay
    /// }
    /// ```
    public func delaySubscription(
        by duration: Duration,
        clock: any Clock<Duration> = ContinuousClock()
    ) -> DelayedAsyncSequence<Self> {
        DelayedAsyncSequence(
            base: self,
            subscriptionDelay: duration,
            clock: clock
        )
    }
    
    /// Returns a new async sequence that delays each element by the specified duration.
    ///
    /// This method simulates slow data transmission or processing delays by introducing
    /// a delay between each yielded element.
    ///
    /// - Important: The delay is applied between elements, not before the first element.
    ///   All delays are fully cancellable.
    ///
    /// - Parameters:
    ///   - duration: The duration to delay between elements.
    ///   - clock: The clock to use for sleeping. Defaults to `ContinuousClock()`.
    /// - Returns: A delayed async sequence.
    ///
    /// ## Example
    /// ```swift
    /// let stream = MyAsyncSequence([1, 2, 3])
    ///     .delayEach(by: .milliseconds(50))
    /// 
    /// for await value in stream {
    ///     print(value) // Each value appears 50ms after the previous
    /// }
    /// ```
    public func delayEach(
        by duration: Duration,
        clock: any Clock<Duration> = ContinuousClock()
    ) -> DelayedAsyncSequence<Self> {
        DelayedAsyncSequence(
            base: self,
            elementDelay: duration,
            clock: clock
        )
    }
    
    /// Returns a new async sequence that delays both subscription and each element.
    ///
    /// This method combines subscription and element delays to simulate complex
    /// network scenarios with both slow connection establishment and slow data transmission.
    ///
    /// - Parameters:
    ///   - subscriptionDelay: The duration to delay before subscribing.
    ///   - elementDelay: The duration to delay between elements.
    ///   - clock: The clock to use for sleeping. Defaults to `ContinuousClock()`.
    /// - Returns: A delayed async sequence.
    ///
    /// ## Example
    /// ```swift
    /// let stream = MyAsyncSequence([1, 2, 3])
    ///     .delay(subscription: .milliseconds(200), elements: .milliseconds(50))
    /// ```
    public func delay(
        subscription subscriptionDelay: Duration,
        elements elementDelay: Duration,
        clock: any Clock<Duration> = ContinuousClock()
    ) -> DelayedAsyncSequence<Self> {
        DelayedAsyncSequence(
            base: self,
            subscriptionDelay: subscriptionDelay,
            elementDelay: elementDelay,
            clock: clock
        )
    }
}

// MARK: - Utilities for Mockable Integration

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public enum AsyncSequenceDelay {
    
    /// Creates a delayed async sequence for use in mocks.
    ///
    /// This utility creates a delayed wrapper around an existing async sequence
    /// that can be used with `willReturn()` in mocks.
    ///
    /// - Parameters:
    ///   - sequence: The base async sequence to wrap.
    ///   - subscriptionDelay: Optional delay before subscription.
    ///   - elementDelay: Optional delay between elements.
    ///   - clock: The clock to use for sleeping. Defaults to `ContinuousClock()`.
    /// - Returns: A delayed async sequence.
    ///
    /// ## Example
    /// ```swift
    /// given(mock)
    ///     .eventsStream()
    ///     .willReturn(AsyncSequenceDelay.create(
    ///         MyAsyncSequence([1, 2, 3]),
    ///         subscriptionDelay: .milliseconds(150),
    ///         elementDelay: .milliseconds(50)
    ///     ))
    /// ```
    public static func create<S: AsyncSequence>(
        _ sequence: S,
        subscriptionDelay: Duration? = nil,
        elementDelay: Duration? = nil,
        clock: any Clock<Duration> = ContinuousClock()
    ) -> DelayedAsyncSequence<S> {
        DelayedAsyncSequence(
            base: sequence,
            subscriptionDelay: subscriptionDelay,
            elementDelay: elementDelay,
            clock: clock
        )
    }
}