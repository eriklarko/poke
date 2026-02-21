package commands

import (
	"context"
	"fmt"

	"github.com/spf13/cobra"
	"larko.se/poke/src/cli/ui"
	"larko.se/poke/src/domain"
)

func NewRemindersCmd(deps *Deps) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "reminders",
		Short: "Show upcoming reminders",
	}
	cmd.AddCommand(newRemindersListCmd(deps))
	return cmd
}

func newRemindersListCmd(deps *Deps) *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "List all predicted reminders",
		Long: `List all reminders with predicted due dates.

Actions are sorted with overdue/due items first, then by due date.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			var reminders []*domain.Reminder
			err := ui.RunWithSpinner("Fetching reminders…", func() error {
				var e error
				reminders, e = deps.ActionService.ListReminders(context.Background(), deps.UserID)
				return e
			})
			if err != nil {
				return fmt.Errorf("listing reminders: %w", err)
			}

			if len(reminders) == 0 {
				fmt.Println("No reminders found. Add actions first: poke actions create")
				return nil
			}

			sortReminders(reminders)

			rows := make([][]string, 0, len(reminders))
			for _, r := range reminders {
				rows = append(rows, []string{
					ui.DueBadge(r.IsDue),
					r.Action.ID(),
					ui.RelativeTime(r.DueDate),
					ui.FormatEventCount(len(r.Action.Events())),
				})
			}

			ui.PrintTable([]string{"", "Action", "Due", "Events"}, rows)
			return nil
		},
	}
}

func sortReminders(reminders []*domain.Reminder) {
	for i := 1; i < len(reminders); i++ {
		for j := i; j > 0; j-- {
			if shouldSwap(reminders[j-1], reminders[j]) {
				reminders[j-1], reminders[j] = reminders[j], reminders[j-1]
			} else {
				break
			}
		}
	}
}

func shouldSwap(a, b *domain.Reminder) bool {
	if b.IsDue && !a.IsDue {
		return true
	}
	if a.IsDue && !b.IsDue {
		return false
	}
	if a.DueDate != nil && b.DueDate != nil {
		return b.DueDate.Before(*a.DueDate)
	}
	return b.DueDate != nil && a.DueDate == nil
}
