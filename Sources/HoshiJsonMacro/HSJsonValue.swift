//
//  HSJsonValue.swift
//
//
//  Created by 星空凛 on 2024/8/9.
//

import Foundation

public struct HSJsonValue {
    private var value: Any?
}

extension HSJsonValue: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral, ExpressibleByStringLiteral, ExpressibleByBooleanLiteral {
    public init(integerLiteral value: Int) {
        self.value = value
    }
    
    public init(floatLiteral value: Double) {
        self.value = value
    }
    
    public init(stringLiteral value: String) {
        self.value = value
    }
    
    public init(booleanLiteral value: Bool) {
        self.value = value
    }
}

extension HSJsonValue: ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral, ExpressibleByNilLiteral {
    public init(arrayLiteral elements: Any...) {
        self.value = elements
    }
    
    public init(dictionaryLiteral elements: (String, Any)...) {
        self.value = Dictionary(uniqueKeysWithValues: elements)
    }
    
    public init(nilLiteral: ()) { }
}

extension HSJsonValue: CustomStringConvertible, Equatable {
    public var description: String {
        return "\(value ?? "nil")"
    }
    
    public static func == (lhs: HSJsonValue, rhs: HSJsonValue) -> Bool {
        return false // TODO: 补充
    }
}

extension HSJsonValue: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Int.self) {
            value = v
        } else if let v = try? container.decode(Double.self) {
            value = v
        } else if let v = try? container.decode(String.self) {
            value = v
        } else if let v = try? container.decode(Bool.self) {
            value = v
        } else if let v = try? container.decode([HSJsonValue].self) {
            value = v
        } else if let v = try? container.decode([String:HSJsonValue].self) {
            value = v
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        if let v = value as? Int {
            try container.encode(v)
        } else if let v = value as? Double {
            try container.encode(v)
        } else if let v = value as? String {
            try container.encode(v)
        } else if let v = value as? Bool {
            try container.encode(v)
        } else if let v = value as? [HSJsonValue] {
            try container.encode(v)
        } else if let v = value as? [String:HSJsonValue] {
            try container.encode(v)
        } else {
            try container.encodeNil()
        }
    }
}
