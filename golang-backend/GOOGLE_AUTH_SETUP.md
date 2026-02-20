# Google OAuth Setup Guide

This guide explains how to set up Google Sign-In for the Poke backend server.

## Why Google Sign-In?

The backend server needs to authenticate as a user to access Firebase/Firestore. You can choose between:

1. **Google Sign-In** (recommended) - Use your existing Google account
2. **Email + Password** - Traditional authentication
3. **Anonymous** - Quick testing without credentials

## Setting up Google OAuth

### Step 1: Create OAuth 2.0 Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project (or create a new project)
3. Navigate to **APIs & Services** > **Credentials**
4. Click **"+ CREATE CREDENTIALS"** > **"OAuth client ID"**
5. If prompted, configure the OAuth consent screen:
   - User Type: **External** (unless you have a Google Workspace)
   - Fill in required fields (App name, User support email, etc.)
   - Add your email to **Test users** during development
6. Application type: **Web application**
7. Add authorized redirect URI: `http://localhost:8765/callback`
8. Click **Create**
9. Copy the **Client ID** and **Client Secret**

### Step 2: Configure Environment Variables

Add to your `.env` file:

```bash
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
```

### Step 3: Start the Server

```bash
go run ./cmd/api/main.go
```

When prompted, select option `1` for Google Sign-In:

```
=== Firebase Authentication ===
Choose authentication method:
  1) Google Sign-In (recommended)
  2) Email + Password
  3) Anonymous

Enter choice (1/2/3) [1]: 1
```

The server will:
1. Start a temporary local web server on port 8765
2. Open your default browser to Google's sign-in page
3. Wait for you to authenticate
4. Receive the authentication callback
5. Exchange the token for Firebase credentials
6. Start the API server

## Troubleshooting

### Browser doesn't open automatically

If the browser doesn't open, copy the URL from the terminal and paste it into your browser manually.

### "Redirect URI mismatch" error

Make sure you added `http://localhost:8765/callback` (exactly) to the authorized redirect URIs in Google Cloud Console.

### "Access blocked: This app's request is invalid"

Your OAuth consent screen needs to be configured. Go back to Google Cloud Console and complete the OAuth consent screen setup.

### Port 8765 already in use

Another application is using port 8765. Either:
- Stop the other application
- Or modify the port in `firebase_client.go` (search for `:8765`)

## Security Notes

- The OAuth flow uses CSRF protection with a random state parameter
- The local callback server only runs during authentication
- Credentials are never logged or stored permanently
- The Google Client Secret should be kept confidential

## Alternative: Email + Password

If you prefer not to use Google Sign-In, you can create a test user:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Navigate to **Authentication** > **Users**
3. Click **Add user**
4. Enter email and password
5. Use option `2` when starting the server

## Alternative: Anonymous Authentication

For quick testing without any credentials:

1. Enable Anonymous authentication in Firebase Console
2. Select option `3` when starting the server

Anonymous users have limited permissions and each session creates a new user ID.
