import SwiftCompilerPlugin
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct DecodableMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        HoshiJsonMacro.self,
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
        let variables = declaration.memberBlock.members.compactMap { member -> PatternBindingSyntax? in
            member.decl.as(VariableDeclSyntax.self)?.bindings.first
        }.filter { $0?.accessorBlock == nil }.compactMap { member -> String? in
            member?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
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
        
        let assignments = variables.map { variable in
            """
            self.\(variable) = try container.decodeIfPresent(type(of: \(variable)), forKey: .\(variable)) ?? \(variable)
            """
        }
        
        let requiredStr = isClass ? "required " : ""
        let cvnsStr = isClass ? "convenience " : ""
        let overrideStr = hasFather ? "override " : ""
        let superInitStr = hasFather ? "super.init()" : ""
        
        let initWithDataStr: String = {
            if (isStruct) { return "self = model" }
            return variables.map { variable in
                "self.\(variable) = model.\(variable)"
            }.joined(separator: "\n        ")
        }()
        
        let codingKeysCode = variables.map {"""
            case \($0) = "\($0.toSnake)"
        """}.joined(separator: "\n")
        
        let codingKeysStr = hasCodingKeys ? "" : """
            enum CodingKeys: String, CodingKey {
                \(codingKeysCode)
            }
        """
        
        let descCode = variables.map {"\($0): \\(\($0))"}.joined(separator: ", ")
        
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
        
        return [
            """
            \(raw: codingKeysStr)
            
            \(raw: initFromDcdStr)
            
            public \(raw: requiredStr)\(raw: cvnsStr)init(jsonStr: String) {
                guard let data = jsonStr.data(using: .utf8) else { self.init(); return }
                self.init(data: data)
            }
            
            public \(raw: requiredStr)\(raw: cvnsStr)init(dict: [String:Any]) {
                guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []) else { self.init(); return }
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
            
            \(raw: descStr)
            """
        ]
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
        let descExtension = try ExtensionDeclSyntax("extension \(type.trimmed): CustomStringConvertible {}")
        return isClass && fatherName == nil ? [decodableExtension, descExtension] : [decodableExtension]
    }
    
    func camel2snake(v: String) {
         
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
