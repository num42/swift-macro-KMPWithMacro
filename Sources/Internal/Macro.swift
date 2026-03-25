public import SwiftSyntax
internal import SwiftSyntaxBuilder
public import SwiftSyntaxMacros

public struct GenerateApplyMacro: PeerMacro {
  enum Error: Swift.Error, CustomStringConvertible {
    case notAFunction
    case notInExtension

    var description: String {
      switch self {
      case .notAFunction:
        "@GenerateApply can only be applied to a function"
      case .notInExtension:
        "@GenerateApply must be used inside an extension"
      }
    }
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
      throw Error.notAFunction
    }

    // Get enclosing type name from lexical context
    guard let extensionDecl = context.lexicalContext.first(
      where: { $0.as(ExtensionDeclSyntax.self) != nil }
    )?.as(ExtensionDeclSyntax.self) else {
      throw Error.notInExtension
    }

    let typeName = extensionDecl.extendedType.trimmedDescription
    let parameters = funcDecl.signature.parameterClause.parameters

    var caseLines: [String] = []

    for param in parameters {
      let name = param.firstName.text

      guard let optionalType = param.type.as(OptionalTypeSyntax.self) else {
        continue
      }

      let innerType = optionalType.wrappedType

      if isClosureWrapped(innerType) {
        let baseType = extractClosureReturnBaseType(innerType)
        caseLines.append("    case \\KTStateWrapper<State>.kt.\(name):")
        caseLines.append("      with(\(name): { value as? \(baseType) })")
      } else {
        let baseType = innerType.trimmedDescription
        caseLines.append("    case \\KTStateWrapper<State>.kt.\(name):")
        caseLines.append("      with(\(name): value as? \(baseType))")
      }
    }

    let casesStr = caseLines.joined(separator: "\n")
    let fatalLine = #"fatalError("Unknown key path \(path)")"#

    let funcStr = """
      func apply(path: AnyKeyPath, value: Any) -> Self {
        typealias State = \(typeName)

        return switch path {
      \(casesStr)
        default:
          \(fatalLine)
        }
      }
      """

    return [DeclSyntax(stringLiteral: funcStr)]
  }

  /// Checks if a type is a closure type like `(() -> SomeType?)`
  private static func isClosureWrapped(_ type: TypeSyntax) -> Bool {
    if let tupleType = type.as(TupleTypeSyntax.self),
      tupleType.elements.count == 1,
      let element = tupleType.elements.first,
      element.type.is(FunctionTypeSyntax.self)
    {
      return true
    }

    if type.is(FunctionTypeSyntax.self) {
      return true
    }

    return false
  }

  /// Extracts the base return type from `(() -> SomeType?)` → `SomeType`
  private static func extractClosureReturnBaseType(_ type: TypeSyntax) -> String {
    var funcType: FunctionTypeSyntax?

    if let tupleType = type.as(TupleTypeSyntax.self),
      tupleType.elements.count == 1,
      let element = tupleType.elements.first,
      let ft = element.type.as(FunctionTypeSyntax.self)
    {
      funcType = ft
    } else if let ft = type.as(FunctionTypeSyntax.self) {
      funcType = ft
    }

    guard let funcType else { return type.trimmedDescription }

    let returnType = funcType.returnClause.type

    if let optionalReturn = returnType.as(OptionalTypeSyntax.self) {
      return optionalReturn.wrappedType.trimmedDescription
    }

    return returnType.trimmedDescription
  }
}
