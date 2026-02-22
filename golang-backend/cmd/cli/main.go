package main

import (
	"context"
	"fmt"
	"os"
	"sync"

	"github.com/spf13/cobra"
	cliauth "larko.se/poke/src/cli/auth"
	"larko.se/poke/src/cli/commands"
	"larko.se/poke/src/config"
	"larko.se/poke/src/firebase"
	"larko.se/poke/src/service"
)

// Injected at build time via -ldflags "-X main.version=... -X main.commit=... -X main.date=..."
// Falls back to "dev" when running locally with `go run`.
var (
	version = "dev"
	commit  = "none"
	date    = "unknown"
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

	// deps starts empty; it is populated lazily the first time a command that
	// requires authentication actually runs (via PersistentPreRunE below).
	deps := &commands.Deps{}

	var (
		once    sync.Once
		authErr error
	)
	initAuth := func() error {
		once.Do(func() {
			var fbClient *firebase.FirebaseClient
			fbClient, authErr = cliauth.Initialize(context.Background(), cfg)
			if authErr != nil {
				authErr = fmt.Errorf("authentication: %w", authErr)
				return
			}
			firestoreClient := firebase.NewFirestoreClient(fbClient)
			firestoreRepo := firebase.NewFirestoreActionRepository(firestoreClient)
			actionService := service.NewActionService(firestoreRepo)
			deps.ActionService = actionService
			deps.UserID = fbClient.GetUserID()
		})
		return authErr
	}

	cmd := &cobra.Command{
		Use:   "poke",
		Short: "Poke – personal action & reminder tracker",
		Long: `Poke lets you track recurring actions and get reminders when they're due.

Use "poke help <command>" for more information about a specific command.`,
		SilenceUsage: true,
	}

	authRequired := func(cmd *cobra.Command, args []string) error {
		return initAuth()
	}

	actionsCmd := commands.NewActionsCmd(deps)
	actionsCmd.PersistentPreRunE = authRequired

	eventsCmd := commands.NewEventsCmd(deps)
	eventsCmd.PersistentPreRunE = authRequired

	remindersCmd := commands.NewRemindersCmd(deps)
	remindersCmd.PersistentPreRunE = authRequired

	cmd.AddCommand(commands.NewVersionCmd(version, commit, date))
	cmd.AddCommand(commands.NewAuthCmd())
	cmd.AddCommand(actionsCmd)
	cmd.AddCommand(eventsCmd)
	cmd.AddCommand(remindersCmd)

	if err := cmd.Execute(); err != nil {
		os.Exit(1)
	}
	return nil
}
