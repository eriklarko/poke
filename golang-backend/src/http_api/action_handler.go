package http_api

import (
	"context"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/segmentio/ksuid"
	"larko.se/poke/src/domain"
	"larko.se/poke/src/utils"
)

// ActionService is the subset of service.ActionService used by ActionHandler.
type ActionService interface {
	CreateAction(ctx context.Context, userID string, actionID string, action *domain.Action) error
	GetAction(ctx context.Context, userID string, actionID string) (*domain.Action, error)
	ListActions(ctx context.Context, userID string) ([]*domain.Action, error)
	UpdateAction(ctx context.Context, userID string, actionID string, action *domain.Action) error
	DeleteAction(ctx context.Context, userID string, actionID string) error
	LogEvent(ctx context.Context, userID string, actionID string, when time.Time, data map[string]interface{}) error
	DeleteEvent(ctx context.Context, userID string, actionID string, when time.Time) error
}

// ActionHandler handles HTTP requests for actions.
type ActionHandler struct {
	service ActionService
	userID  string
}

// NewActionHandler creates a new action handler for the given authenticated user.
func NewActionHandler(service ActionService, userID string) *ActionHandler {
	return &ActionHandler{
		service: service,
		userID:  userID,
	}
}

// CreateAction handles POST /v1/actions
func (h *ActionHandler) CreateAction(c *gin.Context) {
	userID := h.userID
	if userID == "" {
		Error(c, http.StatusUnauthorized, "UNAUTHORIZED", "User ID not found in context")
		return
	}

	var action domain.Action
	if err := c.ShouldBindJSON(&action); err != nil {
		Error(c, http.StatusBadRequest, "INVALID_REQUEST", "Invalid action data: "+err.Error())
		return
	}

	// Validate required fields
	if action.SerializationKey == "" {
		Error(c, http.StatusBadRequest, "MISSING_SERIALIZATION_KEY", "serializationKey is required")
		return
	}

	// Derive action ID from the action data
	actionID := deriveActionID(&action)
	if actionID == "" {
		Error(c, http.StatusBadRequest, "INVALID_ACTION", "Could not derive action ID from action data")
		return
	}

	// Initialize events if nil
	if action.Events == nil {
		action.Events = make(map[string]interface{})
	}

	if err := h.service.CreateAction(c.Request.Context(), userID, actionID, &action); err != nil {
		if strings.Contains(err.Error(), "already exists") {
			Error(c, http.StatusConflict, "ACTION_EXISTS", "Action with this ID already exists")
			return
		}
		slog.Error("failed to create action", "error", err, "userID", userID, "actionID", actionID)
		Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to create action")
		return
	}

	Success(c, http.StatusCreated, gin.H{
		"success":  true,
		"actionId": actionID,
	})
}

// ListActions handles GET /v1/actions
func (h *ActionHandler) ListActions(c *gin.Context) {
	userID := h.userID
	if userID == "" {
		Error(c, http.StatusUnauthorized, "UNAUTHORIZED", "User ID not found in context")
		return
	}

	actions, err := h.service.ListActions(c.Request.Context(), userID)
	if err != nil {
		slog.Error("failed to list actions", "error", err, "userID", userID)
		Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to list actions")
		return
	}

	Success(c, http.StatusOK, gin.H{
		"actions": actions,
	})
}

// GetAction handles GET /v1/actions/:actionId
func (h *ActionHandler) GetAction(c *gin.Context) {
	userID := h.userID
	if userID == "" {
		Error(c, http.StatusUnauthorized, "UNAUTHORIZED", "User ID not found in context")
		return
	}

	actionID := c.Param("actionId")
	if actionID == "" {
		Error(c, http.StatusBadRequest, "MISSING_ACTION_ID", "Action ID is required")
		return
	}

	action, err := h.service.GetAction(c.Request.Context(), userID, actionID)
	if err != nil {
		slog.Error("failed to get action", "error", err, "userID", userID, "actionID", actionID)
		Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to get action")
		return
	}

	if action == nil {
		Error(c, http.StatusNotFound, "ACTION_NOT_FOUND", "Action not found")
		return
	}

	Success(c, http.StatusOK, action)
}

// UpdateAction handles PUT /v1/actions/:actionId
func (h *ActionHandler) UpdateAction(c *gin.Context) {
	userID := h.userID
	if userID == "" {
		Error(c, http.StatusUnauthorized, "UNAUTHORIZED", "User ID not found in context")
		return
	}

	actionID := c.Param("actionId")
	if actionID == "" {
		Error(c, http.StatusBadRequest, "MISSING_ACTION_ID", "Action ID is required")
		return
	}

	var action domain.Action
	if err := c.ShouldBindJSON(&action); err != nil {
		Error(c, http.StatusBadRequest, "INVALID_REQUEST", "Invalid action data: "+err.Error())
		return
	}

	if err := h.service.UpdateAction(c.Request.Context(), userID, actionID, &action); err != nil {
		if strings.Contains(err.Error(), "not found") {
			Error(c, http.StatusNotFound, "ACTION_NOT_FOUND", "Action not found")
			return
		}
		slog.Error("failed to update action", "error", err, "userID", userID, "actionID", actionID)
		Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to update action")
		return
	}

	Success(c, http.StatusOK, gin.H{
		"success": true,
	})
}

