package auth

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
)

// ErrNoCredentials is returned by LoadSavedToken when no credentials file exists.
var ErrNoCredentials = errors.New("no saved credentials")

// credentials holds the persisted auth state.
type credentials struct {
	RefreshToken string `json:"refreshToken"`
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

// SaveToken writes the given Firebase refresh token to the credential store.
func SaveToken(refreshToken string) error {
	path, err := credentialsPath()
	if err != nil {
		return err
	}

	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return fmt.Errorf("creating config directory: %w", err)
	}

	data, err := json.Marshal(credentials{RefreshToken: refreshToken})
	if err != nil {
		return fmt.Errorf("marshalling credentials: %w", err)
	}

	if err := os.WriteFile(path, data, 0o600); err != nil {
		return fmt.Errorf("writing credentials file: %w", err)
	}

	return nil
}

// LoadSavedToken reads the saved refresh token from the credential store.
// Returns ErrNoCredentials if no credentials file exists.
func LoadSavedToken() (string, error) {
	path, err := credentialsPath()
	if err != nil {
		return "", err
	}

	data, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return "", ErrNoCredentials
	}
	if err != nil {
		return "", fmt.Errorf("reading credentials file: %w", err)
	}

	var creds credentials
	if err := json.Unmarshal(data, &creds); err != nil {
		return "", fmt.Errorf("parsing credentials file: %w", err)
	}

	return creds.RefreshToken, nil
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
