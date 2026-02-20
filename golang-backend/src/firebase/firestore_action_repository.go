package firebase

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"time"

	"larko.se/poke/src/domain"
)

const (
	usersCollection   = "users"
	actionsCollection = "actions"
)

// FirestoreActionRepository implements ActionRepository using Firebase Firestore REST API
type FirestoreActionRepository struct {
	client *FirestoreClient
}

// NewFirestoreActionRepository creates a new Firestore action repository
func NewFirestoreActionRepository(client *FirestoreClient) *FirestoreActionRepository {
	return &FirestoreActionRepository{
		client: client,
	}
}

// Create creates a new action
func (r *FirestoreActionRepository) Create(ctx context.Context, userID string, actionID string, action *domain.Action) error {
	path := fmt.Sprintf("%s/%s/%s", usersCollection, userID, actionsCollection)

	// Check if action already exists
	existing, err := r.GetByID(ctx, userID, actionID)
	if err != nil {
		return fmt.Errorf("failed to check existing action: %w", err)
	}
	if existing != nil {
		return fmt.Errorf("action with ID %s already exists", actionID)
	}

	// Convert action to map
	actionMap, err := actionToMap(action)
	if err != nil {
		return fmt.Errorf("failed to convert action to map: %w", err)
	}

	// Create the action
	if err := r.client.CreateDocument(ctx, path, actionID, actionMap); err != nil {
		return fmt.Errorf("failed to create action: %w", err)
	}

	return nil
}

// GetByID retrieves an action by its ID
func (r *FirestoreActionRepository) GetByID(ctx context.Context, userID string, actionID string) (*domain.Action, error) {
	path := fmt.Sprintf("%s/%s/%s/%s", usersCollection, userID, actionsCollection, actionID)

	doc, err := r.client.GetDocument(ctx, path)
	if err != nil {
		return nil, fmt.Errorf("failed to get action: %w", err)
	}

	if doc == nil {
		return nil, nil // Action not found
	}

	action, err := mapToAction(doc, actionID)
	if err != nil {
		return nil, fmt.Errorf("failed to parse action: %w", err)
	}

	return action, nil
}

// List retrieves all actions for a user
func (r *FirestoreActionRepository) List(ctx context.Context, userID string) ([]*domain.Action, error) {
	path := fmt.Sprintf("%s/%s/%s", usersCollection, userID, actionsCollection)

	docs, err := r.client.ListDocumentsWithIDs(ctx, path)
	if err != nil {
		return nil, fmt.Errorf("failed to list actions: %w", err)
	}

	actions := make([]*domain.Action, 0, len(docs))
	for _, doc := range docs {
		action, err := mapToAction(doc.Fields, doc.ID)
		if err != nil {
			// Log and skip documents that can't be parsed
			slog.Warn("skipping unparseable action document", "id", doc.ID, "error", err)
			continue
		}
		actions = append(actions, action)
	}

	return actions, nil
}

// Update updates an existing action
func (r *FirestoreActionRepository) Update(ctx context.Context, userID string, actionID string, action *domain.Action) error {
	// Check if action exists
	existing, err := r.GetByID(ctx, userID, actionID)
	if err != nil {
		return fmt.Errorf("failed to check action existence: %w", err)
	}
	if existing == nil {
		return fmt.Errorf("action with ID %s not found", actionID)
	}

	// Update the action
	fullPath := fmt.Sprintf("projects/%s/databases/(default)/documents/%s/%s/%s/%s",
		r.client.ProjectID, usersCollection, userID, actionsCollection, actionID)

	actionMap, err := actionToMap(action)
	if err != nil {
		return fmt.Errorf("failed to convert action to map: %w", err)
	}
	if err := r.client.UpdateDocument(ctx, fullPath, actionMap); err != nil {
		return fmt.Errorf("failed to update action: %w", err)
	}

	return nil
}

// Delete deletes an action
func (r *FirestoreActionRepository) Delete(ctx context.Context, userID string, actionID string) error {
	fullPath := fmt.Sprintf("projects/%s/databases/(default)/documents/%s/%s/%s/%s",
		r.client.ProjectID, usersCollection, userID, actionsCollection, actionID)

	if err := r.client.DeleteDocument(ctx, fullPath); err != nil {
		return fmt.Errorf("failed to delete action: %w", err)
	}

	return nil
}

