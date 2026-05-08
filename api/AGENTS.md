
## Code Style -- Go

### Imports

Use goimports-style grouping with a blank line between groups:
1. Standard library
2. Third-party packages
3. Internal project packages (`github.com/Miskamyasa/money-hero-app/api/internal/...`)

When a package name conflicts with a local identifier, use a descriptive alias (e.g., `syncmodule` for `internal/sync`).

### Formatting

Standard `gofmt`. No custom formatter. The linter config (`.golangci.yml`) enables: errcheck, govet, ineffassign, staticcheck, unused.

### Naming Conventions

- **Packages**: lowercase, single-word (e.g., `sync`, `auth`, `admin`, `database`, `logging`).
- **Exported types**: PascalCase. Handler structs are named `Handler` within their package.
- **Constructors**: `NewHandler(db *sql.DB) *Handler`, `NewRepository(db *sql.DB) *Repository`.
- **HTTP handler methods**: receiver on `*Handler`, signature `(w http.ResponseWriter, r *http.Request)`.
- **Context keys**: typed `ContextKey string` constants (e.g., `UserIDKey`, `AdminIDKey`).
- **Unexported helpers**: camelCase (e.g., `writeJSON`, `writeError`, `userIDFromContext`).

### Types and Structs

- Use typed string constants for enums (e.g., `type VolumeTrend string` with `VolumeTrendUp`, `VolumeTrendDown`).
- JSON tags use camelCase (e.g., `json:"skillId"`, `json:"workoutId"`).
- Use `json:"...,omitempty"` for optional pointer fields.
- Request/response types live in contracts files (e.g., `internal/sync/contracts.go`).
- Use `json.RawMessage` for opaque JSON blobs stored in the database.

### Error Handling

- Wrap errors with `fmt.Errorf("context: %w", err)` -- always include a module/function prefix.
- Pattern: `"module: operation: %w"` (e.g., `"database: open: %w"`, `"sync repository: get snapshot: %w"`).
- On resource cleanup failure during error paths, report both errors: `fmt.Errorf("main error: %w (close error: %v)", err, closeErr)`.
- HTTP handlers: log internal errors via `logging.Logger().Error().Err(err).Msg(...)`, return generic `"internal server error"` to clients.
- Never expose internal error details in HTTP responses.
- Use `errors.Is()` and `errors.As()` for sentinel/typed error checks.

### Logging

Use `zerolog` via `logging.Logger()`. Structured fields with `.Str()`, `.Int()`, `.Err()`. Levels: `Fatal`, `Error`, `Info`, `Debug`.

### Database
