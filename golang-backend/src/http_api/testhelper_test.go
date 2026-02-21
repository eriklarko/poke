package http_api

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
	"larko.se/poke/src/domain"
)

// MockActionService is a mock implementation of ActionService
type MockActionService struct {
	mock.Mock
}

func (m *MockActionService) CreateAction(ctx context.Context, userID string, actionID string, action *domain.Action) error {
	args := m.Called(ctx, userID, actionID, action)
	return args.Error(0)
}

func (m *MockActionService) GetAction(ctx context.Context, userID string, actionID string) (*domain.Action, error) {
	args := m.Called(ctx, userID, actionID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.Action), args.Error(1)
}

func (m *MockActionService) ListActions(ctx context.Context, userID string) ([]*domain.Action, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*domain.Action), args.Error(1)
}

func (m *MockActionService) UpdateAction(ctx context.Context, userID string, actionID string, action *domain.Action) error {
	args := m.Called(ctx, userID, actionID, action)
	return args.Error(0)
}

func (m *MockActionService) DeleteAction(ctx context.Context, userID string, actionID string) error {
	args := m.Called(ctx, userID, actionID)
	return args.Error(0)
}

func (m *MockActionService) LogEvent(ctx context.Context, userID string, actionID string, when time.Time, data map[string]interface{}) error {
	args := m.Called(ctx, userID, actionID, when, data)
	return args.Error(0)
}

func (m *MockActionService) DeleteEvent(ctx context.Context, userID string, actionID string, when time.Time) error {
	args := m.Called(ctx, userID, actionID, when)
	return args.Error(0)
}

func (m *MockActionService) ListReminders(ctx context.Context, userID string) ([]*domain.Reminder, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*domain.Reminder), args.Error(1)
}

// setupTestRouter creates a test router for handlers. Kept for compatibility with existing tests.
func setupTestRouter(handler *ActionHandler) *gin.Engine {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	return router
}

// setupAuthenticatedRoute registers a route with a handler.
func setupAuthenticatedRoute(router *gin.Engine, method, path string, handler gin.HandlerFunc) {
	switch method {
	case http.MethodGet:
		router.GET(path, handler)
	case http.MethodPost:
		router.POST(path, handler)
	case http.MethodPut:
		router.PUT(path, handler)
	case http.MethodDelete:
		router.DELETE(path, handler)
	default:
		router.Handle(method, path, handler)
	}
}

// DoRequest builds and executes an HTTP request against the provided router and returns the recorder.
// headers may be nil.
func DoRequest(router *gin.Engine, method, path string, body []byte, headers map[string]string) *httptest.ResponseRecorder {
	var b *bytes.Buffer
	if body != nil {
		b = bytes.NewBuffer(body)
	} else {
		b = &bytes.Buffer{}
	}
	req := httptest.NewRequest(method, path, b)
	for k, v := range headers {
		req.Header.Set(k, v)
	}
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	return w
}

// ParseJSONBody asserts and returns a parsed JSON body as a map
func ParseJSONBody(t *testing.T, w *httptest.ResponseRecorder) map[string]interface{} {
	var m map[string]interface{}
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &m))
	return m
}

// testContext encapsulates test dependencies to reduce boilerplate
type testContext struct {
	t           *testing.T
	mockService *MockActionService
	handler     *ActionHandler
	router      *gin.Engine
}

// newTestContext creates a new test context with mock service, handler, and router.
// All standard routes are registered automatically.
func newTestContext(t *testing.T) *testContext {
	mockService := new(MockActionService)
	handler := NewActionHandler(mockService, "")
	gin.SetMode(gin.TestMode)
	router := gin.New()

	tc := &testContext{
		t:           t,
		mockService: mockService,
		handler:     handler,
		router:      router,
	}

	// Register all routes upfront - this matches the actual API setup
	tc.registerAllRoutes("")

	return tc
}

// registerAllRoutes registers all action handler routes.
func (tc *testContext) registerAllRoutes(userID string) {
	tc.handler = NewActionHandler(tc.mockService, userID)
	tc.router.POST("/actions", tc.handler.CreateAction)
	tc.router.GET("/actions", tc.handler.ListActions)
	tc.router.GET("/actions/:actionId", tc.handler.GetAction)
	tc.router.PUT("/actions/:actionId", tc.handler.UpdateAction)
	tc.router.DELETE("/actions/:actionId", tc.handler.DeleteAction)
	tc.router.POST("/actions/:actionId/events", tc.handler.LogEvent)
	tc.router.DELETE("/actions/:actionId/events/:timestamp", tc.handler.DeleteEvent)
}

// withAuth returns a new test context with the given user ID.
func (tc *testContext) withAuth(userID string) *testContext {
	tc.router = gin.New()
	gin.SetMode(gin.TestMode)
	tc.registerAllRoutes(userID)
	return tc
}

// setupRoute registers a route with optional authentication
func (tc *testContext) setupRoute(method, path string, handlerFunc gin.HandlerFunc) {
	setupAuthenticatedRoute(tc.router, method, path, handlerFunc)
}

// doJSON makes a JSON request and returns the response recorder
func (tc *testContext) doJSON(method, path string, body interface{}) *httptest.ResponseRecorder {
	var bodyBytes []byte
	if body != nil {
		bodyBytes, _ = json.Marshal(body)
	}
	headers := map[string]string{"Content-Type": "application/json"}
	return DoRequest(tc.router, method, path, bodyBytes, headers)
}

// doRequest makes a request without body marshaling
func (tc *testContext) doRequest(method, path string) *httptest.ResponseRecorder {
	return DoRequest(tc.router, method, path, nil, nil)
}

// expectStatus asserts the HTTP status code
func (tc *testContext) expectStatus(w *httptest.ResponseRecorder, expectedStatus int) {
	require.Equal(tc.t, expectedStatus, w.Code)
}

// expectSuccess asserts status and returns the success field from JSON response
func (tc *testContext) expectSuccess(w *httptest.ResponseRecorder, expectedStatus int) bool {
	tc.expectStatus(w, expectedStatus)
	response := ParseJSONBody(tc.t, w)
	success, ok := response["success"].(bool)
	require.True(tc.t, ok, "response should have success field")
	return success
}

// assertExpectations verifies all mock expectations were met
func (tc *testContext) assertExpectations() {
	tc.mockService.AssertExpectations(tc.t)
}

// authedRequest makes an authenticated HTTP request and returns the response.
// Routes must already be registered with authentication via withAuth().
func (tc *testContext) authedRequest(method, path string, body interface{}, userID string) *httptest.ResponseRecorder {
	// Re-register routes with this user's authentication
	tc.withAuth(userID)

	if body != nil {
		return tc.doJSON(method, path, body)
	}
	return tc.doRequest(method, path)
}

// unauthedRequest makes an unauthenticated HTTP request and returns the response
func (tc *testContext) unauthedRequest(method, path string, body interface{}) *httptest.ResponseRecorder {
	return tc.authedRequest(method, path, body, "")
}

// arbitraryAction creates a generic action for tests that don't care about specific fields
func arbitraryAction() *domain.Action {
	a, err := domain.NewAction("", "test", nil, nil)
	if err != nil {
		panic(fmt.Sprintf("failed to create action: %v", err))
	}
	return a
}

func mustNewAction(id, serializationKey string, events, metadata map[string]interface{}) *domain.Action {
	a, err := domain.NewAction(id, serializationKey, events, metadata)
	if err != nil {
		panic(fmt.Sprintf("failed to create action: %v", err))
	}
	return a
}
