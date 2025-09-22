package service

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/cocahonka/hecate/backend/user_service/internal/service/mocks"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.uber.org/zap"
)

func TestRegister_Init(t *testing.T) {
	logger := zap.NewNop()
	challengeTTL := 5 * time.Minute

	t.Run("successful registration", func(t *testing.T) {
		// Arrange
		mockChecker := mocks.NewMocknicknameChecker(t)
		mockSaver := mocks.NewMockchallengeSaver(t)

		mockChecker.EXPECT().
			IsExists(mock.Anything, "testuser").
			Return(false, nil).
			Once()

		mockSaver.EXPECT().
			Save(mock.Anything, "testuser", mock.AnythingOfType("string"), challengeTTL).
			Return(nil).
			Once()

		service := NewRegisterService(logger, mockChecker, mockSaver, challengeTTL)

		// Act
		challenge, err := service.Init(context.Background(), "testuser")

		// Assert
		assert.NoError(t, err)
		assert.NotEmpty(t, challenge)
		assert.Len(t, challenge, 36) // UUID v4 length with hyphens
	})

	t.Run("nickname already exists", func(t *testing.T) {
		// Arrange
		mockChecker := mocks.NewMocknicknameChecker(t)
		mockSaver := mocks.NewMockchallengeSaver(t)

		mockChecker.EXPECT().
			IsExists(mock.Anything, "existinguser").
			Return(true, nil).
			Once()

		service := NewRegisterService(logger, mockChecker, mockSaver, challengeTTL)

		// Act
		challenge, err := service.Init(context.Background(), "existinguser")

		// Assert
		assert.Error(t, err)
		assert.Equal(t, domain.ErrNicknameIsNotUnique, err)
		assert.Empty(t, challenge)
	})

	t.Run("nickname check error", func(t *testing.T) {
		// Arrange
		mockChecker := mocks.NewMocknicknameChecker(t)
		mockSaver := mocks.NewMockchallengeSaver(t)
		dbError := errors.New("database connection error")

		mockChecker.EXPECT().
			IsExists(mock.Anything, "testuser").
			Return(false, dbError).
			Once()

		service := NewRegisterService(logger, mockChecker, mockSaver, challengeTTL)

		// Act
		challenge, err := service.Init(context.Background(), "testuser")

		// Assert
		assert.Error(t, err)
		assert.Equal(t, dbError, err)
		assert.Empty(t, challenge)
	})

	t.Run("challenge save error", func(t *testing.T) {
		// Arrange
		mockChecker := mocks.NewMocknicknameChecker(t)
		mockSaver := mocks.NewMockchallengeSaver(t)
		saveError := errors.New("redis connection error")

		mockChecker.EXPECT().
			IsExists(mock.Anything, "testuser").
			Return(false, nil).
			Once()

		mockSaver.EXPECT().
			Save(mock.Anything, "testuser", mock.AnythingOfType("string"), challengeTTL).
			Return(saveError).
			Once()

		service := NewRegisterService(logger, mockChecker, mockSaver, challengeTTL)

		// Act
		challenge, err := service.Init(context.Background(), "testuser")

		// Assert
		assert.Error(t, err)
		assert.Equal(t, saveError, err)
		assert.Empty(t, challenge)
	})

	t.Run("context cancellation", func(t *testing.T) {
		// Arrange
		mockChecker := mocks.NewMocknicknameChecker(t)
		mockSaver := mocks.NewMockchallengeSaver(t)

		ctx, cancel := context.WithCancel(context.Background())
		cancel() // Cancel context immediately

		mockChecker.EXPECT().
			IsExists(mock.Anything, "testuser").
			Return(false, context.Canceled).
			Once()

		service := NewRegisterService(logger, mockChecker, mockSaver, challengeTTL)

		// Act
		challenge, err := service.Init(ctx, "testuser")

		// Assert
		assert.Error(t, err)
		assert.Equal(t, context.Canceled, err)
		assert.Empty(t, challenge)
	})
}

func TestGenerateChallenge(t *testing.T) {
	t.Run("generates unique challenges", func(t *testing.T) {
		// Act
		challenge1 := generateChallenge()
		challenge2 := generateChallenge()

		// Assert
		assert.NotEmpty(t, challenge1)
		assert.NotEmpty(t, challenge2)
		assert.NotEqual(t, challenge1, challenge2)
		assert.Len(t, challenge1, 36) // UUID v4 length with hyphens
		assert.Len(t, challenge2, 36)
	})

	t.Run("challenge format validation", func(t *testing.T) {
		// Act
		challenge := generateChallenge()

		// Assert
		// UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
		assert.Regexp(t, `^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$`, challenge)
	})
}
