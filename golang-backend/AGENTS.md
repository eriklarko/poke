# AGENTS.md

> **MISSION**: You are a Principal Golang Engineer assisting with a Reminder App HTTP Server.
> **STACK**: Go (1.22+), Gin Web Framework, Firebase (Auth & Firestore).
> **CONTEXT**: This is a production-grade backend. We prioritize type safety, idiomatic Go, and clean architecture over ease of writing.

## @Map: Project Structure
- `/cmd/api`: Entry point. `main.go` initializes deps and starts server.
- `/internal/api`: HTTP Layer. Handlers, Middleware, Router setup.
- `/internal/core`: Business Logic. Domain Models (`/domain`) and Service Ports (`/ports`).
- `/internal/service`: Service Implementations. Pure Go logic.
- `/internal/repository`: Data Access Layer (Firebase implementations).
- `/pkg`: Public shared libraries (helpers, validators).

## @Workflow: Commands
* **Run Dev**: `go run ./cmd/api/main.go`
* **Test All**: `go test -v -race ./...`
* **Test Short**: `go test -short ./...`
* **Mod Tidy**: `go mod tidy`

## @ArchitecturalRules (CRITICAL)
1.  **No Logic in Handlers**: Gin handlers (`func(*gin.Context)`) must ONLY parse requests, call a Service, and map responses. NEVER put business logic or DB calls inside a handler.
2.  **Dependency Injection**: All dependencies (services, repositories, firebase clients) must be injected via struct fields or constructor functions. Do not use global state.
3.  **Interface-First**: Services define interfaces in `/internal/core/ports`. Repositories implement interfaces defined by the Domain.
4.  **Consumer-Side Interfaces**: Following the Dependency Inversion Principle, the consumer (e.g., Service) should declare the interface it needs, not the provider (Repository). This keeps dependencies pointing inward toward the domain.
5.  **Firebase Isolation**: Do not import `firebase.google.com/go` in `/internal/core`. The core domain must be agnostic of the storage technology. Isolate Firebase code to `/internal/repository`.
6.  **Never ignore errors**: Never ever ever ignore errors! Return them for as long as you can, wrapping them with good context. At the last layer possible, we log the error.

## @CodingStandards

> ⛔ **ABSOLUTE RULE — NO EXCEPTIONS**: Every `5xx` HTTP response MUST be preceded by a `slog.Error(...)` call that includes the **actual `err` value**. Returning a 500 with zero log output is a critical bug. The pattern is always:
> ```go
> slog.Error("failed to <operation>", "error", err, "userID", userID)
> response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "...")
> ```
> Violating this makes the server completely undebuggable in production and will be rejected in code review.

* **No Deprecation**: Never leave deprecated or backwards-compatible shim code. Delete the old function/type and update all call sites immediately. A build failure is preferable to accumulating dead weight.
* **Error Handling**: Use `errors.Is` and `errors.As`. Wrap errors with context: `fmt.Errorf("failed to create reminder: %w", err)`. NEVER just return `err` if context can be added.
* **Never Ignore Errors**: NEVER swallow errors silently. If you can't return an error, at least log it with `log/slog`. We'd much rather have errors in logs than have them disappear into the void.
* **Always Log Errors**: When returning generic error messages to users (for security/UX), always log the actual error details server-side first using structured logging (`log/slog`).
* **Journal Order**: Helper functions should appear immediately after their first use, not at the top or bottom of the file. This makes code easier to read top-to-bottom.
* **Extract Helpers from functions**: Keep functions concise and declarative. Extract logic into separate helper functions with clear names.
* **Document Time Formats**: When validating time formats, include concrete examples in error messages (e.g., "Expected RFC3339Nano (e.g., 2026-02-16T15:45:30.123456789Z)").
* **JSON Tags**: All API structs must have `json` tags. Use camelCase for JSON fields.
* **Firestore Tags**: All DB structs must have `firestore` tags.
* **Context Propagation**: Always pass `ctx context.Context` from the Gin handler down to the Repository layer.
* **Config**: Use `viper` or `godotenv` for configuration. accessing `os.Getenv` directly is forbidden outside of `config` package.

## @GinSpecifics
* **Binding**: Use `ShouldBindJSON` and check errors immediately.
* **Response**: Use a standardized response helper (e.g., `api.Success(c, data)` or `api.Error(c, status, err)`). Do not manually construct `c.JSON` in every handler.
* **Middleware**: Auth validation happens in middleware. It injects the user ID into the context via `c.Set("userID", uid)`.

## @FirebaseSpecifics
* **Auth**: Validate tokens in Middleware using Firebase Auth SDK.
* **Types**: Firestore documents map to strictly typed Go structs. Do not use `map[string]interface{}` unless absolutely necessary for partial updates.
* **Collections**: Define collection names as constants in the Repository package.

## @TestingStrategy
* **Unit Tests**: Test Services using mocked Repositories (use `stretchr/testify/mock`).
* **Integration Tests**: Test Handlers using `httptest` and mocked Services.
* **Table-Driven**: Use table-driven tests for all logic.

## @AgentBehavior
* **Refactoring**: If you change a generic interface, check all implementations.
* **Safety**: If you see a `panic`, remove it. We handle errors gracefully.
* **Completeness**: When generating a new feature (e.g., "Create Reminder"), generate the **Handler**, **Service Interface**, **Service Implementation**, and **Repository Interface** in one go.
