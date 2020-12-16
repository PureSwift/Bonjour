//
//  NetServiceClient.swift
//  NetService
//
//  Created by Alsey Coleman Miller on 11/5/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation

/// Bonjour Net Service Client
public protocol NetServiceClientProtocol: class {
    
    /// Discover services of the specified type in the specified domain.
    func discoverServices(of type: NetServiceType,
                          in domain: NetServiceDomain,
                          foundService: @escaping (Service) -> ()) throws
    
    /// Stop service discovery.
    func stopDiscovery()
    
    /// Resolve the address of the specified net service.
    func resolve(_ service: Service, timeout: TimeInterval) throws -> [NetServiceAddress]
}

public extension NetServiceClientProtocol {
    
    @available(*, deprecated)
    func discoverServices(
        of type: NetServiceType,
        in domain: NetServiceDomain,
        shouldContinue: @escaping () -> Bool,
        foundService: @escaping (Service) -> ()) throws {
                
        DispatchQueue.global().async { [weak self] in
            while shouldContinue() {
                sleep(1)
            }
            self?.stopDiscovery()
        }
        
        try discoverServices(of: type, in: domain, foundService: foundService)
    }
}

/// Net Service Error
public enum NetServiceClientError: Error {
    
    /// Operation timed out.
    case timeout
    
    /// Invalid / Unknown service specified.
    case invalidService(Service)
    
    #if os(macOS) || os(iOS) || canImport(NetService)
    
    ///
    case notDiscoverServices([String: NSNumber])
    
    ///
    case notResolveAddress([String: NSNumber])
    #endif
}