// AddEvent adds an event to an action
func (r *FirestoreActionRepository) AddEvent(ctx context.Context, userID string, actionID string, when time.Time, data map[string]interface{}) error {
	// Get the action
	action, err := r.GetByID(ctx, userID, actionID)
	if err != nil {
		return fmt.Errorf("failed to get action: %w", err)
	}
	if action == nil {
		return fmt.Errorf("action with ID %s not found", actionID)
	}

	// Initialize events map if nil
	if action.Events == nil {
		action.Events = make(map[string]interface{})
	}

	// Check for duplicate timestamp
	whenKey := when.UTC().Format(time.RFC3339Nano)
	if _, exists := action.Events[whenKey]; exists {
		return fmt.Errorf("event at timestamp %s already exists", whenKey)
	}

	// Add the event. Store nil when there is no metadata so Firestore persists
	// a nullValue instead of an empty mapValue, avoiding unnecessary nesting.
	var eventData interface{}
	if len(data) > 0 {
		eventData = data
	}
	action.Events[whenKey] = eventData

	// Update the document
	fullPath := fmt.Sprintf("projects/%s/databases/(default)/documents/%s/%s/%s/%s",
		r.client.ProjectID, usersCollection, userID, actionsCollection, actionID)

	actionMap, err := actionToMap(action)
	if err != nil {
		return fmt.Errorf("failed to convert action to map after adding event: %w", err)
	}
	if err := r.client.UpdateDocument(ctx, fullPath, actionMap); err != nil {
		return fmt.Errorf("failed to add event: %w", err)
	}

	return nil
}

// DeleteEvent removes an event from an action
func (r *FirestoreActionRepository) DeleteEvent(ctx context.Context, userID string, actionID string, when time.Time) error {
	// Get the action
	action, err := r.GetByID(ctx, userID, actionID)
	if err != nil {
		return fmt.Errorf("failed to get action: %w", err)
	}
	if action == nil {
		return nil // Idempotent delete
	}

	// Remove the event
	whenKey := when.UTC().Format(time.RFC3339Nano)
	if action.Events != nil {
		delete(action.Events, whenKey)
	}

	// Update the document
	fullPath := fmt.Sprintf("projects/%s/databases/(default)/documents/%s/%s/%s/%s",
		r.client.ProjectID, usersCollection, userID, actionsCollection, actionID)

	actionMap, err := actionToMap(action)
	if err != nil {
		return fmt.Errorf("failed to convert action to map after deleting event: %w", err)
	}
	if err := r.client.UpdateDocument(ctx, fullPath, actionMap); err != nil {
		return fmt.Errorf("failed to delete event: %w", err)
	}

	return nil
}

// actionToMap converts a domain.Action to a map for Firestore
func actionToMap(action *domain.Action) (map[string]interface{}, error) {
	actionMap := make(map[string]interface{})

	// Convert action to JSON and back to map to handle serialization
	jsonBytes, err := json.Marshal(action)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal action: %w", err)
	}
	if err := json.Unmarshal(jsonBytes, &actionMap); err != nil {
		return nil, fmt.Errorf("failed to unmarshal action JSON into map: %w", err)
	}

	return actionMap, nil
}

// mapToAction converts a Firestore document map to a domain.Action.
// id is the Firestore document ID (used to populate Action.ID).
//
// The Flutter app stores events as an array of {when, data} objects. This
// function converts that array format into the Go map[timestamp]data format
// for easier manipulation in the predictor.
//
// TODO: This function should not know about plants - it should just handle generic actions, not water plant actions
func mapToAction(doc map[string]interface{}, id string) (*domain.Action, error) {
	// Use a flexible intermediate type so we can handle both array and map events.
	var raw struct {
		SerializationKey string          `json:"serializationKey"`
		Events           json.RawMessage `json:"events,omitempty"`
		Plant            *domain.Plant   `json:"plant,omitempty"`
	}

	jsonBytes, err := json.Marshal(doc)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal document: %w", err)
	}
	if err := json.Unmarshal(jsonBytes, &raw); err != nil {
		return nil, fmt.Errorf("failed to unmarshal action: %w", err)
	}

	action := &domain.Action{
		ID:               id,
		SerializationKey: raw.SerializationKey,
		Plant:            raw.Plant,
		Events:           make(map[string]interface{}),
	}

	// Parse events - Flutter uses array format, Go API uses map format
	if len(raw.Events) > 0 && string(raw.Events) != "null" {
		// Try map format first (from Go API)
		var eventsMap map[string]interface{}
		if err := json.Unmarshal(raw.Events, &eventsMap); err == nil {
			action.Events = eventsMap
		} else {
			// Try array format (from Flutter app - canonical source)
			var eventsArray []struct {
				When string                 `json:"when"`
				Data map[string]interface{} `json:"data,omitempty"`
			}
			if err := json.Unmarshal(raw.Events, &eventsArray); err != nil {
				slog.Warn("failed to parse events in either map or array format",
					"actionID", id, "error", err)
			} else {
				// Convert array to map
				for _, event := range eventsArray {
					action.Events[event.When] = event.Data
				}
			}
		}
	}

	return action, nil
}
