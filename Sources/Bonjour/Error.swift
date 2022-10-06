//
//  NetServiceError.swift
//  
//
//  Created by Alsey Coleman Miller on 10/5/22.
//

import Foundation

/// Net Service Error
public enum NetServiceError: Error {
    
    /// Operation timed out.
    case timeout
    
    /// Invalid / Unknown service specified.
    case invalidService(Service)
    
    #if os(macOS) || os(iOS) || canImport(NetService)
    case errorDictionary([String: NSNumber])
    #endif
}
