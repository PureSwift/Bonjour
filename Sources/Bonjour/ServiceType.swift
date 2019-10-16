//
//  NetServiceType.swift
//  NetService
//
//  Created by Alsey Coleman Miller on 11/5/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation

/// Net Service Type
public struct NetServiceType: RawRepresentable, Equatable, Hashable {
    
    public let rawValue: String
    
    public init(rawValue: String) {
        
        assert(rawValue.isEmpty == false)
        assert(rawValue.hasSuffix("."))
        
        self.rawValue = rawValue
    }
}

// MARK: - CustomStringConvertible

extension NetServiceType: CustomStringConvertible {
    
    public var description: String {
        return rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension NetServiceType: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

// MARK: - Net Service Types

public extension NetServiceType {
    
    /// HTTP Server
    static let http = NetServiceType("_http._tcp.")
    
    /// SSH Remote Login Protocol
    static let ssh = NetServiceType("_ssh._tcp.")
    
    /// Server Message Block over TCP/IP
    static let smb = NetServiceType("_smb._tcp.")
    
    /// Secure File Transfer Protocol
    static let sftp = NetServiceType("_sftp._tcp.")
    
    /// Secure File Transfer Protocol over SSH
    static let sftpSSH = NetServiceType("_sftp-ssh._tcp.")
    
    /// RTB
    static let rfb = NetServiceType("_rfb._tcp.")
    
    /// Printer
    static let printer = NetServiceType("_printer._tcp.")
    
    /// Scanner
    static let scanner = NetServiceType("_scanner._tcp.")
    
    /// Device Info
    static let deviceInfo = NetServiceType("_device-info._tcp.")
    
    /// iTunes Sharing
    static let iTunesSharing = NetServiceType("_daap._tcp.")
    
    /// HomeKit Accessory Protocol
    static let homeKitAccessory = NetServiceType("_hap._tcp.")
    
    /// HomeKit Hub
    static let homeKit = NetServiceType("_homekit._tcp.")
    
    /// Companion Link
    static let companionLink = NetServiceType("_companion-link._tcp.")
}
