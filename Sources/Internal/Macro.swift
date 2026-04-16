public import SwiftSyntax
internal import SwiftSyntaxBuilder
public import SwiftSyntaxMacros

public struct GenerateApplyMacro: DeclarationMacro {
  enum Error: Swift.Error, CustomStringConvertible {
    case missingState
    case invalidProperty(String)

    var description: String {
      switch self {
      case .missingState:
        "#GenerateApply requires a state type name as its first argument"
      case .invalidProperty(let str):
        "Invalid property format '\(str)'. Expected (\\Type.property, Type.self)."
      }
    }
  }

  struct Property {
    let name: String
    let type: String
    let isOptional: Bool

    var baseType: String {
      isOptional ? String(type.dropLast()) : type
    }
  }

  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let arguments = Array(node.arguments)

    guard
      let firstArg = arguments.first,
      let memberAccess = firstArg.expression.as(MemberAccessExprSyntax.self),
      memberAccess.declName.baseName.text == "self",
      let base = memberAccess.base
    else {
      throw Error.missingState
    }

    let typeName = base.trimmedDescription
    let propertyArgs = arguments.dropFirst()
    let properties = try parseProperties(from: propertyArgs)

    let withFunc = generateWithFunction(properties: properties)
    let applyFunc = generateApplyFunction(typeName: typeName, properties: properties)

    let extensionStr = """
      extension \(typeName) {
        \(withFunc)

        \(applyFunc)
      }
      """

    return [DeclSyntax(stringLiteral: extensionStr)]
  }

  private static func parseProperties(
    from arguments: some Sequence<LabeledExprSyntax>
  ) throws -> [Property] {
    try arguments.map { arg in
      guard
        let tuple = arg.expression.as(TupleExprSyntax.self),
        tuple.elements.count == 2
      else {
        throw Error.invalidProperty(arg.expression.trimmedDescription)
      }

      let elements = Array(tuple.elements)

      guard
        let keyPath = elements[0].expression.as(KeyPathExprSyntax.self),
        let lastComponent = keyPath.components.last,
        let property = lastComponent.component.as(KeyPathPropertyComponentSyntax.self)
      else {
        throw Error.invalidProperty(arg.expression.trimmedDescription)
      }

      let name = property.declName.baseName.text

      guard
        let memberAccess = elements[1].expression.as(MemberAccessExprSyntax.self),
        memberAccess.declName.baseName.text == "self",
        let base = memberAccess.base
      else {
        throw Error.invalidProperty(arg.expression.trimmedDescription)
      }

      let type = base.trimmedDescription
      let isOptional = type.hasSuffix("?")

      return Property(name: name, type: type, isOptional: isOptional)
    }
  }

  private static func generateWithFunction(properties: [Property]) -> String {
    let params = properties.map { prop in
      if prop.isOptional {
        "\(prop.name): (() -> \(prop.type))? = nil"
      } else {
        "\(prop.name): \(prop.type)? = nil"
      }
    }.joined(separator: ", ")

    let bodyArgs = properties.map { prop in
      if prop.isOptional {
        "\(prop.name): \(prop.name) != nil ? \(prop.name)!() : self.\(prop.name)"
      } else {
        "\(prop.name): \(prop.name) ?? self.\(prop.name)"
      }
    }.joined(separator: ", ")

    return """
      func with(\(params)) -> Self {
        Self(\(bodyArgs))
      }
      """
  }

  private static func generateApplyFunction(typeName: String, properties: [Property]) -> String {
    var caseLines: [String] = []

    for prop in properties {
      caseLines.append("    case \\KTStateWrapper<State>.kt.\(prop.name):")
      if prop.isOptional {
        caseLines.append("      with(\(prop.name): { value as? \(prop.baseType) })")
      } else {
        caseLines.append("      with(\(prop.name): value as? \(prop.type))")
      }
    }

    let casesStr = caseLines.joined(separator: "\n")
    let fatalLine = #"fatalError("Unknown key path \(path)")"#

    return """
      func apply(path: AnyKeyPath, value: Any) -> Self {
        typealias State = \(typeName)

        return switch path {
      \(casesStr)
        default:
          \(fatalLine)
        }
      }
      """
  }
}
