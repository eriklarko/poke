package service

import (
	"context"
	"time"

	"larko.se/poke/src/domain"
	"larko.se/poke/src/predictor"
)

// ActionRepository defines the interface for action persistence.
// This interface is declared here (by the consumer) following the Dependency Inversion Principle.
// The service declares what it needs; the repository implements it.
// This allows the service to be tested with mocks and decouples it from infrastructure.
type ActionRepository interface {
	// Create creates a new action
	Create(ctx context.Context, userID string, actionID string, action *domain.Action) error

	// GetByID retrieves an action by its ID
	GetByID(ctx context.Context, userID string, actionID string) (*domain.Action, error)

	// List retrieves all actions for a user
	List(ctx context.Context, userID string) ([]*domain.Action, error)

	// Update updates an existing action
	Update(ctx context.Context, userID string, actionID string, action *domain.Action) error

	// Delete deletes an action
	Delete(ctx context.Context, userID string, actionID string) error

	// AddEvent adds an event to an action
	AddEvent(ctx context.Context, userID string, actionID string, when time.Time, data map[string]interface{}) error

	// DeleteEvent removes an event from an action
	DeleteEvent(ctx context.Context, userID string, actionID string, when time.Time) error
}

// ActionService implements the ActionService port
type ActionService struct {
	repo ActionRepository
}

// NewActionService creates a new action service
func NewActionService(repo ActionRepository) *ActionService {
	return &ActionService{
		repo: repo,
	}
}

// CreateAction creates a new action
func (s *ActionService) CreateAction(ctx context.Context, userID string, actionID string, action *domain.Action) error {
	return s.repo.Create(ctx, userID, actionID, action)
}

// GetAction retrieves an action by ID
func (s *ActionService) GetAction(ctx context.Context, userID string, actionID string) (*domain.Action, error) {
	return s.repo.GetByID(ctx, userID, actionID)
}

// ListActions retrieves all actions for a user
func (s *ActionService) ListActions(ctx context.Context, userID string) ([]*domain.Action, error) {
	return s.repo.List(ctx, userID)
}

// UpdateAction updates an existing action
func (s *ActionService) UpdateAction(ctx context.Context, userID string, actionID string, action *domain.Action) error {
	return s.repo.Update(ctx, userID, actionID, action)
}

// DeleteAction deletes an action
func (s *ActionService) DeleteAction(ctx context.Context, userID string, actionID string) error {
	return s.repo.Delete(ctx, userID, actionID)
}

// LogEvent adds an event to an action
func (s *ActionService) LogEvent(ctx context.Context, userID string, actionID string, when time.Time, data map[string]interface{}) error {
	return s.repo.AddEvent(ctx, userID, actionID, when, data)
}

// DeleteEvent removes an event from an action
func (s *ActionService) DeleteEvent(ctx context.Context, userID string, actionID string, when time.Time) error {
	return s.repo.DeleteEvent(ctx, userID, actionID, when)
}

// ListReminders returns a predicted reminder for each action that has sufficient event data
func (s *ActionService) ListReminders(ctx context.Context, userID string) ([]*domain.Reminder, error) {
	actions, err := s.repo.List(ctx, userID)
	if err != nil {
		return nil, err
	}

	var reminders []*domain.Reminder

	now := time.Now().UTC()
	for _, action := range actions {
		dueDate := predictor.PredictNext(action, now)
		reminders = append(reminders, &domain.Reminder{
			Action:  *action,
			DueDate: dueDate,
			IsDue:   dueDate != nil && !dueDate.After(now),
		})
	}

	return reminders, nil
}
