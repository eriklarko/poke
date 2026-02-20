package firebase

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// FirebaseClient holds Firebase project configuration and the authenticated
// user's session tokens. It exposes all supported auth methods and provides
// the ID token required by downstream services (e.g. FirestoreClient).
type FirebaseClient struct {
	ProjectID string
	APIKey    string

	// Auth state — populated after a successful sign-in or token exchange.
	IDToken      string
	RefreshToken string
	UserID       string

	client *http.Client
}

// FirebaseAuthResponse is the common response shape returned by the Firebase
// Identity Toolkit REST API for all sign-in operations.
type FirebaseAuthResponse struct {
	IDToken      string `json:"idToken"`
	Email        string `json:"email"`
	RefreshToken string `json:"refreshToken"`
	ExpiresIn    string `json:"expiresIn"`
	LocalID      string `json:"localId"`
	Registered   bool   `json:"registered"`
}

// NewFirebaseClient creates a Firebase client for the given project. No
// authentication is performed; call one of the SignIn* methods or
// ExchangeRefreshToken afterwards.
func NewFirebaseClient(projectID, apiKey string) *FirebaseClient {
	return &FirebaseClient{
		ProjectID: projectID,
		APIKey:    apiKey,
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// ── Token accessors ──────────────────────────────────────────────────────────

// GetIDToken returns the current short-lived ID token.
func (c *FirebaseClient) GetIDToken() string { return c.IDToken }

// GetRefreshToken returns the long-lived refresh token.
func (c *FirebaseClient) GetRefreshToken() string { return c.RefreshToken }

// GetUserID returns the Firebase user ID (UID) for the authenticated user.
func (c *FirebaseClient) GetUserID() string { return c.UserID }

// IsAuthenticated reports whether the client holds a non-empty ID token and user ID.
func (c *FirebaseClient) IsAuthenticated() bool {
	return c.IDToken != "" && c.UserID != ""
}

// SetIDToken manually injects an already-obtained ID token and its associated
// user ID. Useful when the token was acquired outside this client (e.g. passed
// in via an environment variable).
func (c *FirebaseClient) SetIDToken(token, userID string) {
	c.IDToken = token
	c.UserID = userID
}

// JWTSubject decodes the payload segment of a JWT (without verifying the
// signature) and returns the "sub" claim, which is the Firebase user ID.
func JWTSubject(token string) (string, error) {
	parts := strings.SplitN(token, ".", 3)
	if len(parts) != 3 {
		return "", fmt.Errorf("not a valid JWT (expected 3 segments)")
	}
	// JWT uses base64url encoding without padding.
	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return "", fmt.Errorf("base64 decode: %w", err)
	}
	var claims struct {
		Sub string `json:"sub"`
	}
	if err := json.Unmarshal(payload, &claims); err != nil {
		return "", fmt.Errorf("JSON unmarshal: %w", err)
	}
	if claims.Sub == "" {
		return "", fmt.Errorf("JWT payload has no \"sub\" claim")
	}
	return claims.Sub, nil
}

// ── Auth methods ─────────────────────────────────────────────────────────────

// ExchangeRefreshToken exchanges a long-lived refresh token for a fresh ID
// token. The refresh token is also rotated and stored on the client.
// This is the recommended authentication path for non-interactive environments.
func (c *FirebaseClient) ExchangeRefreshToken(ctx context.Context, refreshToken string) error {
	endpoint := fmt.Sprintf("https://securetoken.googleapis.com/v1/token?key=%s", c.APIKey)

	form := url.Values{}
	form.Set("grant_type", "refresh_token")
	form.Set("refresh_token", refreshToken)

	req, err := http.NewRequestWithContext(ctx, "POST", endpoint,
		bytes.NewBufferString(form.Encode()))
	if err != nil {
		return fmt.Errorf("failed to create refresh request: %w", err)
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to exchange refresh token: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("failed to read refresh response: %w", err)
	}
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("token refresh failed with status %d: %s", resp.StatusCode, string(body))
	}

	var tokenResp struct {
		IDToken      string `json:"id_token"`
		RefreshToken string `json:"refresh_token"`
		UserID       string `json:"user_id"`
	}
	if err := json.Unmarshal(body, &tokenResp); err != nil {
		return fmt.Errorf("failed to parse refresh response: %w", err)
	}

	c.IDToken = tokenResp.IDToken
	c.RefreshToken = tokenResp.RefreshToken
	c.UserID = tokenResp.UserID
	return nil
}

// SignInWithEmailPassword signs in with an email/password credential.
func (c *FirebaseClient) SignInWithEmailPassword(ctx context.Context, email, password string) error {
	endpoint := fmt.Sprintf("https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=%s", c.APIKey)
	return c.doAuthRequest(ctx, endpoint, map[string]interface{}{
		"email":             email,
		"password":          password,
		"returnSecureToken": true,
	})
}

// SignInAnonymously creates an anonymous Firebase session.
func (c *FirebaseClient) SignInAnonymously(ctx context.Context) error {
	endpoint := fmt.Sprintf("https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=%s", c.APIKey)
	return c.doAuthRequest(ctx, endpoint, map[string]interface{}{
		"returnSecureToken": true,
	})
}

