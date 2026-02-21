package firebase

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// newTestFirebaseClient returns a FirebaseClient wired to the provided test
// HTTP server. The client's tokenRefreshURL points to srv so that
// ExchangeRefreshToken never touches the real Firebase API.
func newTestFirebaseClient(srv *httptest.Server) *FirebaseClient {
	return &FirebaseClient{
		ProjectID:       "test-project",
		APIKey:          "test-key",
		RefreshToken:    "test-refresh-token",
		tokenRefreshURL: srv.URL + "/token",
		client:          &http.Client{Timeout: 5 * time.Second},
	}
}

// tokenRefreshHandler returns an HTTP handler that responds with a valid
// token-refresh JSON payload and increments counter on each call.
func tokenRefreshHandler(counter *atomic.Int32) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		counter.Add(1)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{ //nolint:errcheck
			"id_token":      "refreshed-id-token",
			"refresh_token": "rotated-refresh-token",
			"user_id":       "uid-123",
		})
	}
}

// TestStartAutomaticTokenRefresh_CallsRefreshAtInterval verifies that the
// background goroutine calls ExchangeRefreshToken at least twice within
// roughly 2× the configured interval.
func TestStartAutomaticTokenRefresh_CallsRefreshAtInterval(t *testing.T) {
	var counter atomic.Int32
	srv := httptest.NewServer(tokenRefreshHandler(&counter))
	defer srv.Close()

	c := newTestFirebaseClient(srv)

	ctx := context.Background()
	cancel := c.StartAutomaticTokenRefresh(ctx, 50*time.Millisecond)
	defer cancel()

	// Wait long enough for at least 2 ticks, then cancel.
	time.Sleep(160 * time.Millisecond)
	cancel()

	assert.GreaterOrEqual(t, counter.Load(), int32(2), "expected at least 2 refresh calls")
}

// TestStartAutomaticTokenRefresh_UpdatesTokens verifies that after a
// successful refresh the client's tokens are updated.
func TestStartAutomaticTokenRefresh_UpdatesTokens(t *testing.T) {
	var counter atomic.Int32
	srv := httptest.NewServer(tokenRefreshHandler(&counter))
	defer srv.Close()

	c := newTestFirebaseClient(srv)

	ctx := context.Background()
	cancel := c.StartAutomaticTokenRefresh(ctx, 30*time.Millisecond)
	defer cancel()

	// Wait for at least one tick.
	require.Eventually(t, func() bool {
		return counter.Load() >= 1
	}, 200*time.Millisecond, 5*time.Millisecond, "timed out waiting for first refresh")

	cancel()

	assert.Equal(t, "refreshed-id-token", c.IDToken)
	assert.Equal(t, "rotated-refresh-token", c.RefreshToken)
	assert.Equal(t, "uid-123", c.UserID)
}

// TestStartAutomaticTokenRefresh_StopsOnCancel verifies that after cancel()
// is called no further refresh requests are made.
func TestStartAutomaticTokenRefresh_StopsOnCancel(t *testing.T) {
	var counter atomic.Int32
	srv := httptest.NewServer(tokenRefreshHandler(&counter))
	defer srv.Close()

	c := newTestFirebaseClient(srv)

	ctx := context.Background()
	cancel := c.StartAutomaticTokenRefresh(ctx, 30*time.Millisecond)

	// Let it tick at least once, then cancel.
	require.Eventually(t, func() bool {
		return counter.Load() >= 1
	}, 200*time.Millisecond, 5*time.Millisecond, "timed out waiting for first refresh")

	cancel()
	snapshotAfterCancel := counter.Load()

	// Give the goroutine time to fire again if it wasn't actually stopped.
	time.Sleep(80 * time.Millisecond)

	assert.Equal(t, snapshotAfterCancel, counter.Load(), "no further calls after cancel")
}

// TestStartAutomaticTokenRefresh_SkipsWhenNoRefreshToken verifies that no
// HTTP calls are made when RefreshToken is empty.
func TestStartAutomaticTokenRefresh_SkipsWhenNoRefreshToken(t *testing.T) {
	var counter atomic.Int32
	srv := httptest.NewServer(tokenRefreshHandler(&counter))
	defer srv.Close()

	c := newTestFirebaseClient(srv)
	c.RefreshToken = "" // clear so the goroutine should skip

	ctx := context.Background()
	cancel := c.StartAutomaticTokenRefresh(ctx, 20*time.Millisecond)
	defer cancel()

	time.Sleep(70 * time.Millisecond)
	cancel()

	assert.Equal(t, int32(0), counter.Load(), "no calls expected when RefreshToken is empty")
}

// TestStartAutomaticTokenRefresh_HandlesRefreshError verifies that a failed
// refresh (HTTP 401) does not panic and leaves the existing tokens intact.
func TestStartAutomaticTokenRefresh_HandlesRefreshError(t *testing.T) {
	var counter atomic.Int32
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		counter.Add(1)
		w.WriteHeader(http.StatusUnauthorized)
		w.Write([]byte(`{"error":{"code":401,"message":"INVALID_REFRESH_TOKEN"}}`)) //nolint:errcheck
	}))
	defer srv.Close()

	c := newTestFirebaseClient(srv)
	c.IDToken = "original-token"

	ctx := context.Background()
	cancel := c.StartAutomaticTokenRefresh(ctx, 20*time.Millisecond)
	defer cancel()

	// Wait for at least one error response.
	require.Eventually(t, func() bool {
		return counter.Load() >= 1
	}, 200*time.Millisecond, 5*time.Millisecond, "timed out waiting for error refresh attempt")

	cancel()

	// Token must remain unchanged after a failed refresh.
	assert.Equal(t, "original-token", c.IDToken, "token must not be cleared on error")
}
