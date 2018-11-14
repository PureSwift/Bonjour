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
    
    public static var http = NetServiceType("_http._tcp.")
    
    public static var ssh = NetServiceType("_ssh._tcp.")
    
    public static var samba = NetServiceType("_smb._tcp.")
    
    public static var sftp = NetServiceType("_sftp._tcp.")
    
    public static var rfb = NetServiceType("_rfb._tcp.")
    
    public static var printer = NetServiceType("_printer._tcp.")
    
    public static var scanner = NetServiceType("_scanner._tcp.")
    
    public static var itunesSharing = NetServiceType("_daap._tcp.")
}
