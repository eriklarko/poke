# Contributing to Poke

## Development Decisions

All major technical decisions are documented in markdown files, not just in comments or memory.

### Key Documents

- **[BACKEND_PLAN.md](BACKEND_PLAN.md)** - REST API specification, data models, and answered questions
- **[golang-backend/README.md](golang-backend/README.md)** - Backend overview and quick start
- **[golang-backend/IMPLEMENTATION_GUIDE.md](golang-backend/IMPLEMENTATION_GUIDE.md)** - Step-by-step Phase 0 setup

### Decision Log

#### Backend Technology Stack
- **Language**: Go 1.22+
- **HTTP Framework**: gin-gonic/gin
- **Firebase Library**: Official Firebase Admin SDK (`firebase.google.com/go/v4`)
- **Rationale**: Performance, official support, single SDK for auth + database + storage

#### API Design
- **Base Path**: `/v1/` for all endpoints (future-proof)
- **Auth**: Firebase ID tokens in `Authorization: Bearer <token>` header
- **Pagination**: Cursor-based (Firestore query cursors)
- **Error Format**: Structured JSON with `error.code` and `error.message`

#### Authentication Strategy
- **App**: Firebase Auth → Get ID token → Send to backend
- **CLI**: API keys (Phase 2) generated in app, stored in `~/.poke/credentials.json`
- **Backend**: Verify tokens using Firebase Admin SDK, extract user ID
- **Security**: HTTPS required, tokens expire after 1 hour

#### Persistence Strategy
- **Phase 1**: Backend continues using Firebase Firestore (no migration)
- **Future**: Could migrate to PostgreSQL or other database
- **Storage**: Continue using Firebase Storage for images

## Development Workflow

### Adding New Endpoints

1. **Update BACKEND_PLAN.md**:
   - Add endpoint specification
   - Define request/response formats
   - List error cases
   - Add to Implementation Phases

2. **Implement in Go**:
   - Add handler in appropriate `handlers/*.go` file
   - Add route to `main.go`
   - Follow error format from `models/error.go`
   - Use `userID` from context (set by auth middleware)

3. **Test**:
   - Manual test with `curl` and real Firebase token
   - Add to integration test suite (Phase 3)
   - Verify against Flutter app behavior

4. **Update Documentation**:
   - Mark endpoint as implemented in README
   - Add example to IMPLEMENTATION_GUIDE if needed

### Code Style

#### Go
```bash
# Format before committing
go fmt ./...

# Check for issues
go vet ./...

# Run tests
go test ./...
```

Follow standard Go conventions:
- Exported names start with capital letter
- Use descriptive variable names
- Handle all errors explicitly
- Use context for cancellation

#### Flutter/Dart
```bash
# Format
dart format .

# Analyze
flutter analyze

# Test
flutter test
```

Follow Dart style guide and existing patterns in codebase.

## Testing Strategy

### Phase 1: Manual Testing
- Use `curl` with real Firebase tokens
- Test happy paths and error cases
- Verify data in Firebase Console

### Phase 2: Integration Tests
- Automated tests with test Firebase project
- Test all endpoints sequentially
- Verify predictor algorithm accuracy

### Phase 3: Load Testing
- Simulate 100 concurrent users
- Test with 1000+ actions per user
- Measure response times

## Commit Guidelines

Use conventional commit messages:
```
feat(backend): implement GET /v1/actions endpoint
fix(auth): handle expired tokens correctly
docs(api): update pagination examples
chore(deps): update gin to v1.9.0
```

**Scope examples**: backend, flutter, auth, predictor, docs, deps

## Questions?

When adding new features or making architectural decisions:

1. Document the decision in the appropriate markdown file
2. Update BACKEND_PLAN.md if it affects API contracts
3. Keep README files in sync with implementation status
4. Create new markdown docs for complex features

**Remember: Files > Memory**. If it's important, write it down.
