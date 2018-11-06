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

@objc public final class DarwinNetServiceClient: NSObject, NetServiceClient {
    
    // MARK: - Properties
    
    public var log: ((String) -> ())?
    
    internal lazy var netServiceBrowser: NetServiceBrowser = {
        let netServiceBrowser = NetServiceBrowser()
        netServiceBrowser.delegate = self
        return netServiceBrowser
    }()
    
    private var discoveredServices = [NetService: Foundation.NetService]()
    
    // MARK: - Initialization
    
    public override init() {
        
        super.init()
    }
    
    // MARK: - Methods
    
    public func discoverServices(of type: NetServiceType,
                                 in domain: NetServiceDomain,
                                 shouldContinue: () -> Bool,
                                 service: (NetService) -> ()) throws {
        
        // remove previous results for domain and type
        discoveredServices = discoveredServices.filter {
            $0.key.type == type && $0.key.domain == domain
        }
        
        // perform search
        netServiceBrowser.searchForServices(ofType: type.rawValue, inDomain: domain.rawValue)
        
        // wait
        while shouldContinue() {
            sleep(1)
        }
        
        netServiceBrowser.stop()
        
        // return results
        /*
        return Array(
            discoveredServices
            .filter { $0.key.type == type && $0.key.domain == domain }
            .keys
        )*/
    }
    
    public func resolve(_ service: NetService, timeout: TimeInterval) throws -> [String] {
        
        precondition(timeout > 0.0, "Cannot indefinitely resolve")
        
        guard let netService = discoveredServices[service]
            else { throw NetServiceClientError.invalidService(service) }
        
        netService.resolve(withTimeout: timeout)
    }
}

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
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        
        log?("Did remove domain \(domainString)" + (moreComing ? " (more coming)" : ""))
        
        
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: Foundation.NetService, moreComing: Bool) {
        
        log?("Did remove service \(service.domain) \(service.type) \(service.name)" + (moreComing ? " (more coming)" : ""))
        
        
    }
}

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

#endif
