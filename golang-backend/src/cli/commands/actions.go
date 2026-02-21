package commands

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/charmbracelet/huh"
	"github.com/segmentio/ksuid"
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
				{"Serialization Key", a.SerializationKey()},
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
			var id, serializationKey, metadataStr string
			var confirm bool

			form := huh.NewForm(
				huh.NewGroup(
					huh.NewInput().
						Title("Action ID").
						Description("Optional — leave blank to auto-generate").
						Value(&id),
					huh.NewInput().
						Title("Serialization key").
						Description("Required — used to deserialize the action into its specific subtype (like water-plant)").
						Value(&serializationKey).
						Validate(func(s string) error {
							if strings.TrimSpace(s) == "" {
								return fmt.Errorf("serializationKey is required")
							}
							return nil
						}),
					huh.NewText().
						Title("Metadata (JSON)").
						Description(`Optional — arbitrary JSON object, e.g. {"Plant": {"id": "foo", "name": "Fern"}}`).
						Placeholder("{}").
						Value(&metadataStr).
						Validate(func(s string) error {
							if strings.TrimSpace(s) == "" {
								return nil
							}
							var m map[string]interface{}
							if err := json.Unmarshal([]byte(strings.TrimSpace(s)), &m); err != nil {
								return fmt.Errorf("invalid JSON: %w", err)
							}
							return nil
						}),
				),
				huh.NewGroup(
					huh.NewConfirm().
						Title(fmt.Sprintf("Create action with serializationKey %q?", serializationKey)).
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

			if strings.TrimSpace(id) == "" {
				id = ksuid.New().String()
			}

			var metadata map[string]interface{}
			if s := strings.TrimSpace(metadataStr); s != "" {
				if err := json.Unmarshal([]byte(s), &metadata); err != nil {
					return fmt.Errorf("parsing metadata: %w", err)
				}
			}

			action, err := domain.NewAction(id, strings.TrimSpace(serializationKey), nil, metadata)
			if err != nil {
				return fmt.Errorf("building action: %w", err)
			}

			var createdID string
			err = ui.RunWithSpinner("Creating action…", func() error {
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
