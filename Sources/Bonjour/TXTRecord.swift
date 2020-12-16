//
//  TXTRecord.swift
//  
//
//  Created by Alsey Coleman Miller on 12/15/20.
//

import Foundation

/// TXT Record
public struct TXTRecord: Equatable, Hashable {
    
    public var data: Data
    
    public init(data: Data) {
        self.data = data
    }
}

public extension TXTRecord {
    
    /// Initializes a TXT record formed from a given dictionary.
    ///
    /// - Parameter dictionary: A dictionary containing a TXT record.
    init(dictionary: [String: String]) {
        self.init(data: dictionary.reduce(Data(), {
            let attr = "\($1.key)=" + $1.value
            return $0 + Data([UInt8(attr.count)]) + Data(attr.utf8)
        }))
    }
    
    subscript (key: String) -> String? {
        return parse()[key]
    }
    
    /// Returns a dictionary representing a TXT record.
    func parse() -> [String: String] {
        var txtDictionary: [String: String] = [:]
        var position = 0
        while position < data.count {
            let size = Int(data[position])
            position += 1
            if position + size >= data.count { break }
            guard let label = String(bytes: data[position..<position+size], encoding: .utf8) else { break }
            position += size
            let parts = label.split(separator: "=", maxSplits: 1)
            assert(parts.count == 2, "Only key=value parts are supported")
            txtDictionary[String(parts[0])] = String(parts[1])
        }
        return txtDictionary
    }
}

// MARK: - CustomStringConvertible

extension TXTRecord: CustomStringConvertible {
    
    public var description: String {
        let dictionary = parse()
        return dictionary.isEmpty ? data.description : dictionary.description
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension TXTRecord: ExpressibleByDictionaryLiteral {
    
    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(dictionary: .init(uniqueKeysWithValues: elements))
    }
}
