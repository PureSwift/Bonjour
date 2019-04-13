//
//  NetServiceDomain.swift
//  NetService
//
//  Created by Alsey Coleman Miller on 11/5/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation

/// Net Service Domain
public struct NetServiceDomain: RawRepresentable, Equatable, Hashable {
    
    public let rawValue: String
    
    public init?(rawValue: String) {
        
        guard rawValue.isEmpty == false
            else { return nil }
        
        self.rawValue = rawValue
    }
    
    private init(_ unsafe: String) {
        assert(NetServiceDomain(rawValue: unsafe) != nil)
        self.rawValue = unsafe
    }
}

public extension NetServiceDomain {
    
    static let local = NetServiceDomain("local.")
}
