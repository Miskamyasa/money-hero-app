# Architecture

## Current Repo State

The repository contains project documentation, API and admin service folders, and a scaffolded Swift mobile app under `swift/`. Flutter and React Native mobile apps are planned but not scaffolded yet.

## Intended Topology

- Mobile clients: three planned MVP apps, each in its own sibling folder. Swift is scaffolded; Flutter and React Native are not scaffolded yet.
  - `swift/` - native iOS app (scaffolded).
  - `flutter/` - Flutter app for iOS and Android.
  - `react/` - React Native app for iOS and Android.
- API service: Go backend under `api/`, only needed when backend-backed features are introduced. Not part of MVP.
- Admin UI: React/Vite admin app under `admin/`, only needed when admin-facing workflows are introduced. Not part of MVP.
- Docs: shared project documentation under `docs/`.

## Current Architectural Direction

- Mobile user data is local-only. No backend in MVP.
- Yahoo Finance provides current prices and historical market data.
- Desktop product is the behavioral reference for holdings, weights, and dashboard layout.
- Shared contracts and protocols should be documented only when more than one module needs them.
- Service-specific details belong in each service spec, not broad shared docs.

## Service Specs

- `../admin/specs/spec.md` - Admin UI service notes.
- `../api/specs/spec.md` - API service notes.
- `../swift/specs/specs.md` - Swift MVP notes.
- `../flutter/specs/spec.md` - Flutter MVP notes. Not present yet.
- `../react/specs/spec.md` - React Native MVP notes. Not present yet.
