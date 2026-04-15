@attached(peer, names: named(apply))
public macro GenerateApply() =
  #externalMacro(
    module: "KMPGenerateApplyMacroMacros",
    type: "GenerateApplyMacro"
  )

@freestanding(declaration, names: named(with), named(apply))
public macro generateApplyAndWithFromProtocol(
  properties: () -> Void
) =
  #externalMacro(
    module: "KMPGenerateApplyMacroMacros",
    type: "GenerateApplyAndWithFromProtocolMacro"
  )
