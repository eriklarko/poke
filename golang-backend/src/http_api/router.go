package http_api

import (
	"github.com/gin-gonic/gin"
)

// SetupRouter configures all routes.
func SetupRouter(actionHandler *ActionHandler, reminderHandler *ReminderHandler) *gin.Engine {
	router := gin.Default()

	// Configure trusted proxies (none for local development)
	router.SetTrustedProxies(nil)

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// Action endpoints
	router.POST("/v1/actions", actionHandler.CreateAction)
	router.GET("/v1/actions", actionHandler.ListActions)
	router.GET("/v1/actions/:actionId", actionHandler.GetAction)
	router.PUT("/v1/actions/:actionId", actionHandler.UpdateAction)
	router.DELETE("/v1/actions/:actionId", actionHandler.DeleteAction)

	// Event endpoints
	router.POST("/v1/actions/:actionId/events", actionHandler.LogEvent)
	router.DELETE("/v1/actions/:actionId/events/:timestamp", actionHandler.DeleteEvent)

	// Reminder endpoints
	router.GET("/v1/reminders", reminderHandler.ListReminders)

	return router
}
