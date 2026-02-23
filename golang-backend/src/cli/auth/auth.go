// Package auth handles Firebase authentication for the CLI, including
// persisting credentials to disk so the user only has to log in once.
package auth

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"runtime"

	"github.com/charmbracelet/huh"
	"larko.se/poke/src/config"
	"larko.se/poke/src/firebase"
)

// Initialize returns an authenticated FirebaseClient for the CLI.
// Priority:
//  1. FB_REFRESH_TOKEN / FB_AUTH_TOKEN from cfg (env var or flag)
//  2. Saved credentials from ~/.config/poke/credentials.json — the API key
//     stored at login time is used automatically; no flags needed.
// Returns an error if not logged in, directing the user to run "poke auth login".
func Initialize(ctx context.Context, cfg *config.Config) (*firebase.FirebaseClient, error) {
	// 1. Explicit env-var / flag tokens take precedence.
	if cfg.FirebaseRefreshToken != "" {
		fbClient := firebase.NewFirebaseClient(cfg.FirebaseProjectID, cfg.FirebaseAPIKey)
		if err := fbClient.ExchangeRefreshToken(ctx, cfg.FirebaseRefreshToken); err != nil {
			return nil, fmt.Errorf("FB_REFRESH_TOKEN exchange failed: %w", err)
		}
		return fbClient, nil
	}

	if cfg.FirebaseAuthToken != "" {
		fbClient := firebase.NewFirebaseClient(cfg.FirebaseProjectID, cfg.FirebaseAPIKey)
		userID, err := firebase.JWTSubject(cfg.FirebaseAuthToken)
		if err != nil {
			return nil, fmt.Errorf("FB_AUTH_TOKEN could not be decoded: %w", err)
		}
		fbClient.SetIDToken(cfg.FirebaseAuthToken, userID)
		return fbClient, nil
	}

	// 2. Saved credentials — use the API key stored at login time so data
	// commands (actions/events/reminders) need zero flags or env vars.
	savedCreds, err := LoadSavedCredentials()
	if err != nil && !errors.Is(err, ErrNoCredentials) {
		return nil, fmt.Errorf("reading credential store: %w", err)
	}
	if err == nil && savedCreds.RefreshToken != "" {
		// An explicit flag/env var overrides the stored API key.
		apiKey := savedCreds.APIKey
		if cfg.FirebaseAPIKey != "" {
			apiKey = cfg.FirebaseAPIKey
		}
		fbClient := firebase.NewFirebaseClient(cfg.FirebaseProjectID, apiKey)
		if err := fbClient.ExchangeRefreshToken(ctx, savedCreds.RefreshToken); err != nil {
			return nil, fmt.Errorf("saved credentials are invalid — run \"poke auth login\" to re-authenticate: %w", err)
		}
		return fbClient, nil
	}

	return nil, fmt.Errorf("not logged in — run \"poke auth login --firebase-api-key=<key>\" first")
}

// Login performs a fresh interactive sign-in, ignoring any saved credentials.
// It requires an API key (via cfg.FirebaseAPIKey or --firebase-api-key).
// On success the refresh token and API key are saved to the credential store.
func Login(ctx context.Context, cfg *config.Config) (*firebase.FirebaseClient, error) {
	if cfg.FirebaseAPIKey == "" {
		return nil, fmt.Errorf("--firebase-api-key (or FIREBASE_API_KEY) is required to log in")
	}
	fbClient := firebase.NewFirebaseClient(cfg.FirebaseProjectID, cfg.FirebaseAPIKey)
	if err := runInteractiveLogin(ctx, cfg, fbClient); err != nil {
		return nil, err
	}
	if rt := fbClient.GetRefreshToken(); rt != "" {
		if saveErr := SaveCredentials(rt, fbClient.GetUserID(), fbClient.GetEmail(), cfg.FirebaseAPIKey); saveErr != nil {
			fmt.Fprintf(os.Stderr, "⚠ Could not save credentials: %v\n", saveErr)
		}
	}
	return fbClient, nil
}

// runInteractiveLogin shows an interactive Huh form to choose an auth method
// and then authenticates fbClient accordingly.
func runInteractiveLogin(ctx context.Context, cfg *config.Config, fbClient *firebase.FirebaseClient) error {
	var method string

	form := huh.NewForm(
		huh.NewGroup(
			huh.NewSelect[string]().
				Title("Sign in to Poke").
				Description("Choose an authentication method").
				Options(
					huh.NewOption("Google Sign-In", "google"),
					huh.NewOption("Email + Password", "email"),
					huh.NewOption("Anonymous", "anonymous"),
				).
				Value(&method),
		),
	)

	if err := form.Run(); err != nil {
		return fmt.Errorf("auth prompt cancelled: %w", err)
	}

	switch method {
	case "google":
		if cfg.GoogleClientID == "" || cfg.GoogleClientSecret == "" {
			return fmt.Errorf("set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET to use Google Sign-In")
		}
		if err := fbClient.SignInWithGoogle(ctx, cfg.GoogleClientID, cfg.GoogleClientSecret, openBrowser); err != nil {
			return fmt.Errorf("Google sign-in failed: %w", err)
		}

	case "email":
		var email, password string
		emailForm := huh.NewForm(
			huh.NewGroup(
				huh.NewInput().
					Title("Email").
					Value(&email),
				huh.NewInput().
					Title("Password").
					EchoMode(huh.EchoModePassword).
					Value(&password),
			),
		)
		if err := emailForm.Run(); err != nil {
			return fmt.Errorf("login cancelled: %w", err)
		}
		if err := fbClient.SignInWithEmailPassword(ctx, email, password); err != nil {
			return fmt.Errorf("email/password sign-in failed: %w", err)
		}

	case "anonymous":
		if err := fbClient.SignInAnonymously(ctx); err != nil {
			return fmt.Errorf("anonymous sign-in failed: %w", err)
		}
	}

	return nil
}

// openBrowser opens url in the default system browser.
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
		fmt.Printf("Please open this URL in your browser:\n%s\n", url)
		return
	}
	exec.Command(cmd, args...).Start() //nolint:errcheck
}
