# Architecture

## Current Repo State

The mobile app implementation is not scaffolded yet. The repository currently contains documentation plus placeholder service folders for `api` and `admin`.

## Intended Topology

- Mobile clients: three planned MVP apps, each in its own sibling folder. None scaffolded yet.
  - `swift/` - native iOS app.
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

- `../admin/spec.md` - Admin UI service notes.
- `../api/spec.md` - API service notes.
- `../swift/spec.md` - Swift MVP notes. Not present yet.
- `../flutter/spec.md` - Flutter MVP notes. Not present yet.
- `../react/spec.md` - React Native MVP notes. Not present yet.
