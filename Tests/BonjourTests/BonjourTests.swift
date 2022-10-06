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
import Socket

final class BonjourTests: XCTestCase {
    
    #if os(macOS)
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
    #endif
            
    func testClient() async throws {
        
        // create browser
        let client = NetServiceManager()
        client.log = { print("NetService:", $0) }
        
        // start discovery
        let stream = client.discoverServices(of: .http, in: .local)
        Task {
            try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            stream.stop()
        }
        
        // store scanned services
        var services = Set<Service>()
        for try await service in stream {
            services.insert(service)
        }
        
        // resolve each
        for service in services {
            do {
                let addresses = try await client.resolve(service, timeout: 10.0)
                if let hostName = await client.hostName(for: service) {
                    print("Host Name:", hostName)
                }
                addresses.forEach {
                    print(service.name, $0)
                }
                if let txtRecord = await client.txtRecord(for: service) {
                    print("TXT Record:", txtRecord)
                }
            } catch {
                XCTFail(service.name + " " + error.localizedDescription)
            }
        }
    }
}
