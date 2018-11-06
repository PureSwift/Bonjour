//
//  NetService.swift
//  PureSwift
//
//  Created by Alsey Coleman Miller on 11/5/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation

/// Discovered Net Service
public struct NetService: Equatable, Hashable {
    
    public let domain: NetServiceDomain
    
    public let type: NetServiceType
    
    public let name: String
    
    
}
