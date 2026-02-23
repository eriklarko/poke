package commands

import (
	"context"
	"fmt"

	"github.com/spf13/cobra"
	cliauth "larko.se/poke/src/cli/auth"
	"larko.se/poke/src/cli/ui"
	"larko.se/poke/src/config"
)

// NewAuthCmd returns the `auth` command subtree. cfg is the shared config
// instance already populated with env vars and root-level persistent flags,
// so auth login inherits --firebase-project-id / --firebase-api-key /
// --fb-auth-token / --fb-refresh-token without re-declaring them.
func NewAuthCmd(cfg *config.Config) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "auth",
		Short: "Manage authentication",
	}
	cmd.AddCommand(newAuthLoginCmd(cfg))
	cmd.AddCommand(newAuthLogoutCmd())
	cmd.AddCommand(newAuthStatusCmd())
	return cmd
}

func newAuthLoginCmd(cfg *config.Config) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "login",
		Short: "Authenticate with Firebase",
		Long:  `Authenticate with Firebase and save credentials to ~/.config/poke/credentials.json.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			_ = cliauth.DeleteSavedToken()
			client, err := cliauth.Login(context.Background(), cfg)
			if err != nil {
				return err
			}
			ui.Success(fmt.Sprintf("Logged in as %s", client.GetUserID()))
			return nil
		},
	}
	// Firebase connection flags — allow overriding the project/key used for
	// this login without needing env vars.
	cmd.Flags().StringVar(&cfg.FirebaseProjectID, "firebase-project-id", cfg.FirebaseProjectID, "Firebase project ID (env: FIREBASE_PROJECT_ID)")
	cmd.Flags().StringVar(&cfg.FirebaseAPIKey, "firebase-api-key", cfg.FirebaseAPIKey, "Firebase API key (env: FIREBASE_API_KEY)")
	cmd.Flags().StringVar(&cfg.FirebaseAuthToken, "fb-auth-token", cfg.FirebaseAuthToken, "Firebase ID token to use directly (env: FB_AUTH_TOKEN)")
	cmd.Flags().StringVar(&cfg.FirebaseRefreshToken, "fb-refresh-token", cfg.FirebaseRefreshToken, "Firebase refresh token; auto-renews ID token (env: FB_REFRESH_TOKEN)")
	// Google OAuth — only needed when choosing Google Sign-In interactively.
	cmd.Flags().StringVar(&cfg.GoogleClientID, "google-client-id", cfg.GoogleClientID, "Google OAuth client ID (env: GOOGLE_CLIENT_ID)")
	cmd.Flags().StringVar(&cfg.GoogleClientSecret, "google-client-secret", cfg.GoogleClientSecret, "Google OAuth client secret (env: GOOGLE_CLIENT_SECRET)")
	return cmd
}

func newAuthLogoutCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "logout",
		Short: "Remove saved credentials",
		RunE: func(cmd *cobra.Command, args []string) error {
			if err := cliauth.DeleteSavedToken(); err != nil {
				return err
			}
			ui.Success("Logged out — credentials removed.")
			return nil
		},
	}
}

func newAuthStatusCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "status",
		Short: "Show current auth status",
		RunE: func(cmd *cobra.Command, args []string) error {
			creds, err := cliauth.LoadSavedCredentials()
			if err != nil || creds.RefreshToken == "" {
				fmt.Println("Not logged in.")
				return nil
			}
			fmt.Println("Logged in.")
			if creds.UserID != "" {
				fmt.Printf("  User ID : %s\n", creds.UserID)
			}
			if creds.Email != "" {
				fmt.Printf("  Email   : %s\n", creds.Email)
			} else {
				fmt.Println("  Email   : (anonymous or not stored — run \"poke auth login\" to refresh)")
			}
			return nil
		},
	}
}
