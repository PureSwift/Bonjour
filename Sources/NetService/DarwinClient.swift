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
        
        // remove previous results for domain and type
        self.internalState.discoverServices.foundService = foundService
        self.internalState.discoverServices.services = self.internalState.discoverServices.services
            .filter { ($0.key.type == type && $0.key.domain == domain) == false }
        
        // perform search
        netServiceBrowser.searchForServices(ofType: type.rawValue, inDomain: domain.rawValue)
        
        // wait
        while shouldContinue() {
            RunLoop.current.run(until: Date() + 1.0)
        }
        
        netServiceBrowser.stop()
    }
    
    public func resolve(_ service: Service, timeout: TimeInterval) throws -> [NetServiceAddress] {
        
        precondition(timeout > 0.0, "Cannot indefinitely resolve")
        
        guard let netService = self.internalState.discoverServices.services[service]
            else { throw NetServiceClientError.invalidService(service) }
        
        self.internalState.resolveAddress.didResolve = false
        
        // perform action
        netService.resolve(withTimeout: timeout)
        
        // run loop
        let end = Date() + timeout
        while Date() < end && self.internalState.resolveAddress.didResolve == false {
            RunLoop.current.run(until: Date() + 1.0)
        }
        
        // make sure the method did not timeout
        guard self.internalState.resolveAddress.didResolve || Date() < end
            else { throw NetServiceClientError.timeout }
        
        // return value
        return (netService.addresses ?? []).map { NetServiceAddress(data: $0) }
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
        
        let value = Service(domain: NetServiceDomain(rawValue: service.domain)!,
                               type: NetServiceType(rawValue: service.type)!,
                               name: service.name)
        
        self.internalState.discoverServices.services[value] = service
        self.internalState.discoverServices.foundService?(value)
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
        
        self.internalState.resolveAddress.didResolve = true
    }
    
    public func netService(_ service: Foundation.NetService, didNotResolve errorDict: [String : NSNumber]) {
        
        log?("[\(service.domain)\(service.type)\(service.name)]: Did not resolve \(errorDict)")
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
            
            var services = [Service: Foundation.NetService]()
            
            var foundService: ((Service) -> ())?
        }
        
        var resolveAddress = ResolveAddress()
        
        struct ResolveAddress {
            
            var didResolve: Bool = false
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
            
            self.init(port: ipv4.sin_port, address: .ipv4(NetServiceAddressIPv4(address: ipv4.sin_addr)))
            
        case AF_INET6:
            let ipv6 = withUnsafePointer(to: &socketAddress) {
                $0.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) {
                    $0.pointee
                }
            }
            
            self.init(port: ipv6.sin6_port, address: .ipv6(NetServiceAddressIPv6(address: ipv6.sin6_addr)))
            
        default:
            fatalError()
        }
    }
}

#endif
