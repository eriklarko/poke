package auth

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
)

// ErrNoCredentials is returned by LoadSavedCredentials when no credentials file exists.
var ErrNoCredentials = errors.New("no saved credentials")

// credentials holds the persisted auth state.
type credentials struct {
	RefreshToken string `json:"refreshToken"`
	UserID       string `json:"userID,omitempty"`
	Email        string `json:"email,omitempty"`
	APIKey       string `json:"apiKey,omitempty"`
}

// credentialsPath returns the path to the credentials file.
// Respects $XDG_CONFIG_HOME, falling back to ~/.config.
func credentialsPath() (string, error) {
	base := os.Getenv("XDG_CONFIG_HOME")
	if base == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", fmt.Errorf("could not determine home directory: %w", err)
		}
		base = filepath.Join(home, ".config")
	}
	return filepath.Join(base, "poke", "credentials.json"), nil
}

// SaveCredentials writes the refresh token, user ID, email, and API key to the credential store.
func SaveCredentials(refreshToken, userID, email, apiKey string) error {
	path, err := credentialsPath()
	if err != nil {
		return err
	}

	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return fmt.Errorf("creating config directory: %w", err)
	}

	data, err := json.Marshal(credentials{RefreshToken: refreshToken, UserID: userID, Email: email, APIKey: apiKey})
	if err != nil {
		return fmt.Errorf("marshalling credentials: %w", err)
	}

	if err := os.WriteFile(path, data, 0o600); err != nil {
		return fmt.Errorf("writing credentials file: %w", err)
	}

	return nil
}

// SavedCredentials is the publicly visible form of the persisted auth state.
type SavedCredentials struct {
	RefreshToken string
	UserID       string
	Email        string
	APIKey       string
}

// LoadSavedCredentials reads all saved credentials from the credential store.
// Returns ErrNoCredentials if no credentials file exists.
func LoadSavedCredentials() (*SavedCredentials, error) {
	path, err := credentialsPath()
	if err != nil {
		return nil, err
	}

	data, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil, ErrNoCredentials
	}
	if err != nil {
		return nil, fmt.Errorf("reading credentials file: %w", err)
	}

	var creds credentials
	if err := json.Unmarshal(data, &creds); err != nil {
		return nil, fmt.Errorf("parsing credentials file: %w", err)
	}

	return &SavedCredentials{
		RefreshToken: creds.RefreshToken,
		UserID:       creds.UserID,
		Email:        creds.Email,
		APIKey:       creds.APIKey,
	}, nil
}

// DeleteSavedToken removes the credential store file.
func DeleteSavedToken() error {
	path, err := credentialsPath()
	if err != nil {
		return err
	}

	if err := os.Remove(path); err != nil && !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("removing credentials file: %w", err)
	}

	return nil
}
