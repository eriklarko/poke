package firebase

import (
	"context"
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
	actionMap, err := domain.ActionToMap(action)
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

	action, err := domain.ActionFromMap(doc, actionID)
	if err != nil {
		return nil, fmt.Errorf("failed to parse action: %w", err)
	}

	if isDeleted(action) {
		return nil, nil // Treat soft-deleted actions as not found
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
		action, err := domain.ActionFromMap(doc.Fields, doc.ID)
		if err != nil {
			// Log and skip documents that can't be parsed
			slog.Warn("skipping unparseable action document", "id", doc.ID, "error", err)
			continue
		}
		if isDeleted(action) {
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

	actionMap, err := domain.ActionToMap(action)
	if err != nil {
		return fmt.Errorf("failed to convert action to map: %w", err)
	}
	if err := r.client.UpdateDocument(ctx, fullPath, actionMap); err != nil {
		return fmt.Errorf("failed to update action: %w", err)
	}

	return nil
}

// Delete soft-deletes an action by setting a "deleted" field to true.
// The document is retained in Firestore to preserve event history and to avoid
// eventual-consistency issues with reminders.
func (r *FirestoreActionRepository) Delete(ctx context.Context, userID string, actionID string) error {
	action, err := r.GetByID(ctx, userID, actionID)
	if err != nil {
		return fmt.Errorf("failed to get action for deletion: %w", err)
	}
	if action == nil {
		return nil // Already deleted or does not exist — idempotent
	}

	action.Metadata()["deleted"] = true

	fullPath := fmt.Sprintf("projects/%s/databases/(default)/documents/%s/%s/%s/%s",
		r.client.ProjectID, usersCollection, userID, actionsCollection, actionID)

	actionMap, err := domain.ActionToMap(action)
	if err != nil {
		return fmt.Errorf("failed to convert action to map for soft delete: %w", err)
	}
	if err := r.client.UpdateDocument(ctx, fullPath, actionMap); err != nil {
		return fmt.Errorf("failed to soft-delete action: %w", err)
	}

	return nil
}

// isDeleted reports whether an action has been soft-deleted.
func isDeleted(action *domain.Action) bool {
	v, ok := action.Metadata()["deleted"]
	if !ok {
		return false
	}
	deleted, ok := v.(bool)
	return ok && deleted
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

	events := action.Events()

	// Check for duplicate timestamp
	whenKey := when.UTC().Format(time.RFC3339Nano)
	if _, exists := events[whenKey]; exists {
		return fmt.Errorf("event at timestamp %s already exists", whenKey)
	}

	// Add the event. Store nil when there is no metadata so Firestore persists
	// a nullValue instead of an empty mapValue, avoiding unnecessary nesting.
	var eventData interface{}
	if len(data) > 0 {
		eventData = data
	}
	events[whenKey] = eventData

	// Update the document
	fullPath := fmt.Sprintf("projects/%s/databases/(default)/documents/%s/%s/%s/%s",
		r.client.ProjectID, usersCollection, userID, actionsCollection, actionID)

	actionMap, err := domain.ActionToMap(action)
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
	events := action.Events()
	if events != nil {
		delete(events, whenKey)
	}

	// Update the document
	fullPath := fmt.Sprintf("projects/%s/databases/(default)/documents/%s/%s/%s/%s",
		r.client.ProjectID, usersCollection, userID, actionsCollection, actionID)

	actionMap, err := domain.ActionToMap(action)
	if err != nil {
		return fmt.Errorf("failed to convert action to map after deleting event: %w", err)
	}
	if err := r.client.UpdateDocument(ctx, fullPath, actionMap); err != nil {
		return fmt.Errorf("failed to delete event: %w", err)
	}

	return nil
}
