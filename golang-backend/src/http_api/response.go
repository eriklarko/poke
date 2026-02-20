package http_api

import (
	"github.com/gin-gonic/gin"
)

// ErrorDetail represents the error structure in API responses
type ErrorDetail struct {
	Code    string                 `json:"code"`
	Message string                 `json:"message"`
	Details map[string]interface{} `json:"details,omitempty"`
}

// ErrorResponse wraps the error detail
type ErrorResponse struct {
	Error ErrorDetail `json:"error"`
}

// Success sends a successful JSON response
func Success(c *gin.Context, status int, data interface{}) {
	c.JSON(status, data)
}

// Error sends an error JSON response with structured format
func Error(c *gin.Context, status int, code, message string) {
	c.JSON(status, ErrorResponse{
		Error: ErrorDetail{
			Code:    code,
			Message: message,
		},
	})
}

// ErrorWithDetails sends an error JSON response with additional details
func ErrorWithDetails(c *gin.Context, status int, code, message string, details map[string]interface{}) {
	c.JSON(status, ErrorResponse{
		Error: ErrorDetail{
			Code:    code,
			Message: message,
			Details: details,
		},
	})
}
