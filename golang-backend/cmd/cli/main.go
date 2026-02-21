package main

import (
	"context"
	"fmt"
	"os"

	"github.com/spf13/cobra"
	cliauth "larko.se/poke/src/cli/auth"
	"larko.se/poke/src/cli/commands"
	"larko.se/poke/src/config"
	"larko.se/poke/src/firebase"
	"larko.se/poke/src/service"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("loading config: %w", err)
	}

	fbClient, err := cliauth.Initialize(context.Background(), cfg)
	if err != nil {
		return fmt.Errorf("authentication: %w", err)
	}

	firestoreClient := firebase.NewFirestoreClient(fbClient)
	firestoreRepo := firebase.NewFirestoreActionRepository(firestoreClient)
	actionService := service.NewActionService(firestoreRepo)

	deps := &commands.Deps{
		ActionService: actionService,
		UserID:        fbClient.GetUserID(),
	}

	cmd := &cobra.Command{
		Use:   "poke",
		Short: "Poke – personal action & reminder tracker",
		Long: `Poke lets you track recurring actions and get reminders when they're due.

Use "poke help <command>" for more information about a specific command.`,
		SilenceUsage: true,
	}
	cmd.AddCommand(commands.NewAuthCmd())
	cmd.AddCommand(commands.NewActionsCmd(deps))
	cmd.AddCommand(commands.NewEventsCmd(deps))
	cmd.AddCommand(commands.NewRemindersCmd(deps))

	if err := cmd.Execute(); err != nil {
		os.Exit(1)
	}
	return nil
}
