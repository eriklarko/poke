package commands

import (
	"fmt"

	"github.com/spf13/cobra"
)

// NewVersionCmd returns a command that prints build version information.
// The version, commit, and date strings are injected at build time via ldflags.
// When running locally without a release build they will be "dev".
func NewVersionCmd(version, commit, date string) *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Print version information",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Printf("poke %s\n", version)
			fmt.Printf("  commit: %s\n", commit)
			fmt.Printf("  built:  %s\n", date)
		},
	}
}
