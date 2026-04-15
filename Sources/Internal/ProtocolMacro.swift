public import SwiftSyntax
internal import SwiftSyntaxBuilder
public import SwiftSyntaxMacros

public struct GenerateApplyFromProtocolMacro: PeerMacro {
  enum Error: Swift.Error, CustomStringConvertible {
    case notAProtocol
    case missingStateType

    var description: String {
      switch self {
      case .notAProtocol:
        "@GenerateApplyFromProtocol can only be applied to a protocol"
      case .missingStateType:
        "@GenerateApplyFromProtocol requires a state type argument, e.g. @GenerateApplyFromProtocol(MyState.self)"
      }
    }
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard declaration.is(ProtocolDeclSyntax.self) else {
      throw Error.notAProtocol
    }

    let protocolDecl = declaration.as(ProtocolDeclSyntax.self)!

    // Extract state type name from macro argument: @GenerateApplyFromProtocol(MyState.self)
    guard
      let arguments = node.arguments?.as(LabeledExprListSyntax.self),
      let firstArg = arguments.first,
      let memberAccess = firstArg.expression.as(MemberAccessExprSyntax.self),
      let base = memberAccess.base
    else {
      throw Error.missingStateType
    }

    let typeName = base.trimmedDescription

    // Collect properties from protocol declaration
    var properties: [(name: String, type: String)] = []

    for member in protocolDecl.memberBlock.members {
      guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }

      for binding in varDecl.bindings {
        guard
          let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
          let typeAnnotation = binding.typeAnnotation
        else { continue }

        let name = pattern.identifier.text
        let type = typeAnnotation.type.trimmedDescription

        // Strip trailing optional `?` to get the base type
        let baseType: String
        if let optionalType = typeAnnotation.type.as(OptionalTypeSyntax.self) {
          baseType = optionalType.wrappedType.trimmedDescription
        } else {
          baseType = type
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
      extension \(typeName) {
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
