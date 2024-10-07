import Foundation
import HoshiJsonMacro

@HoshiJson class Test1 {
    var testDict: HSJsonObj = nil
}

let test1 = Test1(jsonStr: """
{
    "test_dict1": {
        "key1": "value1",
        "key2": "value2"
    }
}
""")

let temp1 = test1.testDict.toDict
print(temp1)
