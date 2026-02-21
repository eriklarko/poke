package commands

import "github.com/segmentio/ksuid"

// generateKSUID returns a new random KSUID string, matching the convention
// used by the HTTP action handler for auto-generated action IDs.
func generateKSUID() string {
	return ksuid.New().String()
}
