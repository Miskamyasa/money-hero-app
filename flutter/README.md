# Flutter Scaffold

This folder contains the Flutter scaffold for the Money Hero native mobile client.

Service scope and constraints are defined in `specs/spec.md`.

## Prerequisites

- Flutter SDK installed and available on `PATH`.
- iOS and Android platform toolchains installed (for example, Xcode and Android SDK).

Signing and provisioning are not configured in this scaffold.

## Setup

From Terminal (inside `flutter/`):

```bash
flutter pub get
```

## Test

From Terminal (inside `flutter/`):

```bash
flutter test
```

## Run

From Terminal (inside `flutter/`), choose a connected device or simulator/emulator and run:

```bash
flutter run
```

## Verification Note

This Linux dev container can edit files and run Dart/Flutter unit tests, but it cannot verify native iOS execution. Validate iOS runtime flows on macOS with Xcode and validate Android runtime flows with a configured Android SDK plus emulator/device.
