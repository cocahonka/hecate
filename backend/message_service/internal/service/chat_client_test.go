package service

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"go.uber.org/zap"
)

func TestHTTPChatClient_CheckMembership(t *testing.T) {
	logger := zap.NewNop()

	t.Run("success - user is member", func(t *testing.T) {
		chatID := uuid.New()
		token := "test_jwt_token"

		// Create mock server
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Check request
			assert.Equal(t, "GET", r.Method)
			assert.Contains(t, r.URL.Path, chatID.String())
			assert.Equal(t, "Bearer "+token, r.Header.Get("Authorization"))

			// Send response
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(checkMemberResponse{IsMember: true})
		}))
		defer server.Close()

		client := NewChatClient(server.URL, logger)

		isMember, err := client.CheckMembership(context.Background(), chatID, token)
		assert.NoError(t, err)
		assert.True(t, isMember)
	})

	t.Run("success - user is not member", func(t *testing.T) {
		chatID := uuid.New()
		token := "test_jwt_token"

		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(checkMemberResponse{IsMember: false})
		}))
		defer server.Close()

		client := NewChatClient(server.URL, logger)

		isMember, err := client.CheckMembership(context.Background(), chatID, token)
		assert.NoError(t, err)
		assert.False(t, isMember)
	})

	t.Run("non-200 status code", func(t *testing.T) {
		chatID := uuid.New()
		token := "test_jwt_token"

		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusForbidden)
		}))
		defer server.Close()

		client := NewChatClient(server.URL, logger)

		isMember, err := client.CheckMembership(context.Background(), chatID, token)
		assert.NoError(t, err) // According to implementation, returns false on non-200
		assert.False(t, isMember)
	})

	t.Run("invalid JSON response", func(t *testing.T) {
		chatID := uuid.New()
		token := "test_jwt_token"

		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusOK)
			w.Write([]byte("invalid json"))
		}))
		defer server.Close()

		client := NewChatClient(server.URL, logger)

		isMember, err := client.CheckMembership(context.Background(), chatID, token)
		assert.Error(t, err)
		assert.False(t, isMember)
	})

	t.Run("network error", func(t *testing.T) {
		chatID := uuid.New()
		token := "test_jwt_token"

		// Use invalid URL to force network error
		client := NewChatClient("http://invalid-host-that-does-not-exist-12345.local", logger)

		isMember, err := client.CheckMembership(context.Background(), chatID, token)
		assert.Error(t, err)
		assert.False(t, isMember)
	})

	t.Run("context cancellation", func(t *testing.T) {
		chatID := uuid.New()
		token := "test_jwt_token"

		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// This handler should not be reached due to context cancellation
			t.Error("handler should not be called with cancelled context")
		}))
		defer server.Close()

		client := NewChatClient(server.URL, logger)

		ctx, cancel := context.WithCancel(context.Background())
		cancel() // Cancel immediately

		isMember, err := client.CheckMembership(ctx, chatID, token)
		assert.Error(t, err)
		assert.False(t, isMember)
	})

	t.Run("validates request parameters", func(t *testing.T) {
		chatID := uuid.New()
		token := "my_secure_token_123"

		requestReceived := false
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			requestReceived = true

			// Validate URL path contains chatID
			assert.Contains(t, r.URL.Path, "/api/v1/chats/")
			assert.Contains(t, r.URL.Path, chatID.String())
			assert.Contains(t, r.URL.Path, "/member")

			// Validate Authorization header
			assert.Equal(t, "Bearer "+token, r.Header.Get("Authorization"))

			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(checkMemberResponse{IsMember: true})
		}))
		defer server.Close()

		client := NewChatClient(server.URL, logger)

		_, err := client.CheckMembership(context.Background(), chatID, token)
		assert.NoError(t, err)
		assert.True(t, requestReceived, "server should have received the request")
	})
}

func TestNewChatClient(t *testing.T) {
	t.Run("creates client with correct baseURL", func(t *testing.T) {
		baseURL := "http://chat-service:8080"
		logger := zap.NewNop()

		client := NewChatClient(baseURL, logger)

		assert.NotNil(t, client)
		assert.Equal(t, baseURL, client.baseURL)
		assert.NotNil(t, client.client)
		assert.NotNil(t, client.logger)
	})
}
