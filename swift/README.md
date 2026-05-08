# Swift Scaffold

This folder contains the Swift Package scaffold for the Money Hero native iOS client.

Service scope and constraints are defined in `specs/specs.md`.

## Prerequisites

- macOS with Xcode installed.
- Swift Package Manager support (included with Xcode).

Signing and provisioning are not configured in this scaffold.

`Package.swift` declares both iOS 17 and macOS 14. The macOS platform is there so SwiftPM can build and test the SwiftUI package on a Mac host; the product scope remains the native iOS client described in `specs/specs.md`.

## Open the iOS App

- In Finder: open the `swift/` folder and double-click `MoneyHero.xcodeproj`.
- In Terminal on macOS:

```bash
open -a Xcode MoneyHero.xcodeproj
```

## Build and Test

From Terminal on macOS (inside `swift/`):

```bash
swift build
swift test
xcodebuild -project MoneyHero.xcodeproj -scheme MoneyHero -destination 'generic/platform=iOS Simulator' build
```

In Xcode:

- Build: Product -> Build (`Cmd+B`).
- Test: Product -> Test (`Cmd+U`).

## Run

- Select the `MoneyHero` scheme.
- Choose an iOS Simulator destination.
- Run with Product -> Run (`Cmd+R`).

If Xcode prompts for signing to run on a physical device, configure your own team settings locally.

## Verification Note

This Linux dev container can edit files, but it cannot run or verify native iOS execution. Use macOS/Xcode for runtime verification.
