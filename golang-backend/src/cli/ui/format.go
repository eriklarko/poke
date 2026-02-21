package ui

import (
	"fmt"
	"sort"
	"strings"
	"time"

	"larko.se/poke/src/domain"
)

// RelativeTime formats t as a human-readable relative duration from now.
// e.g. "in 3 days", "2 hours ago", "today"
func RelativeTime(t *time.Time) string {
	if t == nil {
		return "—"
	}
	now := time.Now()
	diff := t.Sub(now)
	abs := diff
	if abs < 0 {
		abs = -abs
	}

	switch {
	case abs < time.Minute:
		return "just now"
	case abs < time.Hour:
		mins := int(abs.Minutes())
		if diff < 0 {
			return fmt.Sprintf("%d min ago", mins)
		}
		return fmt.Sprintf("in %d min", mins)
	case abs < 24*time.Hour:
		hours := int(abs.Hours())
		if diff < 0 {
			return fmt.Sprintf("%d hr ago", hours)
		}
		return fmt.Sprintf("in %d hr", hours)
	case abs < 48*time.Hour:
		if diff < 0 {
			return "yesterday"
		}
		return "tomorrow"
	default:
		days := int(abs.Hours() / 24)
		if diff < 0 {
			return fmt.Sprintf("%d days ago", days)
		}
		return fmt.Sprintf("in %d days", days)
	}
}

// ActionMetadataLines returns a sorted slice of "key: value" strings for
// the non-standard metadata fields of an action (excludes name, deleted).
func ActionMetadataLines(a *domain.Action) []string {
	skip := map[string]bool{"name": true, "deleted": true}
	var lines []string
	for k, v := range a.Metadata() {
		if skip[k] {
			continue
		}
		lines = append(lines, fmt.Sprintf("%s: %v", k, v))
	}
	sort.Strings(lines)
	return lines
}

// FormatEventCount formats an event count with correct pluralisation.
func FormatEventCount(n int) string {
	if n == 1 {
		return "1 event"
	}
	return fmt.Sprintf("%d events", n)
}

// LastEventTime returns the timestamp of the most recent event, or nil.
func LastEventTime(a *domain.Action) *time.Time {
	events := a.Events()
	if len(events) == 0 {
		return nil
	}

	var latest time.Time
	for tsStr := range events {
		t, err := time.Parse(time.RFC3339Nano, tsStr)
		if err != nil {
			continue
		}
		if t.After(latest) {
			latest = t
		}
	}
	if latest.IsZero() {
		return nil
	}
	return &latest
}

// FormatTimestamp formats t consistently throughout the CLI.
func FormatTimestamp(t time.Time) string {
	return t.Local().Format("2006-01-02 15:04")
}

// TruncateString truncates s to max runes, appending "…" if trimmed.
func TruncateString(s string, max int) string {
	runes := []rune(s)
	if len(runes) <= max {
		return s
	}
	return string(runes[:max-1]) + "…"
}

// JoinMetadata joins metadata lines into a short summary for table display.
func JoinMetadata(lines []string, max int) string {
	if len(lines) == 0 {
		return "—"
	}
	joined := strings.Join(lines, ", ")
	return TruncateString(joined, max)
}
