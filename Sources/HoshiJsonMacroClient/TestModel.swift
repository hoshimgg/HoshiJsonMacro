//
//  TestModel.swift
//
//
//  Created by 星空凛 on 2024/8/5.
//

import Foundation
import HoshiJsonMacro

public class MDEntity {
    public var description: String {
        return "MDEntity"
    }
}

@HoshiJson
struct StructTest {
    @HSNoEqual var intA = 0
    var int_b = 1
    var intID: Int? = 4
//    var bizExtraData: [String:Codable] = [:]
}

@HoshiJson
class ClassTestA {
    var strA = "defaultStrA"
    var str_b: String?
    var structA = StructTest()
    var struct_b: StructTest?
    var intB: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case strA = "str_a", str_b = "str_b", structA = "struct_a", struct_b = "struct_b"
        case intB = "int_b"
    }
}

@HoshiJson
class ClassTestB {
    @HSJson("int_a") var customIntA = 0
    @HSJson("intB") var customInt_b = 1
    @HSNoEqual var intC = 2
    var intD: Int? = 0
}

@HoshiJson
class ClassTestC: MDEntity {
    var intA = 4
}
