package config

import (
	"log"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

// Config holds all application configuration
type Config struct {
	FirebaseProjectID    string
	FirebaseAPIKey       string
	FirebaseAuthToken    string // optional: skip interactive login when set
	FirebaseRefreshToken string // optional: preferred over AuthToken; auto-renews ID token
	GoogleClientID       string
	GoogleClientSecret   string
	Port                 string
	GinMode              string
	CORSEnabled          bool
	MaxUploadSizeMB      int
}

// Load loads configuration from environment variables
func Load() (*Config, error) {
	// Load .env file if it exists (ignore error in production)
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: .env file not found, using environment variables: %v", err)
	}

	config := &Config{
		FirebaseProjectID:    getEnv("FIREBASE_PROJECT_ID", "plant-reminder-90745"),
		FirebaseAPIKey:       getEnv("FIREBASE_API_KEY", "AIzaSyCo2Jlq9WdIpchjg2MxyNfP7CKUFPtvMEw"),
		FirebaseAuthToken:    getEnv("FB_AUTH_TOKEN", ""),
		FirebaseRefreshToken: getEnv("FB_REFRESH_TOKEN", ""),
		GoogleClientID:       getEnv("GOOGLE_CLIENT_ID", ""),
		GoogleClientSecret:   getEnv("GOOGLE_CLIENT_SECRET", ""),
		Port:                 getEnv("PORT", "8080"),
		GinMode:              getEnv("GIN_MODE", "debug"),
		CORSEnabled:          getEnv("CORS_ENABLED", "false") == "true",
		MaxUploadSizeMB:      getEnvInt("MAX_UPLOAD_SIZE_MB", 10),
	}

	return config, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if i, err := strconv.Atoi(value); err == nil {
			return i
		}
		log.Printf("Warning: invalid integer for %s: %s, using default %d", key, value, defaultValue)
	}
	return defaultValue
}
