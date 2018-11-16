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
    
    private var netServiceBrowser: NetServiceBrowser!
    
    private var internalState = InternalState()
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
    }
    
    // MARK: - Methods
    
    public func discoverServices(of type: NetServiceType,
                                 in domain: NetServiceDomain,
                                 shouldContinue: () -> Bool,
                                 foundService: @escaping (Service) -> ()) throws {
        
        netServiceBrowser = NetServiceBrowser()
        netServiceBrowser.delegate = self
        
        // remove previous results
        self.internalState.discoverServices.foundService = foundService
        self.internalState.discoverServices.services.removeAll(keepingCapacity: true)
        
        // perform search
        netServiceBrowser.searchForServices(ofType: type.rawValue, inDomain: domain.rawValue)
        
        // wait
        while shouldContinue() {
            RunLoop.current.run(until: Date() + 1.0)
        }
        
        netServiceBrowser.stop()
        RunLoop.current.run(until: Date() + 0.1)
        
        if let error = self.internalState.discoverServices.error {
            
            throw DarwinNetServiceClientError.notDiscoverServices(error)
        }
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
            throw DarwinNetServiceClientError.notResolveAddress(error)
        }
        
        // make sure the method did not timeout
        guard self.internalState.resolveAddress.didResolve || Date() < end
            else { throw NetServiceClientError.timeout }
        
        // return value
        return (netService.addresses ?? []).map { NetServiceAddress(data: $0) }
    }
}

// MARK: - Error

public enum DarwinNetServiceClientError: Error {
    
    case notDiscoverServices([String: NSNumber])
    case notResolveAddress([String: NSNumber])
}

// MARK: - NetServiceBrowserDelegate

@objc
extension DarwinNetServiceClient: NetServiceBrowserDelegate {
    
    public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        
        log?("Will search")
        
        self.internalState.discoverServices.error = nil
    }
    
    public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        
        log?("Did stop search")
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        
        log?("Did not search: \(errorDict)")
        
        self.internalState.discoverServices.error = errorDict
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: Foundation.NetService, moreComing: Bool) {
        
        log?("Did find service \(service.domain) \(service.type) \(service.name)" + (moreComing ? " (more coming)" : ""))
        
        service.delegate = self
        
        let value = Service(domain: NetServiceDomain(rawValue: service.domain)!,
                               type: NetServiceType(rawValue: service.type)!,
                               name: service.name)
        
        self.internalState.discoverServices.services[value] = service
        self.internalState.discoverServices.foundService?(value)
    }
}

// MARK: - NetServiceDelegate

@objc
extension DarwinNetServiceClient: NetServiceDelegate {
    
    public func netServiceWillResolve(_ service: Foundation.NetService) {
        
        log?("[\(service.domain)\(service.type)\(service.name)]: Will resolve")
        
        self.internalState.resolveAddress.didResolve = false
        self.internalState.resolveAddress.error = nil
    }
    
    public func netServiceDidResolveAddress(_ service: Foundation.NetService) {
        
        log?("[\(service.domain)\(service.type)\(service.name)]: Did resolve")
        
        self.internalState.resolveAddress.didResolve = true
    }
    
    public func netService(_ service: Foundation.NetService, didNotResolve errorDict: [String : NSNumber]) {
        
        log?("[\(service.domain)\(service.type)\(service.name)]: Did not resolve \(errorDict)")
        
        self.internalState.resolveAddress.error = errorDict
    }
}

// MARK: - Private Types

private extension DarwinNetServiceClient {
    
    struct InternalState {
        
        var discoverServices = DiscoverServices()
        
        struct DiscoverServices {
            
            var services = [Service: Foundation.NetService]()
            
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

internal extension NetServiceAddress {
    
    init(data: Data) {
        
        var socketAddress = sockaddr_storage()
        data.withUnsafeBytes { socketAddress = $0.pointee }
        
        switch Int32(socketAddress.ss_family) {
        
        case AF_INET:
            let ipv4 = withUnsafePointer(to: &socketAddress) {
                $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                    $0.pointee
                }
            }
            
            self.init(port: in_port_t(bigEndian: ipv4.sin_port),
                      address: .ipv4(NetServiceAddressIPv4(address: ipv4.sin_addr)))
            
        case AF_INET6:
            let ipv6 = withUnsafePointer(to: &socketAddress) {
                $0.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) {
                    $0.pointee
                }
            }
            
            self.init(port: in_port_t(bigEndian: ipv6.sin6_port),
                      address: .ipv6(NetServiceAddressIPv6(address: ipv6.sin6_addr)))
            
        default:
            fatalError()
        }
    }
}

#endif
