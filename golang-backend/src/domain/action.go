package domain

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"sort"
	"time"
)

// ── Event ──────────────────────────────────────────────────────────────────────

// Event represents a single logged occurrence of an action.
type Event struct {
	When time.Time              `json:"when"`
	Data map[string]interface{} `json:"data,omitempty"`
}

// ── Reminder ───────────────────────────────────────────────────────────────────

// Reminder represents a calculated reminder with due date.
type Reminder struct {
	Action  *Action    `json:"action"`
	DueDate *time.Time `json:"dueDate"`
	IsDue   bool       `json:"isDue"`
}

// ── Action ─────────────────────────────────────────────────────────────────────

// Action is a generic action that passes through all fields from the repository.
// The backend does not interpret type-specific fields; they are stored and
// returned as-is so the client owns the schema.
type Action struct {
	id               string
	serializationKey string
	events           map[string]interface{}
	metadata         map[string]interface{}
}

func (a *Action) ID() string                       { return a.id }
func (a *Action) SerializationKey() string         { return a.serializationKey }
func (a *Action) Events() map[string]interface{}   { return a.events }
func (a *Action) Metadata() map[string]interface{} { return a.metadata }

func (a *Action) MarshalJSON() ([]byte, error) { return MarshalAction(a) }

// NewAction creates a new generic action.
func NewAction(id string, serializationKey string, events map[string]interface{}, metadata map[string]interface{}) (*Action, error) {
	if serializationKey == "" {
		return nil, fmt.Errorf("serializationKey is required")
	}

	if events == nil {
		events = make(map[string]interface{})
	}
	if metadata == nil {
		metadata = make(map[string]interface{})
	}
	return &Action{
		id:               id,
		serializationKey: serializationKey,
		events:           events,
		metadata:         metadata,
	}, nil
}

// ── Serialization ──────────────────────────────────────────────────────────────

// MarshalAction produces a flat JSON representation for any Action.
// Metadata keys are spread at the top level alongside actionId, serializationKey,
// and events. Standard fields take precedence over metadata.
func MarshalAction(a *Action) ([]byte, error) {
	m := make(map[string]interface{})
	for k, v := range a.Metadata() {
		m[k] = v
	}
	if a.ID() != "" {
		m["actionId"] = a.ID()
	}
	if sk := a.SerializationKey(); sk != "" {
		m["serializationKey"] = sk
	}
	// Serialize events as array format (Flutter canonical format).
	// Each entry is {"when": "<RFC3339Nano>", "data": {...}} where data is omitted when nil.
	eventsMap := a.Events()
	eventsArray := make([]map[string]interface{}, 0, len(eventsMap))
	for when, data := range eventsMap {
		entry := map[string]interface{}{"when": when}
		if data != nil {
			entry["data"] = data
		}
		eventsArray = append(eventsArray, entry)
	}
	sort.Slice(eventsArray, func(i, j int) bool {
		return eventsArray[i]["when"].(string) < eventsArray[j]["when"].(string)
	})
	m["events"] = eventsArray
	return json.Marshal(m)
}

// ActionToMap converts any Action to a map suitable for Firestore storage.
// The actionId is excluded since it is the Firestore document ID.
func ActionToMap(a *Action) (map[string]interface{}, error) {
	jsonBytes, err := MarshalAction(a)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal action: %w", err)
	}
	var m map[string]interface{}
	if err := json.Unmarshal(jsonBytes, &m); err != nil {
		return nil, fmt.Errorf("failed to unmarshal action JSON into map: %w", err)
	}
	delete(m, "actionId")
	return m, nil
}

// UnmarshalAction deserializes JSON bytes into a generic Action.
func UnmarshalAction(data []byte) (*Action, error) {
	return actionFromJSON(data, "")
}

// ActionFromMap builds an Action from a Firestore document map and its document ID.
// This handles both the Go API map-based event format and the Flutter app's
// array-based event format.
func ActionFromMap(doc map[string]interface{}, id string) (*Action, error) {
	jsonBytes, err := json.Marshal(doc)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal document map: %w", err)
	}
	return actionFromJSON(jsonBytes, id)
}

// actionFromJSON deserializes raw JSON into a generic Action.
// All fields except actionId, serializationKey, and events go into Metadata.
func actionFromJSON(data []byte, id string) (*Action, error) {
	var raw map[string]json.RawMessage
	if err := json.Unmarshal(data, &raw); err != nil {
		return nil, fmt.Errorf("failed to unmarshal action: %w", err)
	}

	var actionID, serializationKey string
	metadata := make(map[string]interface{})

	if v, ok := raw["actionId"]; ok {
		if err := json.Unmarshal(v, &actionID); err != nil {
			return nil, fmt.Errorf("failed to unmarshal actionId: %w", err)
		}
	}
	if id != "" {
		actionID = id
	}
	if v, ok := raw["serializationKey"]; ok {
		if err := json.Unmarshal(v, &serializationKey); err != nil {
			return nil, fmt.Errorf("failed to unmarshal serializationKey: %w", err)
		}
	}

	var events map[string]interface{}
	if v, ok := raw["events"]; ok {
		var err error
		events, err = parseEvents(v, actionID)
		if err != nil {
			return nil, fmt.Errorf("failed to parse events for action %q: %w", actionID, err)
		}
	}

	reserved := map[string]bool{"actionId": true, "serializationKey": true, "events": true}
	for k, v := range raw {
		if !reserved[k] {
			var val interface{}
			if err := json.Unmarshal(v, &val); err != nil {
				slog.Warn("failed to unmarshal metadata field; skipping",
					"actionID", actionID, "field", k, "error", err)
				continue
			}
			metadata[k] = val
		}
	}

	return NewAction(actionID, serializationKey, events, metadata)
}

// parseEvents handles both array format (Flutter / Go API canonical) and the
// legacy map format written by older Go API versions.
func parseEvents(raw json.RawMessage, actionID string) (map[string]interface{}, error) {
	events := make(map[string]interface{})
	if len(raw) == 0 || string(raw) == "null" {
		return events, nil
	}

	// Try array format first (canonical format used by both Flutter and Go API).
	var eventsArray []struct {
		When string                 `json:"when"`
		Data map[string]interface{} `json:"data,omitempty"`
	}
	if err := json.Unmarshal(raw, &eventsArray); err == nil {
		for _, event := range eventsArray {
			events[event.When] = event.Data
		}
		return events, nil
	}

	// Fall back to legacy map format (Go API before array migration).
	var eventsMap map[string]interface{}
	if err := json.Unmarshal(raw, &eventsMap); err != nil {
		return nil, fmt.Errorf("events field for action %q is neither an array nor a map: %w", actionID, err)
	}
	return eventsMap, nil
}
