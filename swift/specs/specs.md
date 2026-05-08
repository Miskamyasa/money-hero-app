# Swift Spec

## Status

The Swift app now has an MVP scaffold with source and test files.

This service is the native iOS client planned under `swift/` per the repository topology in `../../docs/architecture.md:9` and `../../docs/architecture.md:10`.

## MVP Scope

- Native iOS target only.
- The Swift package also declares a macOS build baseline for local SwiftPM/Xcode build and test support on a Mac host; it does not add a macOS product requirement.
- Local-only user data and cache storage on device; no backend dependency for core tracker behavior (`../../docs/architecture.md:19`, `../../docs/sync.md:5`, `../../docs/sync.md:7`).
- Yahoo Finance is the only market-data provider in MVP (`../../docs/architecture.md:20`, `../../docs/protocols.md:11`).

## Shared References

- Cross-client normalized data contracts: `../../docs/contracts.md:1` and `../../docs/contracts.md:3`.
- Cross-module retrieval and persistence protocols: `../../docs/protocols.md:3` and `../../docs/protocols.md:5`.

Service-specific Swift implementation details should be defined in this spec directory and should reference shared docs instead of duplicating cross-module definitions.

## Explicit Exclusions

The current Swift scaffold excludes:

- Backend API integration (`../../docs/architecture.md:13`, `../../api/specs/spec.md:5`, `../../api/specs/spec.md:7`).
- Sync/account or multi-device behavior (`../../docs/sync.md:5`, `../../docs/sync.md:7`).
- Analytics collection or ingestion (`../../docs/analytics.md:5`, `../../docs/analytics.md:7`).
- Admin workflows and admin UI dependencies (`../../docs/architecture.md:14`).

## External Prerequisite

Generating and validating iOS project/build outputs requires macOS with Xcode installed. Linux environments can edit docs and source files but cannot verify native iOS project generation/build locally.
