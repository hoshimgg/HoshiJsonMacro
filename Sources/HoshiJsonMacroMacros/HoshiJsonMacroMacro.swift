import SwiftCompilerPlugin
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct DecodableMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        HoshiJsonMacro.self,
        HSNoEqualMacro.self,
        HSJsonMacro.self,
        HSNoJsonMacro.self,
        HoshiInitMacro.self
    ]
}

public struct HoshiJsonMacro: MemberMacro, ExtensionMacro {
    public static func expansion<Declaration, Context> (
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] where Declaration: DeclGroupSyntax, Context: MacroExpansionContext {
        let isClass = declaration is ClassDeclSyntax
        let isStruct = declaration is StructDeclSyntax
        guard isClass || isStruct else {
            fatalError("只能修饰struct或class")
        }
        
        let name = declaration.as(ClassDeclSyntax.self)?.name.text ?? declaration.as(StructDeclSyntax.self)?.name.text ?? ""
        
        let variables = analyzeVar(declaration: declaration).filter { !$0.noJson && !$0.isLet }
        
        let enums = declaration.memberBlock.members.compactMap { member in
            member.decl.as(EnumDeclSyntax.self)?.name.text
        }
        
        let inits = declaration.memberBlock.members.compactMap { member -> FunctionParameterSyntax? in
            member.decl.as(InitializerDeclSyntax.self)?.signature.parameterClause.parameters.first
        }

        let hasFather = declaration.inheritanceClause != nil  // 父类只可能是MDEntity或NSObject
        let hasCodingKeys = enums.contains("CodingKeys")
        let hasInitFromDcd = inits.contains { $0.firstName.text == "from" && $0.secondName?.text == "decoder" }
        
        let assignments = variables.map {
            if $0.isBool {
                return """
                    if let v = try? container?.decodeIfPresent(Bool.self, forKey: .\($0.name)) {
                        self.\($0.name) = v
                    } else if let v = try? container?.decodeIfPresent(Int.self, forKey: .\($0.name)) {
                        self.\($0.name) = v > 0
                    }
                """
            } else if $0.isInt {
                return """
                    if let v = try? container?.decodeIfPresent(\($0.typeName ?? "Int").self, forKey: .\($0.name)) {
                        self.\($0.name) = v
                    } else if let v = try? container?.decodeIfPresent(Bool.self, forKey: .\($0.name)) {
                        self.\($0.name) = v ? 1 : 0
                    } else if let v = try? container?.decodeIfPresent(String.self, forKey: .\($0.name)) {
                        self.\($0.name) = \($0.typeName ?? "Int")(v) ?? 0
                    }
                """
            } else if $0.isString {
                return """
                    if let v = try? container?.decodeIfPresent(String.self, forKey: .\($0.name)) {
                        self.\($0.name) = v
                    } else if let v = try? container?.decodeIfPresent(Int.self, forKey: .\($0.name)) {
                        self.\($0.name) = String(v)
                    }
                """
            } else {
                return """
                    self.\($0.name) = (try? container?.decodeIfPresent(type(of: \($0.name)), forKey: .\($0.name))) ?? \($0.name)
                """
            }
        }
        
        let requiredStr = isClass ? "required " : ""
        let cvnsStr = isClass ? "convenience " : ""
        let overrideStr = hasFather ? "override " : ""
        let superInitStr = hasFather ? "super.init()" : ""
        
        let initWithDataStr: String = {
            if (isStruct) { return "self = model" }
            return variables.map {
                "self.\($0.name) = model.\($0.name)"
            }.joined(separator: "\n        ")
        }()
        
        var codingKeysCode = variables.map { """
            case \($0.name) = "\($0.jsonName)"
        """ }.joined(separator: "\n")
        if codingKeysCode.isEmpty { codingKeysCode = "case hoshi = \"hoshi\"" }
        
        let codingKeysStr = hasCodingKeys ? "" : """
            enum CodingKeys: String, CodingKey {
                \(codingKeysCode)
            }
        """
        
        let encodeFuncStr = variables.isEmpty ? "func encode(to encoder: any Encoder) throws {}" : ""
        
        let descCode = variables.map {"\($0.name): \\(\($0.name))"}.joined(separator: ", ")
        
        let descStr = isClass ? """
            public \(overrideStr)var description: String {
                "\(name)(\(descCode))"
            }
        """ : ""
        
        let initFromDcdStr = hasInitFromDcd ? "" : """
            public \(requiredStr)init(from decoder: Decoder) {
                let container = try? decoder.container(keyedBy: CodingKeys.self)
                \(assignments.joined(separator: "\n    "))
                \(superInitStr)
            }
        """
        
        var equalStr = hasFather ? "" : variables.compactMap { v -> String? in
            if v.noEqual { return nil }
            return "lhs.\(v.name) == rhs.\(v.name)"
        }.joined(separator: " && ")
        if equalStr.isEmpty { equalStr = "true" }
        
        equalStr = hasFather ? "" : """
            public static func == (lhs: \(name), rhs: \(name)) -> Bool {
                return \(equalStr)
            }
        """
        
        var ocEqualStr = hasFather ? variables.compactMap { v -> String? in
            if v.noEqual { return nil }
            return "self.\(v.name) == obj.\(v.name)"
        }.joined(separator: " && ") : ""
        
        ocEqualStr = hasFather ? """
            public func isEqual(_ object: \(name)?) -> Bool {
                guard let obj = object else { return false }
                return \(ocEqualStr)
            }
        """ : ""

        return [ """
            \(raw: codingKeysStr)
            \(raw: encodeFuncStr)
            
            \(raw: initFromDcdStr)
            
            public \(raw: requiredStr)\(raw: cvnsStr)init(jsonStr: String) {
                guard let data = jsonStr.data(using: .utf8) else { self.init(); return }
                self.init(data: data)
            }
            
            public \(raw: requiredStr)\(raw: cvnsStr)init(dict: [String:Any]) {
                var data: Data? = nil
                if let dict = dict as? [String:HSJsonObj] {
                    data = try? JSONEncoder().encode(dict)
                } else if JSONSerialization.isValidJSONObject(dict) {
                    data = try? JSONSerialization.data(withJSONObject: dict, options: .fragmentsAllowed)
                }
                guard let data else { self.init(); return }
                self.init(data: data)
            }
            
            public init(data: Data) {
                if let model = try? JSONDecoder().decode(Self.self, from: data) {
                    \(raw: initWithDataStr)
                }
                \(raw: superInitStr)
            }
            
            public \(raw: requiredStr)init?(coder: NSCoder) {
                fatalError("init(coder:) 未实现")
            }
            
            public \(raw: overrideStr)init() {
                \(raw: superInitStr)
            }
        
            \(raw: equalStr)
        
            \(raw: ocEqualStr)
        
            \(raw: descStr)
        
            public var jsonString: String {
                guard let data = try? JSONEncoder().encode(self) else { return "序列化错误" }
                return String(data: data, encoding: .utf8) ?? "序列化错误"
            }
            
            public var toDict: [String:Any] {
                guard let data = try? JSONEncoder().encode(self) else { return ["error": "序列化错误"] }
                return (try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]) ?? ["error": "序列化错误"]
            }
        
            public func hsCopy() -> \(raw: name) {
                return \(raw: name)(dict: self.toDict)
            }
        """ ]
    }
    
