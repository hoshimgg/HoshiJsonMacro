import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(HoshiJsonMacroMacros)
import HoshiJsonMacroMacros

let testMacros: [String: Macro.Type] = [
    "HoshiJson": HoshiJsonMacro.self,
]
#endif

final class HoshiJsonMacroTests: XCTestCase {
    func testMacro() throws {
        #if canImport(HoshiJsonMacroMacros)
        assertMacroExpansion(
            """
            @HoshiJson
            class Test {
                var traceID: String = ""
                var test2: Int?
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
