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
#else
import Glibc
#endif

public struct NetServiceAddress: Equatable, Hashable {
    
    public let port: UInt16
    
    public let address: Address
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

public struct NetServiceAddressIPv4: NetServiceAddressProtocol {
    
    public let address: in_addr
    
    public init(address: in_addr) {
        
        self.address = address
    }
}

extension NetServiceAddressIPv4: RawRepresentable {
    
    public init?(rawValue: String) {
        
        
    }
}

extension NetServiceAddressIPv4: CustomStringConvertible {
    
    public var description: String {
        
        //return String(cString: inet_ntoa(address.sin_addr), encoding: .ascii)!
        
        var output = Data(count: Int(INET_ADDRSTRLEN))
        var address = self.address
        guard let presentationBytes = output.withUnsafeMutableBytes({
            inet_ntop(AF_INET, &address, $0, socklen_t(INET_ADDRSTRLEN))
        }) else {
            fatalError("Invalid IPv4 address")
        }
        
        return String(cString: presentationBytes)
    }
}

internal protocol InternetAddress {
    
    static var stringLength: Int { get }
    
    static var addressFamily: sa_family_t { get }
}

extension InternetAddress {
    
    var presentationString: String {
        
        var output = Data(count: Int(type(of: self).stringLength))
        var address = self
        guard let presentationBytes = output.withUnsafeMutableBytes({
            inet_ntop(Int32(type(of: self).addressFamily),
                      &address,
                      $0,
                      socklen_t(type(of: self).stringLength))
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

public struct NetServiceAddressIPv6: NetServiceAddressProtocol {
    
    public let address: sockaddr_in6
    
    public init(address: sockaddr_in6) {
        
        self.address = address
    }
}

public extension NetServiceAddressIPv4 {
    
    public init?(data: Data) {
        
        guard data.count == MemoryLayout<sockaddr_storage>.size
            else { return nil }
        
        var socketAddress = sockaddr_storage()
        data.withUnsafeBytes { socketAddress = $0.pointee }
        
        guard socketAddress.ss_family == AF_INET
            else { return nil }
        
        let address = withUnsafePointer(to: &socketAddress) {
            $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                $0.pointee
            }
        }
        
        self.init(address: address)
    }
}
