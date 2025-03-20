import Foundation
import HoshiJsonMacro



// MARK: ------

class TestClassB: Codable {
    @HSJson("custom_a") var testA = 1
    var testB: String? = nil
    var testC = [1, 3, 5]
    @HSNoEqual var testD: Bool? = true
    var testE: [String: String] = [:]
    
    enum CodingKeys: String, CodingKey {
        case testA = "custom_a"
        case testB = "test_b"
        case testC = "test_c"
        case testD = "test_d"
        case testE = "test_e"
    }
    
    public required init(from decoder: Decoder) {
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        if let v = try? container?.decodeIfPresent(Int.self, forKey: .testA) {
            self.testA = v
        } else if let v = try? container?.decodeIfPresent(Bool.self, forKey: .testA) {
            self.testA = v ? 1 : 0
        }
        self.testB = (try? container?.decodeIfPresent(type(of: testB), forKey: .testB)) ?? testB
        self.testC = (try? container?.decodeIfPresent(type(of: testC), forKey: .testC)) ?? testC
        if let v = try? container?.decodeIfPresent(Bool.self, forKey: .testD) {
            self.testD = v
        } else if let v = try? container?.decodeIfPresent(Int.self, forKey: .testD) {
            self.testD = v > 0
        }
        self.testE = (try? container?.decodeIfPresent(type(of: testE), forKey: .testE)) ?? testE
        
    }
    
    public var jsonString: String {
        guard let data = try? JSONEncoder().encode(self) else { return "序列化错误" }
        return String(data: data, encoding: .utf8) ?? "序列化错误"
    }
    
    public var toDict: [String:Any] {
        guard let data = try? JSONEncoder().encode(self) else { return ["error": "序列化错误"] }
        return (try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]) ?? ["error": "序列化错误"]
    }
}

let time3 = Date().timeIntervalSince1970 * 1e3  // 毫秒

for _ in 0 ..< 1000 {
    let jsonB = """
    {"custom_a": 1101, "test_b": "性能测试","test_c": [114, 514, 1919], "test_d": false, "test_e": {"dict_a": "810", "dict_b": "字符串"}}
    """
    guard let data = jsonB.data(using: .utf8) else { fatalError() }
    guard let objB = try? JSONDecoder().decode(TestClassB.self, from: data) else { fatalError() }
    guard let data2 = try? JSONEncoder().encode(objB) else { fatalError() }
    let _ = String(data: data2, encoding: .utf8)
    guard let data3 = try? JSONEncoder().encode(objB) else { fatalError() }
    let _ = try? JSONSerialization.jsonObject(with: data3, options: []) as? [String: Any]
}

let time4 = Date().timeIntervalSince1970 * 1e3  // 毫秒
print("System time: \(time4 - time3) ms")

// MARK: ------

@HoshiJson class TestClassA {
    @HSJson("custom_a") var testA = 1
    var testB: String? = nil
    var testC = [1, 3, 5]
    @HSNoEqual var testD: Bool? = true
}

let json = """
{"custom_a": 12, "test_b": "字符串","test_c": [114, 514, 1919], "test_d": false, "test_e": {"dict_a": "810", "dict_b": "星空凛"}}
"""

let time1 = Date().timeIntervalSince1970 * 1e3  // 毫秒

for _ in 0 ..< 1000 {
    let objA = TestClassA(jsonStr: json)
    let _ = objA.jsonString
    let _ = objA.toDict
}

let time2 = Date().timeIntervalSince1970 * 1e3  // 毫秒
print("HoshiJson time: \(time2 - time1) ms")
