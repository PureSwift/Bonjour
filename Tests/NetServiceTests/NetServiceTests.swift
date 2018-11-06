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
        ("testInvalidIPv4Address", testInvalidIPv4Address),
        ("testIPv6Address", testIPv6Address),
        ("testInvalidIPv6Address", testInvalidIPv6Address)
        ]
    
    func testIPv4Address() {
        
        let strings = [
            "127.0.0.1",
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
    
    func testDarwinAddressData() {
        
        let addressData = [
            ("192.168.0.110:20480",
             Data([16, 2, 0, 80, 192, 168, 0, 110, 0, 0, 0, 0, 0, 0, 0, 0])),
            ("fe80::9eae:d3ff:fe97:92c5:20480",
             Data([28, 30, 0, 80, 0, 0, 0, 0, 254, 128, 0, 0, 0, 0, 0, 0, 158, 174, 211, 255, 254, 151, 146, 197, 5, 0, 0, 0]))
        ]
        
        for (string, data) in addressData {
            
            let address = NetServiceAddress(data: data)
            XCTAssertEqual(address.description, string)
        }
    }
    
    func testDarwinClient() {        
        
        do {
            
            let client = DarwinNetServiceClient()
            client.log = { print("NetService:", $0) }
            
            var services = Set<Service>()
            let end = Date() + 1.0
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
