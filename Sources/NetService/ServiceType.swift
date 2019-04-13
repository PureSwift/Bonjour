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
    
    public init?(rawValue: String) {
        
        guard rawValue.isEmpty == false,
            rawValue.hasSuffix(".")
            else { return nil }
        
        self.rawValue = rawValue
    }
    
    private init(_ unsafe: String) {
        assert(NetServiceType(rawValue: unsafe) != nil)
        self.rawValue = unsafe
    }
}

public extension NetServiceType {
    
    static let http = NetServiceType("_http._tcp.")
    static let ssh = NetServiceType("_ssh._tcp.")
    static let samba = NetServiceType("_smb._tcp.")
    static let sftp = NetServiceType("_sftp._tcp.")
    static let rfb = NetServiceType("_rfb._tcp.")
    static let printer = NetServiceType("_printer._tcp.")
    static let scanner = NetServiceType("_scanner._tcp.")
    static let itunesSharing = NetServiceType("_daap._tcp.")
}
