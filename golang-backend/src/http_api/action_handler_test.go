package http_api

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"larko.se/poke/src/domain"
)

func TestCreateAction(t *testing.T) {
	tests := []struct {
		testName       string
		userID         string
		action         domain.Action
		setupMock      func(*MockActionService)
		expectedStatus int
		checkResponse  func(*testing.T, *httptest.ResponseRecorder)
	}{
		{
			testName: "Success",
			userID:   "test-user-123",
			action:   newWaterPlantAction("water-plant", "plant-123", "Monstera"),
			setupMock: func(m *MockActionService) {
				m.On("CreateAction", mock.Anything, "test-user-123", "water-plant-123", mock.MatchedBy(func(a *domain.Action) bool {
					return a.SerializationKey == "water-plant" && a.Plant != nil && a.Plant.ID == "plant-123"
				})).Return(nil)
			},
			expectedStatus: http.StatusCreated,
			checkResponse: func(t *testing.T, w *httptest.ResponseRecorder) {
				response := ParseJSONBody(t, w)
				assert.Equal(t, true, response["success"])
				assert.NotEmpty(t, response["actionId"])
			},
		},
		{
			testName:       "Unauthorized",
			userID:         "",
			action:         arbitraryAction(),
			setupMock:      func(m *MockActionService) {},
			expectedStatus: http.StatusUnauthorized,
			checkResponse: func(t *testing.T, w *httptest.ResponseRecorder) {
				response := ParseJSONBody(t, w)
				assert.Contains(t, response, "error")
			},
		},
		{
			testName: "ServiceError",
			userID:   "test-user-123",
			action:   arbitraryAction(),
			setupMock: func(m *MockActionService) {
				m.On("CreateAction", mock.Anything, "test-user-123", mock.Anything, mock.Anything).
					Return(errors.New("database error"))
			},
			expectedStatus: http.StatusInternalServerError,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
	}

	for _, tt := range tests {
		t.Run(tt.testName, func(t *testing.T) {
			tc := newTestContext(t)
			tt.setupMock(tc.mockService)

			w := tc.authedRequest(http.MethodPost, "/actions", tt.action, tt.userID)

			assert.Equal(t, tt.expectedStatus, w.Code)
			tt.checkResponse(t, w)
			tc.assertExpectations()
		})
	}
}

func TestListActions(t *testing.T) {
	tests := []struct {
		name           string
		userID         string
		setupMock      func(*MockActionService)
		expectedStatus int
		checkResponse  func(*testing.T, *httptest.ResponseRecorder)
	}{
		{
			name:   "Success",
			userID: "test-user-123",
			setupMock: func(m *MockActionService) {
				expectedActions := []*domain.Action{
					{
						SerializationKey: "water-plant",
						Events:           map[string]interface{}{},
						Plant:            &domain.Plant{ID: "plant-1", Name: "Monstera"},
					},
					{
						SerializationKey: "water-plant",
						Events:           map[string]interface{}{},
						Plant:            &domain.Plant{ID: "plant-2", Name: "Pothos"},
					},
				}
				m.On("ListActions", mock.Anything, "test-user-123").Return(expectedActions, nil)
			},
			expectedStatus: http.StatusOK,
			checkResponse: func(t *testing.T, w *httptest.ResponseRecorder) {
				response := ParseJSONBody(t, w)
				assert.Contains(t, response, "actions")
				actions := response["actions"].([]interface{})
				assert.Len(t, actions, 2)
			},
		},
		{
			name:           "Unauthorized",
			userID:         "",
			setupMock:      func(m *MockActionService) {},
			expectedStatus: http.StatusUnauthorized,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
		{
			name:   "ServiceError",
			userID: "test-user-123",
			setupMock: func(m *MockActionService) {
				m.On("ListActions", mock.Anything, "test-user-123").
					Return(nil, errors.New("database connection failed"))
			},
			expectedStatus: http.StatusInternalServerError,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tc := newTestContext(t)
			tt.setupMock(tc.mockService)

			w := tc.authedRequest(http.MethodGet, "/actions", nil, tt.userID)

			assert.Equal(t, tt.expectedStatus, w.Code)
			tt.checkResponse(t, w)
			tc.assertExpectations()
		})
	}
}

func TestGetAction(t *testing.T) {
	tests := []struct {
		name           string
		userID         string
		actionID       string
		setupMock      func(*MockActionService)
		expectedStatus int
		checkResponse  func(*testing.T, *httptest.ResponseRecorder)
	}{
		{
			name:     "Success",
			userID:   "test-user-123",
			actionID: "water-plant-123",
			setupMock: func(m *MockActionService) {
				expectedAction := &domain.Action{
					SerializationKey: "water-plant",
					Events:           map[string]interface{}{},
					Plant:            &domain.Plant{ID: "plant-123", Name: "Monstera"},
				}
				m.On("GetAction", mock.Anything, "test-user-123", "water-plant-123").
					Return(expectedAction, nil)
			},
			expectedStatus: http.StatusOK,
			checkResponse: func(t *testing.T, w *httptest.ResponseRecorder) {
				var response domain.Action
				json.Unmarshal(w.Body.Bytes(), &response)
				assert.Equal(t, "water-plant", response.SerializationKey)
				assert.Equal(t, "plant-123", response.Plant.ID)
			},
		},
		{
			name:           "Unauthorized",
			userID:         "",
			actionID:       "water-plant-123",
			setupMock:      func(m *MockActionService) {},
			expectedStatus: http.StatusUnauthorized,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
		{
			name:     "NotFound",
			userID:   "test-user-123",
			actionID: "nonexistent-id",
			setupMock: func(m *MockActionService) {
				m.On("GetAction", mock.Anything, "test-user-123", "nonexistent-id").Return(nil, nil)
			},
			expectedStatus: http.StatusNotFound,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tc := newTestContext(t)
			tt.setupMock(tc.mockService)

			w := tc.authedRequest(http.MethodGet, "/actions/"+tt.actionID, nil, tt.userID)

			assert.Equal(t, tt.expectedStatus, w.Code)
			tt.checkResponse(t, w)
			tc.assertExpectations()
		})
	}
}

func TestUpdateAction(t *testing.T) {
	tests := []struct {
		name           string
		userID         string
		actionID       string
		action         domain.Action
		setupMock      func(*MockActionService)
		expectedStatus int
		checkResponse  func(*testing.T, *httptest.ResponseRecorder)
	}{
		{
			name:     "Success",
			userID:   "test-user-123",
			actionID: "water-plant-123",
			action:   newWaterPlantAction("water-plant", "plant-123", "Updated Monstera"),
			setupMock: func(m *MockActionService) {
				m.On("UpdateAction", mock.Anything, "test-user-123", "water-plant-123", mock.MatchedBy(func(a *domain.Action) bool {
					return a.Plant != nil && a.Plant.Name == "Updated Monstera"
				})).Return(nil)
			},
			expectedStatus: http.StatusOK,
			checkResponse: func(t *testing.T, w *httptest.ResponseRecorder) {
				response := ParseJSONBody(t, w)
				assert.Equal(t, true, response["success"])
			},
		},
		{
			name:           "Unauthorized",
			userID:         "",
			actionID:       "water-plant-123",
			action:         arbitraryAction(),
			setupMock:      func(m *MockActionService) {},
			expectedStatus: http.StatusUnauthorized,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
		{
			name:     "ServiceError",
			userID:   "test-user-123",
			actionID: "water-plant-123",
			action:   arbitraryAction(),
			setupMock: func(m *MockActionService) {
				m.On("UpdateAction", mock.Anything, "test-user-123", "water-plant-123", mock.Anything).
					Return(errors.New("update failed"))
			},
			expectedStatus: http.StatusInternalServerError,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tc := newTestContext(t)
			tt.setupMock(tc.mockService)

			w := tc.authedRequest(http.MethodPut, "/actions/"+tt.actionID, tt.action, tt.userID)

			assert.Equal(t, tt.expectedStatus, w.Code)
			tt.checkResponse(t, w)
			tc.assertExpectations()
		})
	}
}

func TestDeleteAction(t *testing.T) {
	tests := []struct {
		name           string
		userID         string
		actionID       string
		setupMock      func(*MockActionService)
		expectedStatus int
		checkResponse  func(*testing.T, *httptest.ResponseRecorder)
	}{
		{
			name:     "Success",
			userID:   "test-user-123",
			actionID: "water-plant-123",
			setupMock: func(m *MockActionService) {
				m.On("DeleteAction", mock.Anything, "test-user-123", "water-plant-123").Return(nil)
			},
			expectedStatus: http.StatusOK,
			checkResponse: func(t *testing.T, w *httptest.ResponseRecorder) {
				response := ParseJSONBody(t, w)
				assert.Equal(t, true, response["success"])
			},
		},
		{
			name:           "Unauthorized",
			userID:         "",
			actionID:       "water-plant-123",
			setupMock:      func(m *MockActionService) {},
			expectedStatus: http.StatusUnauthorized,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
		{
			name:     "ServiceError",
			userID:   "test-user-123",
			actionID: "water-plant-123",
			setupMock: func(m *MockActionService) {
				m.On("DeleteAction", mock.Anything, "test-user-123", "water-plant-123").
					Return(errors.New("delete failed"))
			},
			expectedStatus: http.StatusInternalServerError,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tc := newTestContext(t)
			tt.setupMock(tc.mockService)

			w := tc.authedRequest(http.MethodDelete, "/actions/"+tt.actionID, nil, tt.userID)

			assert.Equal(t, tt.expectedStatus, w.Code)
			tt.checkResponse(t, w)
			tc.assertExpectations()
		})
	}
}

func TestLogEvent(t *testing.T) {
	now := time.Now().UTC()

	tests := []struct {
		name           string
		userID         string
		actionID       string
		eventData      map[string]interface{}
		setupMock      func(*MockActionService, time.Time)
		expectedStatus int
		checkResponse  func(*testing.T, *httptest.ResponseRecorder)
	}{
		{
			name:     "Success",
			userID:   "test-user-123",
			actionID: "water-plant-123",
			eventData: map[string]interface{}{
				"when": now.Format(time.RFC3339Nano),
				"data": map[string]interface{}{"notes": "Watered thoroughly"},
			},
			setupMock: func(m *MockActionService, timestamp time.Time) {
				m.On("LogEvent", mock.Anything, "test-user-123", "water-plant-123",
					mock.MatchedBy(func(t time.Time) bool {
						return t.Unix() == timestamp.Unix()
					}),
					mock.MatchedBy(func(data map[string]interface{}) bool {
						return data["notes"] == "Watered thoroughly"
					})).Return(nil)
			},
			expectedStatus: http.StatusCreated,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
		{
			name:     "Unauthorized",
			userID:   "",
			actionID: "water-plant-123",
			eventData: map[string]interface{}{
				"when": now.Format(time.RFC3339Nano),
			},
			setupMock:      func(m *MockActionService, timestamp time.Time) {},
			expectedStatus: http.StatusUnauthorized,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
		{
			name:     "MissingWhen",
			userID:   "test-user-123",
			actionID: "water-plant-123",
			eventData: map[string]interface{}{
				"data": map[string]interface{}{"notes": "Test"},
			},
			setupMock:      func(m *MockActionService, timestamp time.Time) {},
			expectedStatus: http.StatusBadRequest,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
		{
			name:     "InvalidTimestamp",
			userID:   "test-user-123",
			actionID: "water-plant-123",
			eventData: map[string]interface{}{
				"when": "not-a-timestamp",
			},
			setupMock:      func(m *MockActionService, timestamp time.Time) {},
			expectedStatus: http.StatusBadRequest,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
		{
			name:     "ServiceError",
			userID:   "test-user-123",
			actionID: "water-plant-123",
			eventData: map[string]interface{}{
				"when": now.Format(time.RFC3339Nano),
			},
			setupMock: func(m *MockActionService, timestamp time.Time) {
				m.On("LogEvent", mock.Anything, "test-user-123", "water-plant-123", mock.Anything, mock.Anything).
					Return(errors.New("failed to log event"))
			},
			expectedStatus: http.StatusInternalServerError,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tc := newTestContext(t)
			tt.setupMock(tc.mockService, now)

			w := tc.authedRequest(http.MethodPost, "/actions/"+tt.actionID+"/events", tt.eventData, tt.userID)

			assert.Equal(t, tt.expectedStatus, w.Code)
			tt.checkResponse(t, w)
			tc.assertExpectations()
		})
	}
}

func TestDeleteEvent(t *testing.T) {
	now := time.Now().UTC()
	timestamp := now.Format(time.RFC3339Nano)

	tests := []struct {
		name           string
		userID         string
		actionID       string
		timestamp      string
		setupMock      func(*MockActionService, time.Time)
		expectedStatus int
		checkResponse  func(*testing.T, *httptest.ResponseRecorder)
	}{
		{
			name:      "Success",
			userID:    "test-user-123",
			actionID:  "water-plant-123",
			timestamp: timestamp,
			setupMock: func(m *MockActionService, t time.Time) {
				m.On("DeleteEvent", mock.Anything, "test-user-123", "water-plant-123",
					mock.MatchedBy(func(time time.Time) bool {
						return time.Unix() == t.Unix()
					})).Return(nil)
			},
			expectedStatus: http.StatusOK,
			checkResponse: func(t *testing.T, w *httptest.ResponseRecorder) {
				response := ParseJSONBody(t, w)
				assert.Equal(t, true, response["success"])
			},
		},
		{
			name:           "Unauthorized",
			userID:         "",
			actionID:       "water-plant-123",
			timestamp:      timestamp,
			setupMock:      func(m *MockActionService, t time.Time) {},
			expectedStatus: http.StatusUnauthorized,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
		{
			name:           "InvalidTimestamp",
			userID:         "test-user-123",
			actionID:       "water-plant-123",
			timestamp:      "invalid-timestamp",
			setupMock:      func(m *MockActionService, t time.Time) {},
			expectedStatus: http.StatusBadRequest,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
		{
			name:      "ServiceError",
			userID:    "test-user-123",
			actionID:  "water-plant-123",
			timestamp: timestamp,
			setupMock: func(m *MockActionService, t time.Time) {
				m.On("DeleteEvent", mock.Anything, "test-user-123", "water-plant-123", mock.Anything).
					Return(errors.New("failed to delete event"))
			},
			expectedStatus: http.StatusInternalServerError,
			checkResponse:  func(t *testing.T, w *httptest.ResponseRecorder) {},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tc := newTestContext(t)
			tt.setupMock(tc.mockService, now)

			w := tc.authedRequest(http.MethodDelete, "/actions/"+tt.actionID+"/events/"+tt.timestamp, nil, tt.userID)

			assert.Equal(t, tt.expectedStatus, w.Code)
			tt.checkResponse(t, w)
			tc.assertExpectations()
		})
	}
}
