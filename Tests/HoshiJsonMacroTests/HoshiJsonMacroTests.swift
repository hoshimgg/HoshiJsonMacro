import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(HoshiJsonMacroMacros)
import HoshiJsonMacroMacros

let testMacros: [String: Macro.Type] = [
    "HoshiJson": HoshiJsonMacro.self,
    "HSNoEqual": HSNoEqualMacro.self,
    "HSJson": HSJsonMacro.self,
    "HoshiInit": HoshiInitMacro.self,
]
#endif

final class HoshiJsonMacroTests: XCTestCase {
    func testMacro() throws {
        #if canImport(HoshiJsonMacroMacros)
        assertMacroExpansion(
            """
            struct S1 {
                let a
            }
            
            enum E1 {
                case a
            }
            
            @HoshiInit
            struct Test {
                let a: E1 = .a  // test
            }
            """,
            expandedSource: """
            
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithStringLiteral() throws {
        #if canImport(HoshiJsonMacroMacros)
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
