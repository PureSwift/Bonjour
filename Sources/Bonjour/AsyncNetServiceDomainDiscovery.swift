//
//  AsyncNetServiceDomainDiscovery.swift
//  
//
//  Created by Alsey Coleman Miller on 10/5/22.
//

/// Async stream of discovered domains net services.
public struct AsyncNetServiceDomainDiscovery: AsyncSequence {
    
    public typealias Element = NetServiceDomain
    
    let stream: AsyncIndefiniteStream<Element>
    
    public init(
        bufferSize: Int = 100,
        _ build: @escaping ((Element) -> ()) async throws -> ()
    ) {
        self.stream = .init(bufferSize: bufferSize, build)
    }
    
    public init(
        bufferSize: Int = 100,
        onTermination: @escaping () -> (),
        _ build: (AsyncIndefiniteStream<Element>.Continuation) -> ()
    ) {
        self.stream = .init(bufferSize: bufferSize, onTermination: onTermination, build)
    }
    
    public func makeAsyncIterator() -> AsyncIndefiniteStream<Element>.AsyncIterator {
        stream.makeAsyncIterator()
    }
    
    /// Halts a currently running search.
    public func stop() {
        stream.stop()
    }
    
    public var isScanning: Bool {
        return stream.isExecuting
    }
}

public extension AsyncNetServiceDomainDiscovery {
    
    func first() async throws -> Element? {
        for try await element in self {
            self.stop()
            return element
        }
        return nil
    }
}
