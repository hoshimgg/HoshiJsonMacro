import Foundation
import HoshiJsonMacro

@HoshiJson class StructA {
    var a: Int = 0
    var b: Bool = false
    var c: String = ""
    var d: Double = 0
}

let a = StructA(jsonStr: """
    {"a": true, "b": 1, "c": "c", "d": true}
""")
print(a)
