package commands

import (
	"context"
	"fmt"
	"strings"

	"github.com/charmbracelet/huh"
	"github.com/spf13/cobra"
	"larko.se/poke/src/cli/ui"
	"larko.se/poke/src/domain"
)

func NewActionsCmd(deps *Deps) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "actions",
		Short: "Manage actions",
	}
	cmd.AddCommand(newActionsListCmd(deps))
	cmd.AddCommand(newActionsGetCmd(deps))
	cmd.AddCommand(newActionsCreateCmd(deps))
	cmd.AddCommand(newActionsDeleteCmd(deps))
	return cmd
}

// ── list ──────────────────────────────────────────────────────────────────────

func newActionsListCmd(deps *Deps) *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "List all actions",
		RunE: func(cmd *cobra.Command, args []string) error {
			var actions []*domain.Action
			err := ui.RunWithSpinner("Fetching actions…", func() error {
				var e error
				actions, e = deps.ActionService.ListActions(context.Background(), deps.UserID)
				return e
			})
			if err != nil {
				return fmt.Errorf("listing actions: %w", err)
			}

			if len(actions) == 0 {
				fmt.Println("No actions found. Create one with: poke actions create")
				return nil
			}

			rows := make([][]string, 0, len(actions))
			for _, a := range actions {
				lastEvent := ui.LastEventTime(a)
				rows = append(rows, []string{
					a.ID(),
					ui.FormatEventCount(len(a.Events())),
					ui.RelativeTime(lastEvent),
				})
			}
			ui.PrintTable([]string{"ID", "Events", "Last Event"}, rows)
			return nil
		},
	}
}

// ── get ───────────────────────────────────────────────────────────────────────

func newActionsGetCmd(deps *Deps) *cobra.Command {
	return &cobra.Command{
		Use:   "get <actionId>",
		Short: "Show details of a single action",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			actionID := args[0]

			var a *domain.Action
			err := ui.RunWithSpinner("Fetching action…", func() error {
				var e error
				a, e = deps.ActionService.GetAction(context.Background(), deps.UserID, actionID)
				return e
			})
			if err != nil {
				return fmt.Errorf("getting action: %w", err)
			}

			pairs := [][]string{
				{"ID", a.ID()},
				{"Events", ui.FormatEventCount(len(a.Events()))},
			}
			if last := ui.LastEventTime(a); last != nil {
				pairs = append(pairs, []string{"Last Event", ui.FormatTimestamp(*last)})
			}
			for _, line := range ui.ActionMetadataLines(a) {
				parts := strings.SplitN(line, ": ", 2)
				if len(parts) == 2 {
					pairs = append(pairs, parts)
				}
			}
			ui.PrintKeyValue(pairs)

			if len(a.Events()) > 0 {
				ui.Separator()
				fmt.Printf("Events (%s):\n\n", ui.FormatEventCount(len(a.Events())))
				var eventRows [][]string
				for tsStr := range a.Events() {
					eventRows = append(eventRows, []string{tsStr})
				}
				ui.PrintTable([]string{"Timestamp"}, eventRows)
			}
			return nil
		},
	}
}

// ── create ────────────────────────────────────────────────────────────────────

func newActionsCreateCmd(deps *Deps) *cobra.Command {
	return &cobra.Command{
		Use:   "create",
		Short: "Create a new action (interactive)",
		RunE: func(cmd *cobra.Command, args []string) error {
			var name, intervalDays string
			var confirm bool

			// TODO: good try, but needs to be replanned. I'll provide more info.
			form := huh.NewForm(
				huh.NewGroup(
					huh.NewInput().
						Title("Action name").
						Placeholder("e.g. Water the fern").
						Value(&name).
						Validate(func(s string) error {
							if strings.TrimSpace(s) == "" {
								return fmt.Errorf("name is required")
							}
							return nil
						}),
					huh.NewInput().
						Title("Typical interval (days)").
						Description("Optional — used to predict the next due date").
						Placeholder("e.g. 7").
						Value(&intervalDays),
				),
				huh.NewGroup(
					huh.NewConfirm().
						Title(fmt.Sprintf("Create action %q?", name)).
						Value(&confirm),
				),
			)

			if err := form.Run(); err != nil {
				return fmt.Errorf("form cancelled: %w", err)
			}
			if !confirm {
				fmt.Println("Cancelled.")
				return nil
			}

			metadata := map[string]interface{}{
				"name": strings.TrimSpace(name),
			}
			if d := strings.TrimSpace(intervalDays); d != "" {
				metadata["intervalDays"] = d
			}

			id := generateKSUID()
			action := domain.NewAction(id, "", nil, metadata)

			var createdID string
			err := ui.RunWithSpinner("Creating action…", func() error {
				if e := deps.ActionService.CreateAction(context.Background(), deps.UserID, id, action); e != nil {
					return e
				}
				createdID = id
				return nil
			})
			if err != nil {
				return fmt.Errorf("creating action: %w", err)
			}

			ui.Success(fmt.Sprintf("Created action %s", createdID))
			return nil
		},
	}
}

// ── delete ────────────────────────────────────────────────────────────────────

func newActionsDeleteCmd(deps *Deps) *cobra.Command {
	return &cobra.Command{
		Use:   "delete <actionId>",
		Short: "Delete an action",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			actionID := args[0]

			var confirm bool
			form := huh.NewForm(
				huh.NewGroup(
					huh.NewConfirm().
						Title(fmt.Sprintf("Delete action %q?", actionID)).
						Description("This will soft-delete the action (recoverable from Firestore).").
						Value(&confirm),
				),
			)
			if err := form.Run(); err != nil {
				return fmt.Errorf("prompt cancelled: %w", err)
			}
			if !confirm {
				fmt.Println("Cancelled.")
				return nil
			}

			err := ui.RunWithSpinner("Deleting action…", func() error {
				return deps.ActionService.DeleteAction(context.Background(), deps.UserID, actionID)
			})
			if err != nil {
				return fmt.Errorf("deleting action: %w", err)
			}

			ui.Success(fmt.Sprintf("Deleted action %s", actionID))
			return nil
		},
	}
}
