public import SwiftSyntax
internal import SwiftSyntaxBuilder
public import SwiftSyntaxMacros

public struct GenerateApplyAndWithFromProtocolMacro: DeclarationMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    // Get enclosing type name from lexical context
    let typeName: String
    if let extensionDecl = context.lexicalContext.first(
      where: { $0.as(ExtensionDeclSyntax.self) != nil }
    )?.as(ExtensionDeclSyntax.self) {
      typeName = extensionDecl.extendedType.trimmedDescription
    } else {
      typeName = "Self"
    }

    // Get property declarations from the trailing closure
    guard let trailingClosure = node.trailingClosure else {
      return []
    }

    var properties: [(name: String, type: String)] = []

    for statement in trailingClosure.statements {
      guard let varDecl = statement.item.as(VariableDeclSyntax.self) else { continue }

      for binding in varDecl.bindings {
        guard
          let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
          let typeAnnotation = binding.typeAnnotation
        else { continue }

        let name = pattern.identifier.text

        let baseType: String
        if let optionalType = typeAnnotation.type.as(OptionalTypeSyntax.self) {
          baseType = optionalType.wrappedType.trimmedDescription
        } else {
          baseType = typeAnnotation.type.trimmedDescription
        }

        properties.append((name: name, type: baseType))
      }
    }

    // Generate with() parameters
    let withParams = properties.map { prop in
      "    \(prop.name): (() -> \(prop.type)?)? = nil"
    }.joined(separator: ",\n")

    // Generate with() body assignments
    let withAssignments = properties.map { prop in
      "      \(prop.name): \(prop.name) != nil ? \(prop.name)!() : self.\(prop.name)"
    }.joined(separator: ",\n")

    // Generate apply() cases
    let applyCases = properties.map { prop in
      """
          case \\KTStateWrapper<State>.kt.\(prop.name):
            with(\(prop.name): { value as? \(prop.type) })
      """
    }.joined(separator: "\n")

    let fatalLine = #"fatalError("Unknown key path \(path)")"#

    let withFunc: DeclSyntax = """
      func with(
      \(raw: withParams)
      ) -> Self {
        Self(
      \(raw: withAssignments)
        )
      }
      """

    let applyFunc: DeclSyntax = """
      func apply(path: AnyKeyPath, value: Any) -> Self {
        typealias State = \(raw: typeName)

        return switch path {
      \(raw: applyCases)
        default:
          \(raw: fatalLine)
        }
      }
      """

    return [withFunc, applyFunc]
  }
}
