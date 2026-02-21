package commands

import (
	"context"
	"fmt"
	"time"

	"github.com/charmbracelet/huh"
	"github.com/spf13/cobra"
	"larko.se/poke/src/cli/ui"
)

func NewEventsCmd(deps *Deps) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "events",
		Short: "Manage events on actions",
	}
	cmd.AddCommand(newEventsLogCmd(deps))
	return cmd
}

func newEventsLogCmd(deps *Deps) *cobra.Command {
	var whenFlag string
	var nowFlag bool

	cmd := &cobra.Command{
		Use:   "log <actionId>",
		Short: "Log a new event for an action",
		Long: `Log a new event for an action, defaulting to the current time.

Examples:
  poke events log my-action-id
  poke events log my-action-id --now
  poke events log my-action-id --when 2026-02-20T14:30:00Z`,
		Args: cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			actionID := args[0]

			var when time.Time

			if nowFlag {
				when = time.Now().UTC()
			} else if cmd.Flags().Changed("when") {
				t, err := time.Parse(time.RFC3339, whenFlag)
				if err != nil {
					return fmt.Errorf("--when must be RFC3339, e.g. 2026-02-20T14:30:00Z: %w", err)
				}
				when = t
			} else {
				// Interactive: confirm now or enter custom time.
				whenStr := time.Now().UTC().Format(time.RFC3339)
				var useNow bool

				form := huh.NewForm(
					huh.NewGroup(
						huh.NewConfirm().
							Title(fmt.Sprintf("Log event at %s?", time.Now().Local().Format("2006-01-02 15:04"))).
							Description("Press Enter to confirm, or No to enter a custom time.").
							Affirmative("Yes, now").
							Negative("Custom time").
							Value(&useNow),
					),
				)
				if err := form.Run(); err != nil {
					return fmt.Errorf("prompt cancelled: %w", err)
				}

				if !useNow {
					form2 := huh.NewForm(
						huh.NewGroup(
							huh.NewInput().
								Title("Event timestamp (RFC3339)").
								Placeholder("2026-02-20T14:30:00Z").
								Value(&whenStr).
								Validate(func(s string) error {
									if _, err := time.Parse(time.RFC3339, s); err != nil {
										return fmt.Errorf("use RFC3339 format, e.g. 2026-02-20T14:30:00Z")
									}
									return nil
								}),
						),
					)
					if err := form2.Run(); err != nil {
						return fmt.Errorf("prompt cancelled: %w", err)
					}
				}

				t, err := time.Parse(time.RFC3339, whenStr)
				if err != nil {
					return fmt.Errorf("invalid timestamp: %w", err)
				}
				when = t
			}

			err := ui.RunWithSpinner("Logging event…", func() error {
				return deps.ActionService.LogEvent(context.Background(), deps.UserID, actionID, when, nil)
			})
			if err != nil {
				return fmt.Errorf("logging event: %w", err)
			}

			ui.Success(fmt.Sprintf("Event logged at %s", ui.FormatTimestamp(when)))
			return nil
		},
	}

	cmd.Flags().StringVar(&whenFlag, "when", "", "Timestamp in RFC3339 format (default: now)")
	cmd.Flags().BoolVar(&nowFlag, "now", false, "Log event immediately at the current time without prompting")
	return cmd
}
