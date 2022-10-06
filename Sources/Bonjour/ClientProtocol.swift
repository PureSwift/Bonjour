//
//  NetServiceClient.swift
//  NetService
//
//  Created by Alsey Coleman Miller on 11/5/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation

/// Bonjour Net Service Client
public protocol NetServiceManagerProtocol: AnyObject {
    
    /// Discover services of the specified type in the specified domain.
    /// Starts a search for services of a particular type within a specific domain.
    func discoverServices(
        of type: NetServiceType,
        in domain: NetServiceDomain
    ) -> AsyncNetServiceDiscovery<Self>
    
    /// Fetch the TXT record data for the specified service.
    ///
    /// - Parameter service: The service for which cached TXT record will be fetched.
    func txtRecord(for service: Service) async -> TXTRecord?
    
    /// Resolve the address of the specified net service.
    func resolve(_ service: Service, timeout: TimeInterval) async throws -> Set<NetServiceAddress>
    
    /// A string containing the DNS hostname for the specified service.
    ///
    /// - Parameter service: The service for which cached host name will be looked up.
    ///
    /// - Note: This value is `nil` until the service has been resolved (when addresses is `non-nil`).
    func hostName(for service: Service) async -> String?
}