// DeleteAction handles DELETE /v1/actions/:actionId
func (h *ActionHandler) DeleteAction(c *gin.Context) {
	userID := h.userID
	if userID == "" {
		Error(c, http.StatusUnauthorized, "UNAUTHORIZED", "User ID not found in context")
		return
	}

	actionID := c.Param("actionId")
	if actionID == "" {
		Error(c, http.StatusBadRequest, "MISSING_ACTION_ID", "Action ID is required")
		return
	}

	if err := h.service.DeleteAction(c.Request.Context(), userID, actionID); err != nil {
		slog.Error("failed to delete action", "error", err, "userID", userID, "actionID", actionID)
		Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to delete action")
		return
	}

	Success(c, http.StatusOK, gin.H{
		"success": true,
	})
}

// LogEvent handles POST /v1/actions/:actionId/events
func (h *ActionHandler) LogEvent(c *gin.Context) {
	userID := h.userID
	if userID == "" {
		Error(c, http.StatusUnauthorized, "UNAUTHORIZED", "User ID not found in context")
		return
	}

	actionID := c.Param("actionId")
	if actionID == "" {
		Error(c, http.StatusBadRequest, "MISSING_ACTION_ID", "Action ID is required")
		return
	}

	var eventReq struct {
		When string                 `json:"when"`
		Data map[string]interface{} `json:"data"`
	}

	if err := c.ShouldBindJSON(&eventReq); err != nil {
		Error(c, http.StatusBadRequest, "INVALID_REQUEST", "Invalid event data: "+err.Error())
		return
	}

	when, err := utils.ParseTimestamp(eventReq.When)
	if err != nil {
		Error(c, http.StatusBadRequest, "INVALID_TIMESTAMP",
			"Invalid timestamp format. Expected RFC3339 or ISO-8601 (e.g., 2026-02-16T15:45:30Z)")
		return
	}

	if err := h.service.LogEvent(c.Request.Context(), userID, actionID, when, eventReq.Data); err != nil {
		if strings.Contains(err.Error(), "not found") {
			Error(c, http.StatusNotFound, "ACTION_NOT_FOUND", "Action not found")
			return
		}
		if strings.Contains(err.Error(), "already exists") {
			Error(c, http.StatusConflict, "EVENT_EXISTS", "Event at this timestamp already exists")
			return
		}
		slog.Error("failed to log event", "error", err, "userID", userID, "actionID", actionID)
		Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to log event")
		return
	}

	Success(c, http.StatusCreated, gin.H{
		"success": true,
	})
}

// DeleteEvent handles DELETE /v1/actions/:actionId/events/:timestamp
func (h *ActionHandler) DeleteEvent(c *gin.Context) {
	userID := h.userID
	if userID == "" {
		Error(c, http.StatusUnauthorized, "UNAUTHORIZED", "User ID not found in context")
		return
	}

	actionID := c.Param("actionId")
	if actionID == "" {
		Error(c, http.StatusBadRequest, "MISSING_ACTION_ID", "Action ID is required")
		return
	}

	timestamp := c.Param("timestamp")
	if timestamp == "" {
		Error(c, http.StatusBadRequest, "MISSING_TIMESTAMP", "Timestamp is required")
		return
	}

	when, err := utils.ParseTimestamp(timestamp)
	if err != nil {
		Error(c, http.StatusBadRequest, "INVALID_TIMESTAMP",
			"Invalid timestamp format. Expected RFC3339 or ISO-8601 (e.g., 2026-02-16T15:45:30Z)")
		return
	}

	if err := h.service.DeleteEvent(c.Request.Context(), userID, actionID, when); err != nil {
		slog.Error("failed to delete event", "error", err, "userID", userID, "actionID", actionID)
		Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to delete event")
		return
	}

	Success(c, http.StatusOK, gin.H{
		"success": true,
	})
}

// deriveActionID derives the action ID from the action data
// For water-plant actions, it's "water-{plantId}"
// For other actions, generate a random ksuid
func deriveActionID(action *domain.Action) string {
	if action.SerializationKey == "water-plant" && action.Plant != nil {
		return "water-" + action.Plant.ID
	}

	// Generate a random ksuid for other action types
	return ksuid.New().String()
}
