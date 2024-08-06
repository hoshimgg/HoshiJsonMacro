// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public protocol HoshiDecodable: Decodable {
    init(jsonStr: String)
    init(dict: [String:Any])
}

/// - Warning: 变量命名规则:（以下任选其一，不可混用）\
/// (1) 完全和json字段相同，保留下划线；\
/// (2) 严格按照json字段驼峰命名；（如`rtc_channel_id`命名为`rtcChannelId`，注意最后一个`d`为小写）\
/// (3) 自定义enum CodingKeys: String, CodingKey
/// - Warning: 除MDEntity外，禁止继承
/// - Note: 不含计算变量
@attached(member, names:
    named(CodingKeys),
    named(init(from:)),
    named(init(jsonStr:)),
    named(init(dict:)),
    named(init(data:)),
    named(init(coder:)),
    named(init()),
    named(==),
    named(isEqual),
    named(description)
)
@attached(extension, conformances: HoshiDecodable, CustomStringConvertible, Equatable)
public macro HoshiJson() = #externalMacro(module: "HoshiJsonMacroMacros", type: "HoshiJsonMacro")

/// 标记某变量不参与equal比对
/// - Note: 不含计算变量
@attached(peer)
public macro HSNoEqual() = #externalMacro(module: "HoshiJsonMacroMacros", type: "HSNoEqualMacro")

