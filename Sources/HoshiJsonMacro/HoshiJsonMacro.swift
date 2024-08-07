// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public protocol HoshiDecodable: Decodable {
    init(jsonStr: String)
    init(dict: [String:Any])
}

/// - Note: 变量命名规则:\
/// (1) 按照json字段，使用驼峰或下划线命名（如json字段`rtc_channel_id`可以命名为`rtcChannelId`、`rtcChannelID`、`rtc_channel_id`\
/// (2) 使用 `@HSJson("name")` 自定义json字段名
/// - Warning: 除MDEntity外，禁止继承
/// - Note: 若要自定义反序列化过程，可以重写 init(from decoder: Decoder) 方法
/// - Note: 不含计算变量
@attached(member, names:
    named(hsOrigDict),
    named(hsOrigJsonStr),
    named(init(from:)),
    named(init(jsonStr:)),
    named(init(dict:)),
    named(init(data:)),
    named(init(coder:)),
    named(init()),
    named(CodingKeys),
    named(==),
    named(isEqual),
    named(description),
    named(jsonString),
    named(toDict)
)
@attached(extension, conformances: HoshiDecodable, CustomStringConvertible, Equatable, Encodable)
public macro HoshiJson() = #externalMacro(module: "HoshiJsonMacroMacros", type: "HoshiJsonMacro")

/// 标记某变量不参与 equal 对比
/// - Note: equal 对比中不含计算变量
@attached(peer)
public macro HSNoEqual() = #externalMacro(module: "HoshiJsonMacroMacros", type: "HSNoEqualMacro")

/// 用于自定义 json 字段名
@attached(peer)
public macro HSJson(_: String) = #externalMacro(module: "HoshiJsonMacroMacros", type: "HSJsonMacro")
