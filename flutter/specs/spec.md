# Flutter MVP Spec

## MVP Scope

- Native mobile targets: iOS and Android.
- Local-only user data and cache storage on device; no backend dependency for core tracker behavior (`../../docs/architecture.md:19`, `../../docs/sync.md:5`, `../../docs/sync.md:7`).
- Yahoo Finance is the only market-data provider in MVP (`../../docs/architecture.md:20`, `../../docs/protocols.md:11`).

## Shared References

- Cross-client normalized data contracts: `../../docs/contracts.md:1` and `../../docs/contracts.md:3`.
- Cross-module retrieval and persistence protocols: `../../docs/protocols.md:3` and `../../docs/protocols.md:5`.

Service-specific Flutter implementation details should be defined in this spec directory and should reference shared docs instead of duplicating cross-module definitions.

## Explicit Exclusions

The current Flutter scaffold excludes:

- Backend API integration (`../../docs/architecture.md:19`, `../../docs/architecture.md:22`, `../../api/specs/spec.md:5`, `../../api/specs/spec.md:7`).
- Sync/account or multi-device behavior (`../../docs/sync.md:5`, `../../docs/sync.md:7`).
- Analytics collection or ingestion (`../../docs/analytics.md:5`, `../../docs/analytics.md:7`).
- Admin workflows and admin UI dependencies (`../../docs/architecture.md:14`).

## External Prerequisite

Generating and validating Flutter mobile project/build outputs requires the Flutter SDK plus iOS and Android platform toolchains (for example, Xcode and Android SDK).
