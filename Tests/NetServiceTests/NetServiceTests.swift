//
//  NetServiceTests.swift
//  PureSwift
//
//  Created by Alsey Coleman Miller on 11/5/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation
import XCTest
@testable import NetService

final class NetServiceTests: XCTestCase {
    
    static let allTests = [
        ("testExample", testExample),
        ]
    
    func testExample() {
        
    }
    
    #if os(macOS)
    
    func testDarwinClient() {
        
        let client = DarwinNetServiceClient()
        client.log = { print("NetService:", $0) }
        
        do {
            
            var services = Set<Service>()
            let end = Date() + 2.0
            try client.discoverServices(of: .http,
                                        in: .local,
                                        shouldContinue: { Date() < end },
                                        foundService: { services.insert($0) })
            
            for service in services {
                
                let addresses = try client.resolve(service, timeout: 10.0)
                
                addresses.forEach {
                    print(service.name, $0)
                }
            }
        }
        catch { XCTFail("\(error)") }
    }
    
    #endif
}
