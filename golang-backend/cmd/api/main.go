package main

import (
	"bufio"
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"runtime"
	"strings"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/term"
	"larko.se/poke/src/config"
	"larko.se/poke/src/firebase"
	"larko.se/poke/src/http_api"
	"larko.se/poke/src/service"
)

func main() {
	cfg, err := config.LoadWithEnvFile()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	gin.SetMode(cfg.GinMode)

	// Top-level context that drives background tasks (e.g. token refresh).
	// It is cancelled when the server shuts down so all goroutines exit cleanly.
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	fbClient := initializeFirebase(cfg)

	// Keep the ID token fresh for the lifetime of the server when a refresh
	// token is available. Firebase ID tokens expire after 1 hour; refresh 5
	// minutes before that to provide a comfortable margin.
	if fbClient.GetRefreshToken() != "" {
		fbClient.StartAutomaticTokenRefresh(ctx, 55*time.Minute)
		log.Println("✓ Automatic token refresh started (interval: 55m)")
	}

	firestore := firebase.NewFirestoreClient(fbClient)
	firestoreRepo := firebase.NewFirestoreActionRepository(firestore)

	actionService := service.NewActionService(firestoreRepo)
	actionHandler := http_api.NewActionHandler(actionService, fbClient.GetUserID())
	reminderHandler := http_api.NewReminderHandler(actionService, fbClient.GetUserID())

	r := http_api.SetupRouter(actionHandler, reminderHandler)

	startServer(r, cfg.Port)
}

// initializeFirebase builds and authenticates a FirebaseClient from cfg.
// It tries, in order:
//  1. FB_REFRESH_TOKEN  — exchanges for a fresh ID token; never expires.
//  2. FB_AUTH_TOKEN     — raw ID token; expires after 1 hour.
//  3. Interactive prompt — Google OAuth, email/password, or anonymous.
func initializeFirebase(cfg *config.Config) *firebase.FirebaseClient {
	ctx := context.Background()

	fbClient := firebase.NewFirebaseClient(cfg.FirebaseProjectID, cfg.FirebaseAPIKey)
	log.Printf("✓ Connected to Firebase project: %s", cfg.FirebaseProjectID)

	if cfg.FirebaseRefreshToken != "" {
		if err := fbClient.ExchangeRefreshToken(ctx, cfg.FirebaseRefreshToken); err != nil {
			log.Fatalf("FB_REFRESH_TOKEN exchange failed: %v", err)
		}
		log.Printf("✓ Authenticated via FB_REFRESH_TOKEN as user: %s", fbClient.GetUserID())
		return fbClient
	}

	if cfg.FirebaseAuthToken != "" {
		userID, err := firebase.JWTSubject(cfg.FirebaseAuthToken)
		if err != nil {
			log.Fatalf("FB_AUTH_TOKEN is set but could not decode user ID from it: %v", err)
		}
		fbClient.SetIDToken(cfg.FirebaseAuthToken, userID)
		log.Printf("✓ Authenticated via FB_AUTH_TOKEN as user: %s", userID)
		return fbClient
	}

	// TODO: replace with cli version in src/cli
	switch promptForAuthMethod() {
	case "google":
		if cfg.GoogleClientID == "" || cfg.GoogleClientSecret == "" {
			log.Fatalln("Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET to use Google Sign-In")
		}
		log.Println("Authenticating with Google...")
		if err := fbClient.SignInWithGoogle(ctx, cfg.GoogleClientID, cfg.GoogleClientSecret, openBrowser); err != nil {
			log.Fatalf("Failed to authenticate with Google: %v", err)
		}
		log.Printf("✓ Authenticated with Google as user: %s", fbClient.GetUserID())
	case "email":
		email, password := promptForEmailPassword()
		log.Printf("Authenticating with email: %s", email)
		if err := fbClient.SignInWithEmailPassword(ctx, email, password); err != nil {
			log.Fatalf("Failed to authenticate with email/password: %v", err)
		}
		log.Printf("✓ Authenticated as user: %s", fbClient.GetUserID())
	case "anonymous":
		log.Println("Authenticating anonymously...")
		if err := fbClient.SignInAnonymously(ctx); err != nil {
			log.Fatalf("Failed to authenticate anonymously: %v", err)
		}
		log.Printf("✓ Authenticated anonymously as user: %s", fbClient.GetUserID())
	}

	log.Printf("User ID:       %s\n", fbClient.GetUserID())
	log.Printf("Auth token:    %s\n", fbClient.GetIDToken())
	log.Printf("Refresh token: %s\n", fbClient.GetRefreshToken())
	log.Println("ℹ️  Add FB_REFRESH_TOKEN=<above> to your .env to skip this prompt next time.")
	return fbClient
}

// startServer starts the HTTP server and blocks until a shutdown signal is received.
func startServer(r *gin.Engine, port string) {
	addr := fmt.Sprintf(":%s", port)
	log.Printf("✓ Starting server on %s", addr)

	go func() {
		if err := r.Run(addr); err != nil {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Server exited")
}

// ── Interactive auth helpers ──────────────────────────────────────────────────

func promptForAuthMethod() string {
	reader := bufio.NewReader(os.Stdin)

	fmt.Println("\n=== Firebase Authentication ===")
	fmt.Println("Choose authentication method:")
	fmt.Println("  1) Google Sign-In (recommended)")
	fmt.Println("  2) Email + Password")
	fmt.Println("  3) Anonymous")
	fmt.Println()
	fmt.Print("Enter choice (1/2/3) [1]: ")

	choice, _ := reader.ReadString('\n')
	choice = strings.TrimSpace(choice)
	if choice == "" {
		choice = "1"
	}

	switch choice {
	case "1":
		return "google"
	case "2":
		return "email"
	case "3":
		return "anonymous"
	default:
		fmt.Println("Invalid choice, using Google Sign-In")
		return "google"
	}
}

func promptForEmailPassword() (string, string) {
	reader := bufio.NewReader(os.Stdin)

	fmt.Print("Email: ")
	email, _ := reader.ReadString('\n')
	email = strings.TrimSpace(email)

	fmt.Print("Password: ")
	passwordBytes, err := term.ReadPassword(int(os.Stdin.Fd()))
	fmt.Println()
	if err != nil {
		log.Fatalf("Error reading password: %v", err)
	}

	return email, strings.TrimSpace(string(passwordBytes))
}

// openBrowser attempts to open url in the system default browser.
// Errors are silently ignored — the URL is always printed so the user can open it manually.
func openBrowser(url string) {
	var cmd string
	var args []string

	switch runtime.GOOS {
	case "linux":
		cmd, args = "xdg-open", []string{url}
	case "darwin":
		cmd, args = "open", []string{url}
	case "windows":
		cmd, args = "rundll32", []string{"url.dll,FileProtocolHandler", url}
	default:
		fmt.Printf("Cannot open browser on %s. Please visit:\n%s\n", runtime.GOOS, url)
		return
	}

	exec.Command(cmd, args...).Start() //nolint:errcheck
}
