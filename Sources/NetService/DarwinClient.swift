//
//  DarwinClient.swift
//  NetService
//
//  Created by Alsey Coleman Miller on 11/5/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation
import Dispatch

#if os(macOS) || os(iOS)

@objc(NetServiceClient)
public final class DarwinNetServiceClient: NSObject, NetServiceClient {
    
    // MARK: - Properties
    
    public var log: ((String) -> ())?
    
    private lazy var netServiceBrowser: NetServiceBrowser = {
        let netServiceBrowser = NetServiceBrowser()
        netServiceBrowser.delegate = self
        return netServiceBrowser
    }()
    
    private lazy var accessQueue: DispatchQueue = DispatchQueue(label: "\(type(of: self)) Access Queue", attributes: [])
    
    private var internalState = InternalState()
    
    // MARK: - Initialization
    
    public override init() {
        
        super.init()
    }
    
    // MARK: - Methods
    
    public func discoverServices(of type: NetServiceType,
                                 in domain: NetServiceDomain,
                                 shouldContinue: () -> Bool,
                                 foundService: @escaping (NetService) -> ()) throws {
        
        // remove previous results for domain and type
        accessQueue.sync { [unowned self] in
            
            self.internalState.discoverServices.foundService = foundService
            self.internalState.discoverServices.services = self.internalState.discoverServices.services
                .filter { ($0.key.type == type && $0.key.domain == domain) == false }
        }
        
        // perform search
        netServiceBrowser.searchForServices(ofType: type.rawValue, inDomain: domain.rawValue)
        
        // wait
        while shouldContinue() {
            sleep(1)
        }
        
        netServiceBrowser.stop()
    }
    
    public func resolve(_ service: NetService, timeout: TimeInterval) throws -> [String] {
        
        precondition(timeout > 0.0, "Cannot indefinitely resolve")
        
        let netService = try accessQueue.sync { [unowned self] () -> Foundation.NetService in
            
            guard let netService = self.internalState.discoverServices.services[service]
                else { throw NetServiceClientError.invalidService(service) }
            
            return netService
        }
        
        // store semaphore
        let semaphore = Semaphore(timeout: timeout, operation: .resolve(service))
        accessQueue.sync { [unowned self] in self.internalState.resolveAddress.semaphore = semaphore }
        defer { accessQueue.sync { [unowned self] in self.internalState.resolveAddress.semaphore = nil } }
        
        // perform action
        netService.resolve(withTimeout: timeout)
        
        // wait
        try semaphore.wait()
        
        netService.addresses
    }
}

// MARK: - NetServiceBrowserDelegate

@objc
extension DarwinNetServiceClient: NetServiceBrowserDelegate {
    
    public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        
        log?("Will search")
        
        
    }
    
    public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        
        log?("Did stop search")
        
        
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        
        log?("Did not search: \(errorDict)")
        
        
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        
        log?("Did find domain \(domainString)" + (moreComing ? " (more coming)" : ""))
        
        
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: Foundation.NetService, moreComing: Bool) {
        
        log?("Did find service \(service.domain) \(service.type) \(service.name)" + (moreComing ? " (more coming)" : ""))
        
        service.delegate = self
        
        let value = NetService(domain: NetServiceDomain(rawValue: service.domain)!,
                               type: NetServiceType(rawValue: service.type)!,
                               name: service.name)
        
        accessQueue.sync { [unowned self] in
            
            self.internalState.discoverServices.services[value] = service
            self.internalState.discoverServices.foundService?(value)
        }
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        
        log?("Did remove domain \(domainString)" + (moreComing ? " (more coming)" : ""))
        
        
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: Foundation.NetService, moreComing: Bool) {
        
        log?("Did remove service \(service.domain) \(service.type) \(service.name)" + (moreComing ? " (more coming)" : ""))
        
        
    }
}

// MARK: - NetServiceDelegate

@objc
extension DarwinNetServiceClient: NetServiceDelegate {

    public func netServiceWillPublish(_ service: Foundation.NetService) {
        
        log?("[\(service.domain)\(service.type)\(service.name)]: Will publish")
    }
    
    
    public func netServiceDidPublish(_ service: Foundation.NetService) {
        
        log?("[\(service.domain)\(service.type)\(service.name)]: Did publish")
    }
    
    
    public func netService(_ service: Foundation.NetService, didNotPublish errorDict: [String : NSNumber]) {
        
        log?("[\(service.domain)\(service.type)\(service.name)]: Did not publish \(errorDict)")
    }
    
    
    public func netServiceWillResolve(_ service: Foundation.NetService) {
        
        log?("[\(service.domain)\(service.type)\(service.name)]: Will resolve")
    }
    
    
    public func netServiceDidResolveAddress(_ service: Foundation.NetService) {
        
        log?("[\(service.domain)\(service.type)\(service.name)]: Did resolve")
        
        accessQueue.sync { [unowned self] in
            self.internalState.resolveAddress.semaphore?.stopWaiting()
            self.internalState.resolveAddress.semaphore = nil
        }
    }
    
    public func netService(_ service: Foundation.NetService, didNotResolve errorDict: [String : NSNumber]) {
        
        log?("[\(service.domain)\(service.type)\(service.name)]: Did not resolve \(errorDict)")
        
        accessQueue.sync { [unowned self] in
            self.internalState.resolveAddress.semaphore?.stopWaiting(NetServiceClientError.timeout)
            self.internalState.resolveAddress.semaphore = nil
        }
    }
    
    public func netServiceDidStop(_ service: Foundation.NetService) {
        
        log?("[\(service.domain)\(service.type)\(service.name)]: Did stop")
    }
    
    public func netService(_ service: Foundation.NetService, didUpdateTXTRecord data: Data) {
        
        log?("[\(service.domain)\(service.type)\(service.name)]: Did udpate TXT record")
    }
}

// MARK: - Private Types

private extension DarwinNetServiceClient {
    
    struct InternalState {
        
        var discoverServices = DiscoverServices()
        
        struct DiscoverServices {
            
            var services = [NetService: Foundation.NetService]()
            
            var foundService: ((NetService) -> ())?
        }
        
        var resolveAddress = ResolveAddress()
        
        struct ResolveAddress {
            
            var semaphore: Semaphore?
        }
    }
    
    enum Operation {
        
        case discoverServices(NetServiceDomain, NetServiceType)
        case resolve(NetService)
    }
    
    final class Semaphore {
        
        let operation: Operation
        let semaphore: DispatchSemaphore
        let timeout: TimeInterval
        var error: Swift.Error?
        
        init(timeout: TimeInterval,
             operation: Operation) {
            
            self.operation = operation
            self.timeout = timeout
            self.semaphore = DispatchSemaphore(value: 0)
            self.error = nil
        }
        
        func wait() throws {
            
            let dispatchTime: DispatchTime = .now() + timeout
            
            let success = semaphore.wait(timeout: dispatchTime) == .success
            
            if let error = self.error {
                
                throw error
            }
            
            guard success else { throw NetServiceClientError.timeout }
        }
        
        func stopWaiting(_ error: Swift.Error? = nil) {
            
            // store signal
            self.error = error
            
            // stop blocking
            semaphore.signal()
        }
    }
}

#endif
