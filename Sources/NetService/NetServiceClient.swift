//
//  NetServiceClient.swift
//  NetService
//
//  Created by Alsey Coleman Miller on 11/5/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation

/// Bonjour Net Service Client
public protocol NetServiceClient: class {
    
    /// Discover services of the specified type in the specified domain.
    func discoverServices(of type: NetServiceType,
                          in domain: NetServiceDomain,
                          shouldContinue: () -> Bool,
                          foundService: @escaping (NetService) -> ()) throws
    
    /// Resolve the address of the specified net service.
    func resolve(_ service: NetService, timeout: TimeInterval) throws -> [NetServiceAddress]
}

/// Net Service Error
public enum NetServiceClientError: Error {
    
    /// Operation timed out.
    case timeout
    
    /// Invalid / Unknown service specified.
    case invalidService(NetService)
}

