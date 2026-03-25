@attached(peer, names: named(apply))
public macro GenerateApply() =
  #externalMacro(
    module: "KMPGenerateApplyMacroMacros",
    type: "GenerateApplyMacro"
  )
