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
//  1. FB_REFRESH_TOKEN / FB_AUTH_TOKEN env vars (same as the HTTP server)
//  2. Saved refresh token from the credential store (~/.config/poke/credentials.json)
//  3. Interactive login via Huh form
//
// When a new refresh token is obtained interactively, it is saved to the
// credential store automatically.
func Initialize(ctx context.Context, cfg *config.Config) (*firebase.FirebaseClient, error) {
	fbClient := firebase.NewFirebaseClient(cfg.FirebaseProjectID, cfg.FirebaseAPIKey)

	// 1. Env-var tokens take precedence (matches server behaviour).
	if cfg.FirebaseRefreshToken != "" {
		if err := fbClient.ExchangeRefreshToken(ctx, cfg.FirebaseRefreshToken); err != nil {
			return nil, fmt.Errorf("FB_REFRESH_TOKEN exchange failed: %w", err)
		}
		return fbClient, nil
	}

	if cfg.FirebaseAuthToken != "" {
		userID, err := firebase.JWTSubject(cfg.FirebaseAuthToken)
		if err != nil {
			return nil, fmt.Errorf("FB_AUTH_TOKEN could not be decoded: %w", err)
		}
		fbClient.SetIDToken(cfg.FirebaseAuthToken, userID)
		return fbClient, nil
	}

	// 2. Saved refresh token from credential store.
	savedCreds, err := LoadSavedCredentials()
	if err != nil && !errors.Is(err, ErrNoCredentials) {
		return nil, fmt.Errorf("reading credential store: %w", err)
	}
	if err == nil && savedCreds.RefreshToken != "" {
		if err := fbClient.ExchangeRefreshToken(ctx, savedCreds.RefreshToken); err != nil {
			// Saved token may have been revoked — fall through to interactive login.
			fmt.Fprintf(os.Stderr, "⚠ Saved credentials are invalid, please log in again.\n")
		} else {
			return fbClient, nil
		}
	}

	// 3. Interactive login.
	if err := runInteractiveLogin(ctx, cfg, fbClient); err != nil {
		return nil, err
	}

	// Persist the refresh token so the user doesn't have to log in next time.
	if rt := fbClient.GetRefreshToken(); rt != "" {
		if saveErr := SaveCredentials(rt, fbClient.GetUserID(), fbClient.GetEmail()); saveErr != nil {
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
