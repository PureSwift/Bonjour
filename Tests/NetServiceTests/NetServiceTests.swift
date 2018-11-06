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
        ("testIPv4Address", testIPv4Address),
        ]
    
    func testIPv4Address() {
        
        let strings = [
            "192.168.0.110"
        ]
        
        for string in strings {
            
            guard let address = NetServiceAddressIPv4(rawValue: string)
                else { XCTFail("Invalid string \(string)"); return }
            
            XCTAssertEqual(address.description, string)
        }
    }
    
    func testInvalidIPv4Address() {
        
        let strings = [
            "",
            "fe80::9eae:d3ff:fe97:92c5",
            "192.168.0.110."
        ]
        
        strings.forEach { XCTAssertNil(NetServiceAddressIPv4(rawValue: $0)) }
    }
    
    func testIPv6Address() {
        
        let strings = [
            "fe80::9eae:d3ff:fe97:92c5"
        ]
        
        for string in strings {
            
            guard let address = NetServiceAddressIPv6(rawValue: string)
                else { XCTFail("Invalid string \(string)"); return }
            
            XCTAssertEqual(address.description, string)
        }
    }
    
    func testInvalidIPv6Address() {
        
        let strings = [
            "",
            ":9eae:d3ff:fe97:92c5",
            "192.168.0.110"
        ]
        
        strings.forEach { XCTAssertNil(NetServiceAddressIPv6(rawValue: $0)) }
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
