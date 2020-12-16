//
//  NetServiceTests.swift
//  PureSwift
//
//  Created by Alsey Coleman Miller on 11/5/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation
import XCTest
@testable import Bonjour

final class BonjourTests: XCTestCase {
    
    static let allTests = [
        ("testIPv4Address", testIPv4Address),
        ("testInvalidIPv4Address", testInvalidIPv4Address),
        ("testIPv6Address", testIPv6Address),
        ("testInvalidIPv6Address", testInvalidIPv6Address),
        ("testAddressData", testAddressData),
        ("testClient", testClient)
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
            XCTAssertEqual(address, address)
            XCTAssertEqual(address.hashValue, address.hashValue)
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
            XCTAssertEqual(address, address)
            XCTAssertEqual(address.hashValue, address.hashValue)
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
    
    func testAddressData() {
        
        let addressData = [
            ("192.168.0.110:80",
             Data([16, 2, 0, 80, 192, 168, 0, 110, 0, 0, 0, 0, 0, 0, 0, 0])),
            ("fe80::9eae:d3ff:fe97:92c5:80",
             Data([28, 30, 0, 80, 0, 0, 0, 0, 254, 128, 0, 0, 0, 0, 0, 0, 158, 174, 211, 255, 254, 151, 146, 197, 5, 0, 0, 0])),
            ("192.168.100.72:445",
             Data([16, 2, 1, 189, 192, 168, 100, 72, 0, 0, 0, 0, 0, 0, 0, 0])),
            ("fe80::fddf:e4d3:eb46:2143:445",
             Data([28, 30, 1, 189, 0, 0, 0, 0, 254, 128, 0, 0, 0, 0, 0, 0, 253, 223, 228, 211, 235, 70, 33, 67, 10, 0, 0, 0]))
        ]
        
        for (string, data) in addressData {
            
            let address = NetServiceAddress(data: data)
            XCTAssertEqual(address.description, string)
        }
    }
            
    func testClient() {
        
        do {
            
            let client = NetServiceClient()
            client.log = { print("NetService:", $0) }
            
            var services = Set<Service>()
            let end = Date() + 1.0
            try client.discoverServices(of: .smb,
                                        in: .local,
                                        shouldContinue: { Date() < end },
                                        foundService: { services.insert($0) })
            
            for service in services {
                
                let addresses = try client.resolve(service, timeout: 10.0)
                
                if let hostName = client.hostName(for: service) {
                    print("Host Name:", hostName)
                }
                
                addresses.forEach {
                    print(service.name, $0)
                }
                
                if let txtRecord = client.txtRecord(for: service) {
                    print("TXT Record:", txtRecord)
                }
            }
        }
        catch { XCTFail("\(error)") }
    }
}
