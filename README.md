# KMPWithMacro

`@GenerateApply` is a Swift macro that generates an `apply(path:value:)` function from a `with(...)` function signature, routing `AnyKeyPath`-based property updates through `KTStateWrapper` key paths.

## Requirements

- Swift 6.2 toolchain (macro support)
- Platforms: macOS 14, iOS 13, tvOS 13, watchOS 6, macCatalyst 13

## Installation

Add this package to your SwiftPM dependencies and import `KMPWithMacro` in the files where you use the macro.

## Usage

Attach `@GenerateApply` to a `with(...)` function inside an extension on your KMP state type:

```swift
import KMPWithMacro

extension ProfileState {
  @GenerateApply
  private func with(
    name: String? = nil,
    age: Int? = nil,
    trigger: (() -> Trigger?)? = nil
  ) -> Self {
    Self(
      name: name ?? self.name,
      age: age ?? self.age,
      trigger: trigger != nil ? trigger!() : self.trigger
    )
  }
}
```

Generated:

```swift
func apply(path: AnyKeyPath, value: Any) -> Self {
  typealias State = ProfileState

  return switch path {
  case \KTStateWrapper<State>.kt.name:
    with(name: value as? String)
  case \KTStateWrapper<State>.kt.age:
    with(age: value as? Int)
  case \KTStateWrapper<State>.kt.trigger:
    with(trigger: { value as? Trigger })
  default:
    fatalError("Unknown key path \(path)")
  }
}
```

## Closure-Wrapped Properties

Parameters typed as `(() -> T?)? = nil` are detected as closure-wrapped and generate `with(prop: { value as? T })` instead of `with(prop: value as? T)`.

## Constraints

- Apply the macro to a `func with(...)` inside an `extension`.
- All parameters must be optional (`T? = nil` or `(() -> T?)? = nil`).
