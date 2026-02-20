package http_api

import (
	"context"
	"log/slog"
	"net/http"

	"github.com/gin-gonic/gin"
	"larko.se/poke/src/domain"
)

// ReminderLister is the subset of service.ActionService used by ReminderHandler.
type ReminderLister interface {
	ListReminders(ctx context.Context, userID string) ([]*domain.Reminder, error)
}

// ReminderHandler handles HTTP requests for reminders.
type ReminderHandler struct {
	service ReminderLister
	userID  string
}

// NewReminderHandler creates a new reminder handler for the given authenticated user.
func NewReminderHandler(service ReminderLister, userID string) *ReminderHandler {
	return &ReminderHandler{service: service, userID: userID}
}

// ListReminders handles GET /v1/reminders
func (h *ReminderHandler) ListReminders(c *gin.Context) {
	userID := h.userID
	if userID == "" {
		Error(c, http.StatusUnauthorized, "UNAUTHORIZED", "User ID not found in context")
		return
	}

	reminders, err := h.service.ListReminders(c.Request.Context(), userID)
	if err != nil {
		slog.Error("failed to list reminders", "error", err, "userID", userID)
		Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to list reminders")
		return
	}

	Success(c, http.StatusOK, gin.H{
		"reminders": reminders,
	})
}
