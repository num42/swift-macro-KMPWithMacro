@freestanding(declaration, names: arbitrary)
public macro GenerateApply(_ state: Any.Type, _ properties: (AnyKeyPath, Any.Type)...) =
  #externalMacro(
    module: "KMPGenerateApplyMacroMacros",
    type: "GenerateApplyMacro"
  )
