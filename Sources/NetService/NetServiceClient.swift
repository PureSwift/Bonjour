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
                          timeout: TimeInterval) throws -> [NetService]
    
    /// Resolve the address of the specified net service.
    func resolve(_ service: NetService) throws -> [String]
}

/// Net Service Error
public enum NetServiceClientError: Error {
    
    /// Invalid / Unknown service specified.
    case invalidService(NetService)
}

