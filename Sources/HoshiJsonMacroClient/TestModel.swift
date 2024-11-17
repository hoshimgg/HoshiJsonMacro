//
//  TestModel.swift
//
//
//  Created by 星空凛 on 2024/8/5.
//

import Foundation
import HoshiJsonMacro

public class MDEntity: NSObject { }

@HoshiJson
struct StructTestA {
    @HSNoEqual var intA: Int = 0
    var int_b = 1
    var intID: Int? = 2
    var bizExtraData: [String:HSJsonObj] = ["3":3]
    var width: Double = 4
    var jsonObj: HSJsonObj = 5
}

@HoshiJson
class ClassTestA {
    var strA = "defaultStrA"
    var str_b: String?
    var structA = StructTestA()
    var struct_b: StructTestA?
    var intB: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case strA = "str_a", str_b = "str_b", structA = "struct_a", struct_b = "struct_b"
        case intB = "int_b"
    }
}

@HoshiJson
@objcMembers class ClassTestB: NSObject {
    @HSJson("int_a") var customIntA = 0
    @HSJson("intB") var customInt_b = 1
    @HSNoEqual var intC = 2
    var intD: Int? = 0
}

@HoshiJson
class ClassTestC: MDEntity {
    var intA: Int = 4
}
