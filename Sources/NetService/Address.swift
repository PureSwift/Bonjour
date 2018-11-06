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

public struct NetServiceAddress: Equatable, Hashable {
    
    public let port: UInt16
    
    public let address: Address
    
    public init(port: UInt16, address: Address) {
        
        self.port = port
        self.address = address
    }
}

extension NetServiceAddress: CustomStringConvertible {
    
    public var description: String {
        
        return address.description + ":" + port.description
    }
}

public extension NetServiceAddress {
    
    public enum Address: Equatable, Hashable {
        
        case ipv4(NetServiceAddressIPv4)
        case ipv6(NetServiceAddressIPv6)
    }
}

extension NetServiceAddress.Address: CustomStringConvertible {
    
    public var description: String {
        
        switch self {
        case let .ipv4(address): return address.description
        case let .ipv6(address): return address.description
        }
    }
}

public extension NetServiceAddress {
    
    public init?(data: Data) {
        
        guard data.count == MemoryLayout<sockaddr_storage>.size
            else { return nil }
        
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

public protocol NetServiceAddressProtocol {
    
    associatedtype SocketAddress
    
    init(address: SocketAddress)
    
    var address: SocketAddress { get }
}

public struct NetServiceAddressIPv4: NetServiceAddressProtocol, Equatable {
    
    public let address: in_addr
    
    public init(address: in_addr) {
        
        self.address = address
    }
}

extension NetServiceAddressIPv4: RawRepresentable {
    
    public init?(rawValue: String) {
        
        guard let address = SocketAddress(rawValue)
            else { return nil }
        
        self.address = address
    }
    
    public var rawValue: String {
        
        return address.presentation
    }
}

extension NetServiceAddressIPv4: CustomStringConvertible {
    
    public var description: String {
        
        return rawValue
    }
}

extension NetServiceAddressIPv4: Hashable {
    
    public var hashValue: Int {
        
        return unsafeBitCast(address, to: UInt32.self).hashValue
    }
}

public struct NetServiceAddressIPv6: NetServiceAddressProtocol {
    
    public let address: in6_addr
    
    public init(address: in6_addr) {
        
        self.address = address
    }
}

extension NetServiceAddressIPv6: RawRepresentable, Equatable {
    
    public init?(rawValue: String) {
        
        guard let address = SocketAddress(rawValue)
            else { return nil }
        
        self.address = address
    }
    
    public var rawValue: String {
        
        return address.presentation
    }
}

extension NetServiceAddressIPv6: CustomStringConvertible {
    
    public var description: String {
        
        return rawValue
    }
}

extension NetServiceAddressIPv6: Hashable {
    
    public var hashValue: Int {
        
        let bit128Value = unsafeBitCast(address, to: uuid_t.self)
        
        return UUID(uuid: bit128Value).hashValue
    }
}

internal protocol InternetAddress {
    
    static var stringLength: Int { get }
    
    static var addressFamily: sa_family_t { get }
    
    init()
}

extension InternetAddress {
    
    init?(_ presentation: String) {
        
        var address = Self.init()
        
        /**
         inet_pton() returns 1 on success (network address was successfully converted). 0 is returned if src does not contain a character string representing a valid network address in the specified address family. If af does not contain a valid address family, -1 is returned and errno is set to EAFNOSUPPORT.
        */
        guard inet_pton(Int32(Self.addressFamily), presentation, &address) == 1
            else { return nil }
        
        self = address
    }
    
    var presentation: String {
        
        var output = Data(count: Int(Self.stringLength))
        var address = self
        guard let presentationBytes = output.withUnsafeMutableBytes({
            inet_ntop(Int32(Self.addressFamily),
                      &address,
                      $0,
                      socklen_t(Self.stringLength))
        }) else {
            fatalError("Invalid IPv4 address")
        }
        
        return String(cString: presentationBytes)
    }
}

extension in_addr: InternetAddress {
    
    static var stringLength: Int { return Int(INET_ADDRSTRLEN) }
    
    static var addressFamily: sa_family_t { return sa_family_t(AF_INET) }
}

extension in6_addr: InternetAddress {
    
    static var stringLength: Int { return Int(INET6_ADDRSTRLEN) }
    
    static var addressFamily: sa_family_t { return sa_family_t(AF_INET6) }
}
