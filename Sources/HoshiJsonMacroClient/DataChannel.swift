//
//  DataChannel.swift
//
//
//  Created by 星空凛 on 2024/8/5.
//

import Foundation

class Biz {
    init(_ center: Center) {
        center.observerDC(cmd: "Struct", cn: "Struct", lifeFlag: self, class: StructTest.self) { obj in
            print(obj)
            // StructTest(intA: 11, int_b: 12, intID: Optional(13))
        }
        
        center.observerDC(cmd: "ClassA", cn: "ClassA", lifeFlag: self, class: ClassTestA.self) { obj in
            print(obj)
            // ClassTestA(strA: defaultStrA, str_b: nil, structA: StructTest(intA: 0, int_b: 1, intID: nil), struct_b: Optional(HoshiJsonMacroClient.StructTest(intA: 0, int_b: 22, intID: Optional(23))))
        }
        
        center.observerDC(cmd: "ClassB", cn: "ClassB", lifeFlag: self, class: ClassTestB.self) { obj in
            print(obj)
            // ClassTestB(customIntA: 31, customInt_b: 32)
        }
        
        center.observerDC(cmd: "ClassC", cn: "ClassC", lifeFlag: self, class: ClassTestC.self) { obj in
            print(obj, obj.intA)
            // HoshiJsonMacroClient.ClassTestC 4
        }
    }
}

func testDataChannel() {
    let center = Center()
    let biz = Biz(center)
    
    center.onDataChannel(cmd: "Struct", dict: [
        "int_a": 11,
        "int_b": 12,
        "int_id": 13,
    ])
    
    center.onDataChannel(cmd: "ClassA", jsonStr: """
    {
        "struct_b": {
            "int_b": 22,
            "int_id": 23,
        }
    }
    """)
    
    center.onDataChannel(cmd: "ClassB", dict: [
        "int_a": 31,
        "intB": 32,
        "int_c": 33,
        "int_d": 34,
    ])
    
    center.onDataChannel(cmd: "ClassC", dict: [:])
}

