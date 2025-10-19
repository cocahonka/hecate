package service

import (
	"context"
	"errors"
	"testing"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/cocahonka/hecate/backend/user_service/internal/service/mocks"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"go.uber.org/zap"
)

func TestLoginService_Verify(t *testing.T) {
	logger, _ := zap.NewDevelopment()
	ctx := context.Background()

	nickname := "testuser"
	challenge := "sample_challenge"
	user := &domain.User{
		ID:       uuid.New(),
		Nickname: nickname,
		Pub9c:    "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...\n-----END PUBLIC KEY-----",
	}
	accessToken := "access_token"
	refreshToken := "refresh_token"

	tests := []struct {
		name         string
		signature    string
		setupMocks   func(cm *mocks.MockchallengeManager, up *mocks.MockUserProvider, tg *mocks.MockTokenGenerator)
		expectErr    bool
		expectErrStr string
		expectToken  bool
	}{
		{
			name:      "Challenge not found",
			signature: "c2FtcGxl", // valid base64
			setupMocks: func(cm *mocks.MockchallengeManager, up *mocks.MockUserProvider, tg *mocks.MockTokenGenerator) {
				cm.On("Load", ctx, nickname).Return("", errors.New("cache miss")).Once()
			},
			expectErr:    true,
			expectErrStr: "cache miss",
		},
		{
			name:      "User not found",
			signature: "c2FtcGxl",
			setupMocks: func(cm *mocks.MockchallengeManager, up *mocks.MockUserProvider, tg *mocks.MockTokenGenerator) {
				cm.On("Load", ctx, nickname).Return(challenge, nil).Once()
				up.On("Get", ctx, nickname).Return(nil, domain.ErrUserNotFound).Once()
			},
			expectErr:    true,
			expectErrStr: domain.ErrUserNotFound.Error(),
		},
		{
			name:      "Invalid signature format",
			signature: "invalid_base64!!!",
			setupMocks: func(cm *mocks.MockchallengeManager, up *mocks.MockUserProvider, tg *mocks.MockTokenGenerator) {
				cm.On("Load", ctx, nickname).Return(challenge, nil).Once()
				up.On("Get", ctx, nickname).Return(user, nil).Once()
			},
			expectErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			challengeManagerMock := mocks.NewMockchallengeManager(t)
			userProviderMock := mocks.NewMockUserProvider(t)
			tokenGeneratorMock := mocks.NewMockTokenGenerator(t)

			tt.setupMocks(challengeManagerMock, userProviderMock, tokenGeneratorMock)

			service := NewLoginService(logger, challengeManagerMock, userProviderMock, tokenGeneratorMock, 0)

			access, refresh, err := service.Verify(ctx, nickname, tt.signature)

			if tt.expectErr {
				assert.Error(t, err)
				if tt.expectErrStr != "" {
					assert.Contains(t, err.Error(), tt.expectErrStr)
				}
				assert.Empty(t, access)
				assert.Empty(t, refresh)
			} else {
				assert.NoError(t, err)
			}

			if tt.expectToken {
				assert.Equal(t, accessToken, access)
				assert.Equal(t, refreshToken, refresh)
			}

			challengeManagerMock.AssertExpectations(t)
			userProviderMock.AssertExpectations(t)
			tokenGeneratorMock.AssertExpectations(t)
		})
	}
}
