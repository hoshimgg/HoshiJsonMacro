//
//  HSJsonObj.swift
//
//
//  Created by 星空凛 on 2024/8/9.
//

import Foundation

public struct HSJsonObj {
    private var value: Any?
}

extension HSJsonObj: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral, ExpressibleByStringLiteral, ExpressibleByBooleanLiteral {
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

extension HSJsonObj: ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral, ExpressibleByNilLiteral {
    public init(arrayLiteral elements: Any...) {
        self.value = elements
    }
    
    public init(dictionaryLiteral elements: (String, Any)...) {
        self.value = Dictionary(uniqueKeysWithValues: elements)
    }
    
    public init(nilLiteral: ()) { }
}

extension HSJsonObj: CustomStringConvertible, Equatable {
    public var description: String {
        return "\(value ?? "nil")"
    }
    
    public static func == (lhs: HSJsonObj, rhs: HSJsonObj) -> Bool {
        if let l = lhs.value as? Int, let r = rhs.value as? Int {
            return l == r
        } else if let l = lhs.value as? Double, let r = rhs.value as? Double {
            return l == r
        } else if let l = lhs.value as? String, let r = rhs.value as? String {
            return l == r
        } else if let l = lhs.value as? Bool, let r = rhs.value as? Bool {
            return l == r
        } else if let l = lhs.value as? [HSJsonObj], let r = rhs.value as? [HSJsonObj] {
            return l == r
        } else if let l = lhs.value as? [String:HSJsonObj], let r = rhs.value as? [String:HSJsonObj] {
            return l == r
        } else if lhs.value == nil && rhs.value == nil {
            return true
        } else {
            return false
        }
    }
}

extension HSJsonObj: Codable {
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
        } else if let v = try? container.decode([HSJsonObj].self) {
            value = v
        } else if let v = try? container.decode([String:HSJsonObj].self) {
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
        } else if let v = value as? [HSJsonObj] {
            try container.encode(v)
        } else if let v = value as? [String:HSJsonObj] {
            try container.encode(v)
        } else {
            try container.encodeNil()
        }
    }
}
