## Stack

React 18, Vite, Mantine 9 (UI), TanStack Query (data fetching), React Router 6, Recharts (charts).

## Code Style -- Admin UI (TypeScript/React)

### General

- **Strict TypeScript** (`strict: true`, `noUnusedLocals`, `noUnusedParameters`).
- **No semicolons** (`@stylistic/semi: never`).
- **Double quotes** for strings.
- **2-space indentation**.
- **Max line length**: 120 characters (warning).
- **No default exports** (`import-x/no-default-export: error`).
- **Type definitions**: use `type` not `interface` (`consistent-type-definitions: ["error", "type"]`).

### Imports

- Sorted alphabetically, grouped: builtin > external > internal > parent > sibling.
- React imports come first among externals.
- Newline between groups. No duplicate imports. No circular dependencies.
- Unused imports are auto-removed (`unused-imports/no-unused-imports: error`).

## Code Style

Enforced by **@miskamyasa/eslint-config** (flat config in `eslint.config.js`). The shared config bundles TypeScript strict type checking, React + React Hooks, import ordering/validation, and stylistic rules — there is no Prettier and no separate TypeScript-ESLint config.

If you see an ESLint error, fix it by running `pnpm lint:fix` before making manual changes. Change code manually only if auto-fix can't handle it.
