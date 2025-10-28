package service

import (
	"testing"
	"time"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestTokenService_ValidateRefreshToken(t *testing.T) {
	secret := "test-secret-key"
	tokenService := NewTokenService(secret, 15*time.Minute, 24*time.Hour)

	t.Run("valid refresh token", func(t *testing.T) {
		user := domain.User{
			ID:       uuid.New(),
			Nickname: "testuser",
			Pub9c:    "pub9c",
			Pub9d:    "pub9d",
		}

		_, refreshToken, err := tokenService.Generate(user)
		require.NoError(t, err)

		userID, err := tokenService.ValidateRefreshToken(refreshToken)
		assert.NoError(t, err)
		assert.Equal(t, user.ID.String(), userID)
	})

	t.Run("invalid token format", func(t *testing.T) {
		userID, err := tokenService.ValidateRefreshToken("invalid-token")
		assert.Error(t, err)
		assert.Empty(t, userID)
	})

	t.Run("token with invalid signature", func(t *testing.T) {
		differentSecret := "different-secret"
		differentService := NewTokenService(differentSecret, 15*time.Minute, 24*time.Hour)

		user := domain.User{
			ID:       uuid.New(),
			Nickname: "testuser",
			Pub9c:    "pub9c",
			Pub9d:    "pub9d",
		}

		_, refreshToken, err := differentService.Generate(user)
		require.NoError(t, err)

		userID, err := tokenService.ValidateRefreshToken(refreshToken)
		assert.Error(t, err)
		assert.Empty(t, userID)
	})

	t.Run("expired token", func(t *testing.T) {
		expiredService := NewTokenService(secret, 15*time.Minute, -1*time.Hour)

		user := domain.User{
			ID:       uuid.New(),
			Nickname: "testuser",
			Pub9c:    "pub9c",
			Pub9d:    "pub9d",
		}

		_, refreshToken, err := expiredService.Generate(user)
		require.NoError(t, err)

		userID, err := tokenService.ValidateRefreshToken(refreshToken)
		assert.Error(t, err)
		assert.Empty(t, userID)
	})

	t.Run("empty token", func(t *testing.T) {
		userID, err := tokenService.ValidateRefreshToken("")
		assert.Error(t, err)
		assert.Empty(t, userID)
	})
}
