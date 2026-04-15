@attached(peer, names: named(apply))
public macro GenerateApply() =
  #externalMacro(
    module: "KMPGenerateApplyMacroMacros",
    type: "GenerateApplyMacro"
  )

@attached(peer, names: arbitrary)
public macro GenerateApplyFromProtocol(_ stateType: Any.Type) =
  #externalMacro(
    module: "KMPGenerateApplyMacroMacros",
    type: "GenerateApplyFromProtocolMacro"
  )