// SignInWithGoogle completes a full Google OAuth 2.0 flow: it spins up a
// temporary local HTTP server to receive the browser redirect, exchanges the
// auth code for a Google ID token, then signs that token into Firebase.
//
// openBrowserFunc is called with the authorization URL so the caller can open
// it however it likes (e.g. xdg-open, printing to stdout, etc.).
func (c *FirebaseClient) SignInWithGoogle(ctx context.Context, clientID, clientSecret string, openBrowserFunc func(string)) error {
	state := generateRandomState()

	codeChan := make(chan string, 1)
	errChan := make(chan error, 1)

	server := &http.Server{Addr: ":8765"}
	http.HandleFunc("/callback", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Query().Get("state") != state {
			errChan <- fmt.Errorf("state mismatch: potential CSRF attack")
			fmt.Fprintf(w, "<html><body><h1>Error: Invalid state parameter</h1></body></html>")
			return
		}
		code := r.URL.Query().Get("code")
		if code == "" {
			errChan <- fmt.Errorf("no authorization code received")
			fmt.Fprintf(w, "<html><body><h1>Error: No authorization code</h1></body></html>")
			return
		}
		codeChan <- code
		fmt.Fprintf(w, "<html><body><h1>Success!</h1><p>You can close this window and return to the terminal.</p></body></html>")
	})
	go func() {
		if err := server.ListenAndServe(); err != http.ErrServerClosed {
			errChan <- err
		}
	}()
	defer server.Shutdown(ctx) //nolint:errcheck

	authURL := fmt.Sprintf(
		"https://accounts.google.com/o/oauth2/v2/auth?"+
			"client_id=%s&redirect_uri=%s&response_type=code&scope=%s&state=%s&access_type=offline&prompt=consent",
		url.QueryEscape(clientID),
		url.QueryEscape("http://localhost:8765/callback"),
		url.QueryEscape("openid email profile"),
		state,
	)

	if openBrowserFunc != nil {
		openBrowserFunc(authURL)
	}

	var code string
	select {
	case code = <-codeChan:
	case err := <-errChan:
		return fmt.Errorf("oauth callback error: %w", err)
	case <-time.After(5 * time.Minute):
		return fmt.Errorf("timeout waiting for Google authentication")
	}

	tokenPayload := url.Values{
		"code":          {code},
		"client_id":     {clientID},
		"client_secret": {clientSecret},
		"redirect_uri":  {"http://localhost:8765/callback"},
		"grant_type":    {"authorization_code"},
	}
	tokenResp, err := c.client.PostForm("https://oauth2.googleapis.com/token", tokenPayload)
	if err != nil {
		return fmt.Errorf("failed to exchange code for tokens: %w", err)
	}
	defer tokenResp.Body.Close()

	tokenBody, err := io.ReadAll(tokenResp.Body)
	if err != nil {
		return fmt.Errorf("failed to read token response: %w", err)
	}
	if tokenResp.StatusCode != http.StatusOK {
		return fmt.Errorf("token exchange failed with status %d: %s", tokenResp.StatusCode, string(tokenBody))
	}

	var tokenData struct {
		IDToken string `json:"id_token"`
	}
	if err := json.Unmarshal(tokenBody, &tokenData); err != nil {
		return fmt.Errorf("failed to parse token response: %w", err)
	}

	return c.signInWithGoogleIDToken(ctx, tokenData.IDToken)
}

// signInWithGoogleIDToken signs in to Firebase using a Google ID token.
func (c *FirebaseClient) signInWithGoogleIDToken(ctx context.Context, googleIDToken string) error {
	endpoint := fmt.Sprintf("https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=%s", c.APIKey)
	return c.doAuthRequest(ctx, endpoint, map[string]interface{}{
		"postBody":            fmt.Sprintf("id_token=%s&providerId=google.com", googleIDToken),
		"requestUri":          "http://localhost",
		"returnIdpCredential": true,
		"returnSecureToken":   true,
	})
}

// ── Internal helpers ─────────────────────────────────────────────────────────

// doAuthRequest is shared by all sign-in methods: POSTs a JSON payload to an
// Identity Toolkit endpoint and stores the resulting tokens on the client.
func (c *FirebaseClient) doAuthRequest(ctx context.Context, endpoint string, payload map[string]interface{}) error {
	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", endpoint, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("failed to read response: %w", err)
	}
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("auth request failed with status %d: %s", resp.StatusCode, string(body))
	}

	var authResp FirebaseAuthResponse
	if err := json.Unmarshal(body, &authResp); err != nil {
		return fmt.Errorf("failed to parse response: %w", err)
	}

	c.IDToken = authResp.IDToken
	c.RefreshToken = authResp.RefreshToken
	c.UserID = authResp.LocalID
	return nil
}

// generateRandomState generates a random state string for OAuth CSRF protection.
func generateRandomState() string {
	b := make([]byte, 32)
	rand.Read(b) //nolint:errcheck
	return base64.URLEncoding.EncodeToString(b)
}
