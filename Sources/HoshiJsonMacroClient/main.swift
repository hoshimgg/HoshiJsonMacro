import Foundation
import HoshiJsonMacro

@HoshiJson struct StructTest {
    @HSNoJson var intA = 0
    var int_b = 1
}

let a = StructTest(dict: [
    "int_a": 1,
    "int_b": 2
])

print(a)
