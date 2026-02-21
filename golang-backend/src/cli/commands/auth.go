package commands

import (
	"context"
	"fmt"

	"github.com/spf13/cobra"
	cliauth "larko.se/poke/src/cli/auth"
	"larko.se/poke/src/cli/ui"
	"larko.se/poke/src/config"
)

func NewAuthCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "auth",
		Short: "Manage authentication",
	}
	cmd.AddCommand(newAuthLoginCmd())
	cmd.AddCommand(newAuthLogoutCmd())
	cmd.AddCommand(newAuthStatusCmd())
	return cmd
}

func newAuthLoginCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "login",
		Short: "Authenticate with Firebase",
		Long:  `Authenticate with Firebase and save credentials to ~/.config/poke/credentials.json.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			cfg, err := config.Load()
			if err != nil {
				return fmt.Errorf("loading config: %w", err)
			}
			_ = cliauth.DeleteSavedToken()
			client, err := cliauth.Initialize(context.Background(), cfg)
			if err != nil {
				return err
			}
			ui.Success(fmt.Sprintf("Logged in as %s", client.GetUserID()))
			return nil
		},
	}
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
			token, err := cliauth.LoadSavedToken()
			if err != nil || token == "" {
				fmt.Println("Not logged in.")
				return nil
			}
			fmt.Println("Saved credentials found. Run \"poke auth login\" to refresh.")
			return nil
		},
	}
}