    public static func expansion(
      of node: AttributeSyntax,
      attachedTo declaration: some DeclGroupSyntax,
      providingExtensionsOf type: some TypeSyntaxProtocol,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let isClass = declaration is ClassDeclSyntax
        let fatherName = declaration.inheritanceClause?.inheritedTypes.first?.type.as(IdentifierTypeSyntax.self)?.name.text
        let allowedFathers = ["MDEntity", "NSObject"]
        if let fatherName = fatherName, !allowedFathers.contains(fatherName) {
            fatalError("若继承，只允许MDEntity或NSObject")
        }
        let decodableExtension = try ExtensionDeclSyntax("extension \(type.trimmed): HoshiDecodable {}")
        let encodeExtension = try ExtensionDeclSyntax("extension \(type.trimmed): Encodable {}")
        let descExtension = try ExtensionDeclSyntax("extension \(type.trimmed): CustomStringConvertible {}")
        let equalExtension = try ExtensionDeclSyntax("extension \(type.trimmed): Equatable {}")
        
        var exs = [decodableExtension, encodeExtension]
        if isClass && fatherName == nil { exs.append(descExtension) }
        if fatherName == nil { exs.append(equalExtension) }
        return exs
    }
}

public struct HoshiInitMacro: MemberMacro {
    public static func expansion<Declaration, Context> (
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] where Declaration: DeclGroupSyntax, Context: MacroExpansionContext {
        guard declaration is ClassDeclSyntax || declaration is StructDeclSyntax else { fatalError("只能修饰struct或class") }
        
        let variables = analyzeVar(declaration: declaration)
        let params = variables.map {
            "\($0.name): \($0.typeName ?? "")\($0.isOptional == true ? "?" : "") \($0.initial ?? "")"
        }.joined(separator: ", ")
        
        return ["""
            public init(\(raw: params)) {
                \(raw: variables.map { "self.\($0.name) = \($0.name)" }.joined(separator: "\n"))
            }
        """]
    }
}

