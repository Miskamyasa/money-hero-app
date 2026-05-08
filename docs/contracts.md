# Contracts

## Status

No shared cross-module contracts are defined yet.

The current mobile direction is local-only, so there is no required client-server API contract for the core tracker.

## Contract Ownership

- Shared contracts that affect multiple modules should be indexed here.
- Service-specific contracts should live in that service's spec.
- API request and response shapes belong in `../api/spec.md` until they become shared cross-module contracts.
- Admin-only contracts belong in `../admin/spec.md`.

## Likely Future Contracts

- Market quote shape.
- Historical price shape.
- Local cache metadata shape.
- Portfolio snapshot shape, if sync is introduced.
- Analytics event shape, if analytics is introduced.
