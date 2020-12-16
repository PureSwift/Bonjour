//
//  Client.swift
//  NetService
//
//  Created by Alsey Coleman Miller on 11/5/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation
import Dispatch

#if canImport(NetService)
import NetService
#endif

#if os(macOS) || os(iOS) || canImport(NetService)

public final class NetServiceClient: NetServiceClientProtocol {
    
    // MARK: - Properties
    
    public var log: ((String) -> ())?
    
    private var netServiceBrowser: NetServiceBrowser?
    
    private var internalState = InternalState()
    
    private lazy var delegate = Delegate(self)
    
    private var isScanning = false
    
    // MARK: - Initialization
    
    public init() { }
    
    // MARK: - Methods
    
    public func discoverServices(of type: NetServiceType,
                                 in domain: NetServiceDomain,
                                 foundService: @escaping (Service) -> ()) throws {
        
        netServiceBrowser = NetServiceBrowser()
        netServiceBrowser?.delegate = delegate
        
        // remove previous results
        self.internalState.discoverServices.foundService = foundService
        self.internalState.discoverServices.services.removeAll(keepingCapacity: true)
        
        isScanning = true
        
        // perform search
        netServiceBrowser?.searchForServices(ofType: type.rawValue, inDomain: domain.rawValue)
        
        // wait
        while isScanning {
            RunLoop.current.run(until: Date() + 1.0)
        }
        
        netServiceBrowser?.stop()
        RunLoop.current.run(until: Date() + 0.1)
        
        if let error = self.internalState.discoverServices.error {
            throw NetServiceClientError.notDiscoverServices(error)
        }
    }
    
    /// Halts a currently running search or resolution.
    public func stopDiscovery() {
        isScanning = false
    }
    
    /// Fetch the TXT record data for the specified service.
    ///
    /// - Parameter service: The service for which cached TXT record will be fetched.
    public func txtRecord(for service: Service) -> Data? {
        return internalState.discoverServices.services[service]?.txtRecordData()
    }
    
    public func resolve(_ service: Service, timeout: TimeInterval) throws -> [NetServiceAddress] {
        
        precondition(timeout > 0.0, "Cannot indefinitely resolve")
        
        guard let netService = self.internalState.discoverServices.services[service]
            else { throw NetServiceClientError.invalidService(service) }
        
        // return cache
        if let addresses = netService.addresses, addresses.isEmpty == false {
            return addresses.map { NetServiceAddress(data: $0) }
        }
        
        // perform action
        netService.resolve(withTimeout: timeout)
        
        // run loop
        let end = Date() + timeout
        while Date() < end
            && self.internalState.resolveAddress.didResolve == false
            && self.internalState.resolveAddress.error == nil {
            RunLoop.current.run(until: Date() + 1.0)
        }
        
        if let error = self.internalState.resolveAddress.error {
            throw NetServiceClientError.notResolveAddress(error)
        }
        
        // make sure the method did not timeout
        guard self.internalState.resolveAddress.didResolve || Date() < end
            else { throw NetServiceClientError.timeout }
        
        // return value
        return (netService.addresses ?? []).map { NetServiceAddress(data: $0) }
    }
    
    /// A string containing the DNS hostname for the specified service.
    ///
    /// - Parameter service: The service for which cached host name will be looked up.
    ///
    /// - Note: This value is `nil` until the service has been resolved (when addresses is `non-nil`).
    public func hostName(for service: Service) -> String? {
        return internalState.discoverServices.services[service]?.hostName
    }
}

internal extension NetServiceClient {
    
    final class Delegate: NSObject {
        
        private weak var client: NetServiceClient?
        
        fileprivate init(_ client: NetServiceClient) {
            self.client = client
        }
    }
}

// MARK: - NetServiceBrowserDelegate

extension NetServiceClient.Delegate: NetServiceBrowserDelegate {
    
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        
        client?.log?("Will search")
        client?.internalState.discoverServices.error = nil
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        
        client?.log?("Did stop search")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        
        client?.log?("Did not search: \(errorDict)")
        client?.internalState.discoverServices.error = errorDict
        client?.stopDiscovery()
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domain: String, moreComing: Bool) {
        
        client?.log?("Did find domain \(domain)" + (moreComing ? " (more coming)" : ""))
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        
        client?.log?("Did find service \(service.type) (\(service.name)) in \(service.domain)" + (moreComing ? " (more coming)" : ""))
        
        service.delegate = self
        
        let value = Service(
            domain: NetServiceDomain(rawValue: service.domain),
            type: NetServiceType(rawValue: service.type),
            name: service.name
        )
        
        client?.internalState.discoverServices.services[value] = service
        client?.internalState.discoverServices.foundService?(value)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domain: String, moreComing: Bool) {
        
        client?.log?("Did remove domain \(domain)" + (moreComing ? " (more coming)" : ""))
        
        
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        
        client?.log?("Did remove service \(service.type) (\(service.name)) in \(service.domain)" + (moreComing ? " (more coming)" : ""))
        
        
    }
}

// MARK: - NetServiceDelegate

extension NetServiceClient.Delegate: NetServiceDelegate {
    
    public func netServiceWillResolve(_ service: NetService) {
        
        client?.log?("[\(service.domain)\(service.type)\(service.name)]: Will resolve")
        client?.internalState.resolveAddress.didResolve = false
        client?.internalState.resolveAddress.error = nil
    }
    
    public func netServiceDidResolveAddress(_ service: NetService) {
        
        client?.log?("[\(service.domain)\(service.type)\(service.name)]: Did resolve")
        client?.internalState.resolveAddress.didResolve = true
    }
    
    public func netService(_ service: NetService, didNotResolve errorDict: [String : NSNumber]) {
        
        client?.log?("[\(service.domain)\(service.type)\(service.name)]: Did not resolve \(errorDict)")
        client?.internalState.resolveAddress.error = errorDict
    }
}

// MARK: - Private Types

private extension NetServiceClient {
    
    struct InternalState {
        
        var discoverServices = DiscoverServices()
        
        struct DiscoverServices {
            
            var services = [Service: NetService]()
            
            var foundService: ((Service) -> ())?
            
            var error: [String: NSNumber]?
        }
        
        var resolveAddress = ResolveAddress()
        
        struct ResolveAddress {
            
            var didResolve: Bool = false
            
            var error: [String: NSNumber]?
        }
    }
}

#endif
