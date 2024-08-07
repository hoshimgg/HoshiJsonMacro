import Foundation
import HoshiJsonMacro

@HoshiJson class ClassTestD {
    var bizExtraData: [String:HSJsonObj] = [:]
}

let d1 = ClassTestD(dict: [
    "biz_extra_data": [
        "int": 1,
        "double": 2.1,
        "str": "abc",
        "bool": true,
        "nil": nil,
        "array": [1, 2, 3],
        "dict": ["int": 4, "double": 5.1, "str": "def", "bool": false, "nil": nil, "array": [4, 5, 6]],
    ]
])
let d2 = ClassTestD(dict: [
    "biz_extra_data": [
        "int": 1,
        "double": 2.1,
        "str": "abc",
        "bool": true,
        "nil": nil,
        "array": [1, 2, 3],
        "dict": ["int": 4, "double": 5.2, "str": "def", "bool": false, "nil": nil, "array": [4, 5, 6]],
    ]
])
print(d1 == d2)
