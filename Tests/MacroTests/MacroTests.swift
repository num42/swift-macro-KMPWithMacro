internal import MacroTester
internal import SwiftSyntaxMacros
internal import SwiftSyntaxMacrosTestSupport
internal import Testing

#if canImport(KMPWithMacroMacros)
  import KMPWithMacroMacros

  let testMacros: [String: Macro.Type] = [
    "GenerateApply": GenerateApplyMacro.self
  ]

  @Suite
  struct GenerateApplyMacroTests {
    @Test func generateApply() {
      MacroTester.testMacro(macros: testMacros)
    }

    @Test func generateApplyWithClosure() {
      MacroTester.testMacro(macros: testMacros)
    }
  }
#endif
