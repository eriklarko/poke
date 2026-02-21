package commands

import "larko.se/poke/src/service"

// Deps holds the initialized dependencies passed in from main.
type Deps struct {
	ActionService *service.ActionService
	UserID        string
}
