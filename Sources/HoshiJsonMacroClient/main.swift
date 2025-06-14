import Foundation
import HoshiJsonMacro

@HoshiJson class TestClassA {
    var testA: Int64 = 1
}

let dict = ["test_a": "2"]

let a = TestClassA(dict: dict)
print(a)
