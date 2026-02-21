// Package ui provides terminal output primitives for the Poke CLI:
// spinners for async operations, styled tables, and formatting helpers.
package ui

import (
	"fmt"
	"os"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type resultMsg struct{ err error }

type spinnerModel struct {
	spinner  spinner.Model
	message  string
	resultCh <-chan error
	result   error
	done     bool
}

func (m spinnerModel) Init() tea.Cmd {
	return tea.Batch(
		m.spinner.Tick,
		waitForResult(m.resultCh),
	)
}

func (m spinnerModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case resultMsg:
		m.result = msg.err
		m.done = true
		return m, tea.Quit
	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd
	case tea.KeyMsg:
		if msg.Type == tea.KeyCtrlC {
			return m, tea.Quit
		}
	}
	return m, nil
}

func (m spinnerModel) View() string {
	if m.done {
		return ""
	}
	style := lipgloss.NewStyle().Foreground(lipgloss.Color("205"))
	return style.Render(m.spinner.View()) + " " + m.message + "\n"
}

func waitForResult(ch <-chan error) tea.Cmd {
	return func() tea.Msg {
		return resultMsg{err: <-ch}
	}
}

// RunWithSpinner executes fn in the background, showing a spinner with the
// given message until fn returns. The spinner writes to stderr so stdout
// remains clean for piped output.
func RunWithSpinner(message string, fn func() error) error {
	resultCh := make(chan error, 1)

	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().Foreground(lipgloss.Color("205"))

	m := spinnerModel{
		spinner:  s,
		message:  message,
		resultCh: resultCh,
	}

	go func() {
		resultCh <- fn()
	}()

	// Write spinner to stderr so stdout stays pipe-friendly.
	prog := tea.NewProgram(m, tea.WithOutput(os.Stderr), tea.WithoutSignalHandler())
	finalModel, err := prog.Run()
	if err != nil {
		return fmt.Errorf("spinner error: %w", err)
	}

	if fm, ok := finalModel.(spinnerModel); ok {
		return fm.result
	}
	return nil
}
