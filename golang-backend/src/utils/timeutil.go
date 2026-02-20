// Package utils provides shared helpers used across multiple packages.
package utils

import (
	"fmt"
	"time"
)

// ParseTimestamp accepts RFC3339Nano, RFC3339, or a bare ISO-8601 string with
// no timezone offset (treated as UTC). Always returns a UTC time.
func ParseTimestamp(s string) (time.Time, error) {
	for _, layout := range []string{
		time.RFC3339Nano,
		time.RFC3339,
		"2006-01-02T15:04:05.999999999",
		"2006-01-02T15:04:05",
	} {
		if t, err := time.Parse(layout, s); err == nil {
			return t.UTC(), nil
		}
	}
	return time.Time{}, fmt.Errorf("cannot parse %q as a timestamp", s)
}
