# API Spec

## Status

The API service is a placeholder. No implementation exists yet.

The current mobile product direction is local-only, so no backend API is required for the core tracker.

## Stack

- Go
- `gofmt` formatting
- `golangci-lint` with the rules described in `AGENTS.md`

## Documentation Ownership

API-only endpoints, request/response shapes, persistence details, and service behavior should be documented here.

Shared contracts used by the API and another module should be indexed in `../docs/contracts.md` with a precise pointer back to the owning spec or implementation.

## Open Items

- Define whether sync, auth, analytics, or admin features require a backend.
- Define API routes only after a backend-backed product requirement exists.
- Define database schema only after backend persistence is needed.
