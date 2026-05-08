# AI Agents Guide

## Getting Started

Your memory resets between sessions. Read ALL relevant documentation at the start of EVERY task. Never assume knowledge from previous sessions.

## Documentation

All information specific to a service must live in that service's specs file. A developer working on a service should not need to read contracts or protocols for other services if those do not apply to their work. If a contract or protocol applies to only one service, document it only in that service's spec.

References must be minimal and precise. Each reference must point directly to the exact location to read. Do not link to broad documents, sections, or pages that require scanning. Avoid any unnecessary context or noise in references.

### Sources

- `docs/brief.md` - Project mission, goals, non-goals
- `docs/product.md` - Product vision, target users, solution overview
- `docs/architecture.md` - System architecture and module topology
- `docs/definitions.md` - Canonical terminology and ID conventions
- `docs/contracts.md` - Shared contracts index and module pointers
- `docs/protocols.md` - Shared cross-module protocol definitions
- `docs/sync.md` - Client-server sync protocol and snapshot schema
- `docs/analytics.md` - Analytics event ingestion spec and event catalog
- `docs/open-questions.md` - Undecided product questions
- `README.md` - Project overview, setup, and license

## Project Overview

Money Hero mobile is a portfolio balance tracker for iOS and Android. 

### Tooling (managed via mise)

Versions pinned in `mise.toml`: Go 1.26.2, golangci-lint 2.11.4, Node 24.14.0, pnpm 10.33.2