public struct HSNoEqualMacro: PeerMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        return []
    }
}

public struct HSNoJsonMacro: PeerMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        return []
    }
}

public struct HSJsonMacro: PeerMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        return []
    }
}

// MARK: - Util

struct HSVariable {
    let name: String
    let typeName: String?  // 不带"?"
    let isOptional: Bool?
    let initial: String?  // 带"="
    let noJson: Bool
    let noEqual: Bool
    let jsonName: String
    let isBool: Bool
    let isInt: Bool
    let isString: Bool
    let isLet: Bool
}

func analyzeVar(declaration: DeclGroupSyntax) -> [HSVariable] {
    var variables: [HSVariable] = []
    for member in declaration.memberBlock.members {  // 不用compactMap的原因是会导致“错误提示”显示错误
        guard let varDeclSyn = member.decl.as(VariableDeclSyntax.self) else { continue }
        guard let binding = varDeclSyn.bindings.first else { continue }
        if binding.accessorBlock != nil { continue }  // 跳过计算属性
        
        guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { continue }
        
        let (typeName, isOptional) = typeName(binding: binding)
        
        let noJson = varDeclSyn.attributes.contains {
            $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "HSNoJson"
        }
        
        let noEqual = varDeclSyn.attributes.contains {
            $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "HSNoEqual"
        }
        
        let jsonName = varDeclSyn.attributes.first {
            $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "HSJson"
        }?.as(AttributeSyntax.self)?.arguments?.as(LabeledExprListSyntax.self)?.first?.expression
            .as(StringLiteralExprSyntax.self)?.segments.first?.as(StringSegmentSyntax.self)?.content.text
        ?? name.toSnake
        
        let intTypeNames = ["Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16", "UInt32", "UInt64"]
        let isInt = typeName == nil ? binding.initializer?.value.as(IntegerLiteralExprSyntax.self) != nil : intTypeNames.contains(typeName ?? "")
        let isBool = typeName == nil ? binding.initializer?.value.as(BooleanLiteralExprSyntax.self) != nil : typeName == "Bool"
        let isString = typeName == nil ? binding.initializer?.value.as(StringLiteralExprSyntax.self) != nil : typeName == "String"
        let initial = String(binding.initializer?.description.components(separatedBy: "//").first ?? "")
        let isLet = varDeclSyn.bindingSpecifier.text == "let"
        
        variables.append(HSVariable(name: name, typeName: typeName, isOptional: isOptional, initial: initial, noJson: noJson, noEqual: noEqual,
                                    jsonName: jsonName, isBool: isBool, isInt: isInt, isString: isString, isLet: isLet))
    }
    return variables
}

/// 获取显式类型声明
func typeName(binding: PatternBindingSyntax) -> (String?, Bool?) {  // (typeName, isOptional)
    let typeSyntax = binding.typeAnnotation?.type
    if let identifier = typeSyntax?.as(IdentifierTypeSyntax.self) {
        return (identifier.name.text, false)
    } else if let identifier = typeSyntax?.as(OptionalTypeSyntax.self)?.wrappedType.as(IdentifierTypeSyntax.self) {
        return (identifier.name.text, true)
    }
    return (nil, nil)
}

extension String {
    var toSnake: String {
        let pattern = "([a-z0-9])([A-Z])"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return "" }
        let range = NSRange(location: 0, length: self.count)
        let result = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
        return result.lowercased()
    }
}
