# Poke Backend (Go)

REST API backend for the Poke app, providing action tracking and reminder functionality.

## Overview

This backend serves as a REST API wrapper around Firebase services (Firestore, Storage, Auth). It replaces direct Firebase access from the Flutter app and enables CLI tool development.

**Tech Stack**:
- Language: Go 1.22+
- Framework: gin-gonic/gin
- Database: Firebase Firestore
- Storage: Firebase Storage
- Auth: Firebase Auth (ID token verification)

## Quick Start

1. **Setup** (one-time):
   ```bash
   # Install dependencies
   go mod download

   # Create environment file
   cp .env.example .env  # Edit with your values

   # Download Firebase service account key
   # See IMPLEMENTATION_GUIDE.md Step 2 for instructions
   # Save as serviceAccountKey.json
   ```

2. **Run**:
   ```bash
   # Run directly
   go run ./cmd/api/main.go

   # Or build and run binary
   go build -o bin/poke-backend ./cmd/api
   ./bin/poke-backend
   ```

3. **Test**:
   ```bash
   curl http://localhost:8080/health
   # Expected: {"status":"ok"}
   ```

## Project Status

- [x] Phase 0: Project Setup ✅
- [x] Phase 1: Core Actions API ✅ (7/7 endpoints implemented)
- [ ] Phase 2: Advanced Features
- [ ] Phase 3: Production Hardening

See [Implementation Phases](../BACKEND_PLAN.md#implementation-phases) for details.

## API Documentation

Base URL: `http://localhost:8080/v1`

### Endpoints (Planned)

| Method | Endpoint | Description | Status |
|--------|----------|-------------|--------|
| POST   | `/v1/actions` | Create action | ✅ Implemented |
| GET    | `/v1/actions` | List actions | ✅ Implemented |
| GET    | `/v1/actions/:id` | Get action | ✅ Implemented |
| PUT    | `/v1/actions/:id` | Update action | ✅ Implemented |
| DELETE | `/v1/actions/:id` | Delete action | ✅ Implemented |
| POST   | `/v1/actions/:id/events` | Log event | ✅ Implemented |
| DELETE | `/v1/actions/:id/events/:timestamp` | Delete event | ✅ Implemented |
| GET    | `/v1/reminders` | Get reminders | ⏳ Planned |
| POST   | `/v1/data` | Upload image | ⏳ Planned |
| GET    | `/v1/data/:key` | Download image | ⏳ Planned |

**All endpoints** (except `/health`) require `Authorization: Bearer <firebase-token>` header.

For complete API specification, see [BACKEND_PLAN.md](../BACKEND_PLAN.md).

## Development

### Prerequisites

- Go 1.22 or later
- Firebase project with Firestore and Storage enabled
- Service account key JSON file

### Project Structure

```
golang-backend/
├── cmd/api/                    # Entry point
│   └── main.go                # Server initialization
├── internal/
│   ├── api/                   # HTTP Layer
│   │   ├── handlers/          # Request handlers
│   │   ├── middleware/        # Auth, CORS, etc.
│   │   └── router/            # Route definitions
│   ├── core/                  # Business Logic
│   │   ├── domain/            # Domain models
│   │   └── ports/             # Service interfaces
│   ├── service/               # Service implementations
│   ├── repository/            # Data access layer
│   └── config/                # Configuration
└── pkg/                       # Public packages
    └── response/              # API response helpers
```

### Environment Variables

```bash
FIREBASE_CREDENTIALS_PATH=./serviceAccountKey.json
PORT=8080
GIN_MODE=debug  # or "release"
CORS_ENABLED=false
MAX_UPLOAD_SIZE_MB=10
```

### Commands

```bash
# Run server
go run ./cmd/api/main.go

# Format code
go fmt ./...

# Lint
go vet ./...

# Run tests
go test ./...

# Build binary
go build -o bin/poke-backend ./cmd/api
```

## Testing

### Manual Testing

```bash
# Health check
curl http://localhost:8080/health

# Test auth (requires valid Firebase token)
TOKEN="<your-firebase-token>"
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/v1/actions
```

### Getting a Firebase Token

From Flutter app, print the token:
```dart
final token = await FirebaseAuth.instance.currentUser?.getIdToken();
print(token);
```

Or use Firebase Auth REST API to get a token programmatically.

## Deployment

(TODO: Add deployment instructions for your target environment)

## Contributing

1. Follow Go conventions (use `go fmt`)
2. Write tests for new handlers
3. Update BACKEND_PLAN.md if changing API contracts
4. Test with real Firebase tokens before committing

## Documentation

- [BACKEND_PLAN.md](../BACKEND_PLAN.md) - Complete API specification
- [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) - Step-by-step setup
- [Phase 0 Setup](#quick-start) - Get started quickly

## License

(Same as parent project)
