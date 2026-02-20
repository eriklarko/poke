package domain

import "time"

// Plant represents a plant that needs watering
type Plant struct {
	ID   string `json:"id" firestore:"id"`
	Name string `json:"name" firestore:"name"`
}

// Action represents a trackable recurring action.
// Different action types (SerializationKey) have different fields:
//   - "water-plant": Uses Plant field
//   - Future types: Will add their own fields (e.g., Vehicle for oil changes)
type Action struct {
	// ID is the Firestore document ID. It is populated by the repository layer
	// and is NOT stored as a Firestore field (firestore:"-").
	ID               string                 `json:"actionId,omitempty" firestore:"-"`
	SerializationKey string                 `json:"serializationKey" firestore:"serializationKey"`
	Events           map[string]interface{} `json:"events" firestore:"events"`
	Plant            *Plant                 `json:"plant,omitempty" firestore:"plant,omitempty"`
}

// Event represents a single logged occurrence of an action
type Event struct {
	When time.Time              `json:"when"`
	Data map[string]interface{} `json:"data,omitempty"`
}

// Reminder represents a calculated reminder with due date
type Reminder struct {
	Action  Action     `json:"action"`
	DueDate *time.Time `json:"dueDate"`
	IsDue   bool       `json:"isDue"`
}
