import HoshiJsonMacro
import Foundation

public class MDEntity {
    public var description: String {
        return "MDEntity"
    }
}

@HoshiJson
struct StructTest {
    var intA = 0
    var int_b = 1
    var intID: Int?
}

@HoshiJson
class ClassTestA {
    var strA = "defaultStrA"
    var str_b: String?
    var structA = StructTest()
    var struct_b: StructTest?
}

@HoshiJson
class ClassTestB {
    var customIntA = 2
    var customInt_b = 3
    
    enum CodingKeys: String, CodingKey {
        case customIntA = "int_a"
        case customInt_b = "intB"
    }
}

@HoshiJson
class ClassTestC: MDEntity {
    var intA = 4
}

// MARK: -

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
])

center.onDataChannel(cmd: "ClassC", dict: [:])
