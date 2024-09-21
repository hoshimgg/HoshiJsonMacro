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
/// - Warning: 除MDEntity或NSObject外，禁止继承
/// - Note: 若解析失败，请首先考虑类型声明错误
@attached(member, names: arbitrary)
@attached(extension, conformances: HoshiDecodable, CustomStringConvertible, Equatable, Encodable)
public macro HoshiJson() = #externalMacro(module: "HoshiJsonMacroMacros", type: "HoshiJsonMacro")

/// 标记某变量不参与 equal 对比
/// - Note: equal 对比中不含计算变量
@attached(peer)
public macro HSNoEqual() = #externalMacro(module: "HoshiJsonMacroMacros", type: "HSNoEqualMacro")

/// 用于自定义 json 字段名
@attached(peer)
public macro HSJson(_: String) = #externalMacro(module: "HoshiJsonMacroMacros", type: "HSJsonMacro")

/// 标记某变量不参与序列化/反序列化
@attached(peer)
public macro HSNoJson() = #externalMacro(module: "HoshiJsonMacroMacros", type: "HSNoJsonMacro")

/// 自动生成public的init方法，可识别默认值
/// - Warning: 目前必须显示声明每个变量的类型（后续会优化）
@attached(member, names: arbitrary)
public macro HoshiInit() = #externalMacro(module: "HoshiJsonMacroMacros", type: "HoshiInitMacro")
