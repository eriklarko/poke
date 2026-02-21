package ui

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/lipgloss/table"
)

var (
	headerStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("99")).
			Padding(0, 1)

	cellStyle = lipgloss.NewStyle().
			Padding(0, 1)

	evenRowStyle = cellStyle.Foreground(lipgloss.Color("245"))
	oddRowStyle  = cellStyle.Foreground(lipgloss.Color("255"))

	borderStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("238"))

	dueBadge = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("196")).
			SetString("● DUE")

	okBadge = lipgloss.NewStyle().
		Foreground(lipgloss.Color("35")).
		SetString("○")
)

// PrintTable renders rows under the given headers as a styled lipgloss table.
func PrintTable(headers []string, rows [][]string) {
	t := table.New().
		Border(lipgloss.NormalBorder()).
		BorderStyle(borderStyle).
		StyleFunc(func(row, col int) lipgloss.Style {
			if row == table.HeaderRow {
				return headerStyle
			}
			if row%2 == 0 {
				return evenRowStyle
			}
			return oddRowStyle
		}).
		Headers(headers...).
		Rows(rows...)

	fmt.Println(t)
}

// PrintKeyValue renders a list of key-value pairs with aligned colons.
func PrintKeyValue(pairs [][]string) {
	// Find max key width for alignment.
	maxLen := 0
	for _, p := range pairs {
		if len(p[0]) > maxLen {
			maxLen = len(p[0])
		}
	}

	keyStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("99")).
		Width(maxLen)

	for _, p := range pairs {
		fmt.Printf("%s  %s\n", keyStyle.Render(p[0]), p[1])
	}
}

// DueBadge returns a coloured "● DUE" or "○" string.
func DueBadge(isDue bool) string {
	if isDue {
		return dueBadge.String()
	}
	return okBadge.String()
}

// Separator prints a horizontal rule.
func Separator() {
	style := lipgloss.NewStyle().Foreground(lipgloss.Color("238"))
	fmt.Println(style.Render(strings.Repeat("─", 60)))
}

// Success prints a green success message.
func Success(msg string) {
	s := lipgloss.NewStyle().Foreground(lipgloss.Color("35")).Bold(true)
	fmt.Println(s.Render("✓ " + msg))
}

// Error prints a red error message.
func PrintError(msg string) {
	s := lipgloss.NewStyle().Foreground(lipgloss.Color("196")).Bold(true)
	fmt.Println(s.Render("✗ " + msg))
}
