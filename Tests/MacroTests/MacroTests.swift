internal import MacroTester
internal import SwiftSyntaxMacros
internal import SwiftSyntaxMacrosTestSupport
internal import Testing

#if canImport(KMPGenerateApplyMacroMacros)
  import KMPGenerateApplyMacroMacros

  let testMacros: [String: Macro.Type] = [
    "GenerateApply": GenerateApplyMacro.self,
    "GenerateApplyFromProtocol": GenerateApplyFromProtocolMacro.self,
  ]

  @Suite
  struct GenerateApplyMacroTests {
    @Test func generateApply() {
      MacroTester.testMacro(macros: testMacros)
    }

    @Test func generateApplyWithClosure() {
      MacroTester.testMacro(macros: testMacros)
    }

    @Test func generateApplyFromProtocol() {
      MacroTester.testMacro(macros: testMacros)
    }

    @Test func generateApplyFromProtocolMultipleProperties() {
      MacroTester.testMacro(macros: testMacros)
    }
  }
#endif
