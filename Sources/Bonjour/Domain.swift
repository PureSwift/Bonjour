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
    
    public init(rawValue: String) {
        
        assert(rawValue.isEmpty == false)
        self.rawValue = rawValue
    }
}

public extension NetServiceDomain {
    
    static let local: NetServiceDomain = "local."
}

// MARK: - CustomStringConvertible

extension NetServiceDomain: CustomStringConvertible {
    
    public var description: String {
        return rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension NetServiceDomain: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}
