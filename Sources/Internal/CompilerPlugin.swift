internal import SwiftCompilerPlugin
internal import SwiftSyntaxMacros

@main
struct KMPWithMacroPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    GenerateApplyMacro.self
  ]
}
