@attached(peer, names: named(apply))
public macro GenerateApply() =
  #externalMacro(
    module: "KMPGenerateApplyMacroMacros",
    type: "GenerateApplyMacro"
  )

@freestanding(declaration, names: arbitrary)
public macro generateApplyAndWithFromProtocol(
  for stateType: Any.Type,
  protocol protocolType: Any.Type,
  properties: () -> Void
) =
  #externalMacro(
    module: "KMPGenerateApplyMacroMacros",
    type: "GenerateApplyAndWithFromProtocolMacro"
  )
