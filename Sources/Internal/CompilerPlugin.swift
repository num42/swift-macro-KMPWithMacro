internal import SwiftCompilerPlugin
internal import SwiftSyntaxMacros

@main
struct KMPGenerateApplyMacroPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    GenerateApplyMacro.self
  ]
}
