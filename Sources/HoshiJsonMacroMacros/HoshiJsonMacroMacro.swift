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
    ]
}

public struct HoshiJsonMacro: MemberMacro, ExtensionMacro {
    struct HSVariable {
        let name: String
        let noEqual: Bool
        let json: String
        let isBool: Bool
        let isInt: Bool
    }
    
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
        
        var variables: [HSVariable] = []
        for member in declaration.memberBlock.members {  // 不用compactMap的原因是会导致“错误提示”显示错误
            guard let varDeclSyn = member.decl.as(VariableDeclSyntax.self) else { continue }
            guard let binding = varDeclSyn.bindings.first else { continue }
            if binding.accessorBlock != nil { continue }  // 计算属性
            let noJson = varDeclSyn.attributes.contains {
                $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "HSNoJson"
            }
            if noJson { continue }
            guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { continue }
            let noEqual = varDeclSyn.attributes.contains {
                $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "HSNoEqual"
            }
            let json = varDeclSyn.attributes.first {
                $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "HSJson"
            }?.as(AttributeSyntax.self)?.arguments?.as(LabeledExprListSyntax.self)?.first?.as(LabeledExprSyntax.self)?.expression
                .as(StringLiteralExprSyntax.self)?.segments.first?.as(StringSegmentSyntax.self)?.content.text
            ?? name.toSnake

            variables.append(HSVariable(name: name, noEqual: noEqual, json: json, isBool: isBool(binding: binding), isInt: isInt(binding: binding)))
        }
        
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
                    if let v = try? container?.decodeIfPresent(Int.self, forKey: .\($0.name)) {
                        self.\($0.name) = v
                    } else if let v = try? container?.decodeIfPresent(Bool.self, forKey: .\($0.name)) {
                        self.\($0.name) = v ? 1 : 0
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
            case \($0.name) = "\($0.json)"
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
            var hsOrigDict: [String:Any]?
            var hsOrigJsonStr: String?
        
            \(raw: codingKeysStr)
            \(raw: encodeFuncStr)
            
            \(raw: initFromDcdStr)
            
            public \(raw: requiredStr)\(raw: cvnsStr)init(jsonStr: String) {
                guard let data = jsonStr.data(using: .utf8) else { self.init(); return }
                self.init(data: data)
                hsOrigJsonStr = jsonStr
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
                hsOrigDict = dict
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
                if let jsonStr = hsOrigJsonStr { return jsonStr }
                guard let data = try? JSONEncoder().encode(self) else { return "序列化错误" }
                return String(data: data, encoding: .utf8) ?? "序列化错误"
            }
            
            public var toDict: [String:Any] {
                if let dict = hsOrigDict { return dict }
                guard let data = try? JSONEncoder().encode(self) else { return ["error": "序列化错误"] }
                return (try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]) ?? ["error": "序列化错误"]
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
    
    static func isBool(binding: PatternBindingSyntax) -> Bool {
        // 显式类型声明
        let typeSyntax = binding.typeAnnotation?.type
        let identifier = typeSyntax?.as(IdentifierTypeSyntax.self) ?? typeSyntax?.as(OptionalTypeSyntax.self)?.wrappedType.as(IdentifierTypeSyntax.self)
        if let typeText = identifier?.name.text { return typeText == "Bool" }
        // 隐式类型推导
        return binding.initializer?.value.as(BooleanLiteralExprSyntax.self) != nil
    }
    
    static func isInt(binding: PatternBindingSyntax) -> Bool {
        // 显式类型声明
        let typeSyntax = binding.typeAnnotation?.type
        let identifier = typeSyntax?.as(IdentifierTypeSyntax.self) ?? typeSyntax?.as(OptionalTypeSyntax.self)?.wrappedType.as(IdentifierTypeSyntax.self)
        if let typeText = identifier?.name.text { return typeText == "Int" }
        // 隐式类型推导
        return binding.initializer?.value.as(IntegerLiteralExprSyntax.self) != nil
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

extension String {
    var toSnake: String {
        let pattern = "([a-z0-9])([A-Z])"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return "" }
        let range = NSRange(location: 0, length: self.count)
        let result = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
        return result.lowercased()
    }
}
