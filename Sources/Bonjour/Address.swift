//
//  Address.swift
//  NetService
//
//  Created by Alsey Coleman Miller on 11/6/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(Android)
import Glibc
#endif
import Socket

/// Net Service Address
public struct NetServiceAddress: Equatable, Hashable {
    
    /// Network address.
    public let address: IPAddress
    
    /// Network port.
    public let port: UInt16
    
    internal init(address: IPAddress, port: UInt16) {
        
        self.port = port
        self.address = address
    }
}

extension NetServiceAddress: CustomStringConvertible {
    
    public var description: String {
        return address.description + ":" + port.description
    }
}

// MARK: - Data

internal extension NetServiceAddress {
    
    init(data: Data) {
        
        var socketAddress = data.withUnsafeBytes { $0.bindMemory(to: sockaddr_storage.self).baseAddress!.pointee }
        let family = sa_family_t(socketAddress.ss_family)
        
        switch family {
        case sa_family_t(AF_INET):
            let ipv4 = withUnsafePointer(to: &socketAddress) {
                $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                    $0.pointee
                }
            }
            
            self.init(address: .v4(IPv4Address(ipv4.sin_addr)), port: in_port_t(bigEndian: ipv4.sin_port))
            
        case sa_family_t(AF_INET6):
            let ipv6 = withUnsafePointer(to: &socketAddress) {
                $0.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) {
                    $0.pointee
                }
            }
            
            self.init(address: .v6(IPv6Address(ipv6.sin6_addr)), port: in_port_t(bigEndian: ipv6.sin6_port))
            
        default:
            fatalError("Invalid address family: \(family)")
        }
    }
}
