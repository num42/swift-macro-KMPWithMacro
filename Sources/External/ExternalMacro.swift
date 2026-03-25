@attached(peer, names: named(apply))
public macro GenerateApply() =
  #externalMacro(
    module: "KMPWithMacroMacros",
    type: "GenerateApplyMacro"
  )
