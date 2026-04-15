public import SwiftSyntax
internal import SwiftSyntaxBuilder
public import SwiftSyntaxMacros

public struct GenerateApplyAndWithFromProtocolMacro: DeclarationMacro {
  enum Error: Swift.Error, CustomStringConvertible {
    case missingStateType
    case missingProtocol

    var description: String {
      switch self {
      case .missingStateType:
        "#generateApplyAndWithFromProtocol requires a 'for:' argument with the state type, e.g. #generateApplyAndWithFromProtocol(for: MyState.self, protocol: MyStateApply.self)"
      case .missingProtocol:
        "#generateApplyAndWithFromProtocol requires a 'protocol:' argument, e.g. #generateApplyAndWithFromProtocol(for: MyState.self, protocol: MyStateApply.self)"
      }
    }
  }

  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    // Extract arguments
    let arguments = node.arguments

    // Find 'for:' argument (state type)
    guard
      let forArg = arguments.first(where: { $0.label?.text == "for" }),
      let memberAccess = forArg.expression.as(MemberAccessExprSyntax.self),
      let base = memberAccess.base
    else {
      throw Error.missingStateType
    }

    let typeName = base.trimmedDescription

    // Find 'protocol:' argument (protocol type)
    guard
      let protocolArg = arguments.first(where: { $0.label?.text == "protocol" }),
      let protocolMemberAccess = protocolArg.expression.as(MemberAccessExprSyntax.self),
      let protocolBase = protocolMemberAccess.base
    else {
      throw Error.missingProtocol
    }

    let protocolName = protocolBase.trimmedDescription

    // Find 'properties:' closure argument containing property declarations
    guard
      let propertiesArg = arguments.first(where: { $0.label?.text == "properties" }),
      let closureExpr = propertiesArg.expression.as(ClosureExprSyntax.self)
    else {
      // Fall back to trailing closure
      guard let trailingClosure = node.trailingClosure else {
        return []
      }
      return try generateExtension(
        typeName: typeName,
        protocolName: protocolName,
        from: trailingClosure.statements
      )
    }

    return try generateExtension(
      typeName: typeName,
      protocolName: protocolName,
      from: closureExpr.statements
    )
  }

  private static func generateExtension(
    typeName: String,
    protocolName: String,
    from statements: CodeBlockItemListSyntax
  ) throws -> [DeclSyntax] {
    var properties: [(name: String, type: String)] = []

    for statement in statements {
      guard let varDecl = statement.item.as(VariableDeclSyntax.self) else { continue }

      for binding in varDecl.bindings {
        guard
          let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
          let typeAnnotation = binding.typeAnnotation
        else { continue }

        let name = pattern.identifier.text

        // Strip trailing optional `?` to get the base type
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

    let extensionStr = """
      extension \(typeName): \(protocolName) {
        func with(
      \(withParams)
        ) -> Self {
          Self(
      \(withAssignments)
          )
        }

        func apply(path: AnyKeyPath, value: Any) -> Self {
          typealias State = \(typeName)

          return switch path {
      \(applyCases)
          default:
            \(fatalLine)
          }
        }
      }
      """

    return [DeclSyntax(stringLiteral: extensionStr)]
  }
}
