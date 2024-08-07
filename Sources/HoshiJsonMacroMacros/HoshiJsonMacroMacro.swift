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
    ]
}

public struct HoshiJsonMacro: MemberMacro, ExtensionMacro {
    struct HSVariable {
        let name: String
        let noEqual: Bool
        let json: String
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
        
        let variables: [HSVariable] = declaration.memberBlock.members.compactMap { member in
            guard let varDeclSyn = member.decl.as(VariableDeclSyntax.self) else { return nil }
            if varDeclSyn.bindings.first?.accessorBlock != nil { return nil }  // 计算属性
            guard let name = varDeclSyn.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { return nil }
            let noEqual = varDeclSyn.attributes.contains {
                $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "HSNoEqual"
            }
            let json = varDeclSyn.attributes.first {
                $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "HSJson"
            }?.as(AttributeSyntax.self)?.arguments?.as(LabeledExprListSyntax.self)?.first?.as(LabeledExprSyntax.self)?.expression
                .as(StringLiteralExprSyntax.self)?.segments.first?.as(StringSegmentSyntax.self)?.content.text
            ?? name.toSnake

            return HSVariable(name: name, noEqual: noEqual, json: json)
        }
        
        let enums = declaration.memberBlock.members.compactMap { member in
            member.decl.as(EnumDeclSyntax.self)?.name.text
        }
        
        let inits = declaration.memberBlock.members.compactMap { member -> FunctionParameterSyntax? in
            member.decl.as(InitializerDeclSyntax.self)?.signature.parameterClause.parameters.first
        }

        let hasFather = declaration.inheritanceClause != nil  // 父类只可能是MDEntity
        let hasCodingKeys = enums.contains("CodingKeys")
        let hasInitFromDcd = inits.contains { $0.firstName.text == "from" && $0.secondName?.text == "decoder" }
        
        let assignments = variables.map { """
            self.\($0.name) = try container.decodeIfPresent(type(of: \($0.name)), forKey: .\($0.name)) ?? \($0.name)
        """ }
        
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
        
        let codingKeysCode = variables.map { """
            case \($0.name) = "\($0.json)"
        """ }.joined(separator: "\n")
        
        let codingKeysStr = hasCodingKeys ? "" : """
            enum CodingKeys: String, CodingKey {
                \(codingKeysCode)
            }
        """
        
        let descCode = variables.map {"\($0.name): \\(\($0.name))"}.joined(separator: ", ")
        
        let descStr = isClass ? """
            public \(overrideStr)var description: String {
                "\(name)(\(descCode))"
            }
        """ : ""
        
        let initFromDcdStr = hasInitFromDcd ? "" : """
            public \(requiredStr)init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                \(assignments.joined(separator: "\n    "))
                \(superInitStr)
            }
        """
        
        var equalStr = hasFather ? "" : variables.compactMap { v -> String? in
            if v.noEqual { return nil }
            return "lhs.\(v.name) == rhs.\(v.name)"
        }.joined(separator: " && ")
        
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
            
            \(raw: initFromDcdStr)
            
            public \(raw: requiredStr)\(raw: cvnsStr)init(jsonStr: String) {
                guard let data = jsonStr.data(using: .utf8) else { self.init(); return }
                self.init(data: data)
                hsOrigJsonStr = jsonStr
            }
            
            public \(raw: requiredStr)\(raw: cvnsStr)init(dict: [String:Any]) {
                guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []) else { self.init(); return }
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
        
            var jsonString: String {
                if let jsonStr = hsOrigJsonStr { return jsonStr }
                guard let data = try? JSONEncoder().encode(self) else { return "序列化错误" }
                return String(data: data, encoding: .utf8) ?? "序列化错误"
            }
            
            var toDict: [String:Any] {
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
        if let fatherName = fatherName, fatherName != "MDEntity" {
            fatalError("若继承，只允许MDEntity")
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

public struct HSNoEqualMacro: PeerMacro {
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
