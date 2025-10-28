package service

import (
	"context"
	"errors"
	"testing"
	"time"

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
			userProviderByIDMock := mocks.NewMockUserProviderByID(t)
			tokenGeneratorMock := mocks.NewMockTokenGenerator(t)
			tokenValidatorMock := mocks.NewMockTokenValidator(t)
			refreshTokenManagerMock := mocks.NewMockRefreshTokenManager(t)

			tt.setupMocks(challengeManagerMock, userProviderMock, tokenGeneratorMock)

			service := NewLoginService(logger, challengeManagerMock, userProviderMock, userProviderByIDMock, tokenGeneratorMock, tokenValidatorMock, refreshTokenManagerMock, 0, 0)

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

func TestLoginService_Refresh(t *testing.T) {
	logger, _ := zap.NewDevelopment()
	ctx := context.Background()

	userID := uuid.New()
	user := &domain.User{
		ID:       userID,
		Nickname: "testuser",
		Pub9c:    "pub9c",
		Pub9d:    "pub9d",
	}
	nickname := "testuser"
	refreshToken := "valid_refresh_token"
	newAccessToken := "new_access_token"
	newRefreshToken := "new_refresh_token"

	tests := []struct {
		name       string
		token      string
		nickname   *string
		setupMocks func(
			tv *mocks.MockTokenValidator,
			upByID *mocks.MockUserProviderByID,
			up *mocks.MockUserProvider,
			rtm *mocks.MockRefreshTokenManager,
			tg *mocks.MockTokenGenerator,
		)
		expectErr    bool
		expectErrIs  error
		expectTokens bool
	}{
		{
			name:     "successful refresh with user ID in token",
			token:    refreshToken,
			nickname: nil,
			setupMocks: func(tv *mocks.MockTokenValidator, upByID *mocks.MockUserProviderByID, up *mocks.MockUserProvider, rtm *mocks.MockRefreshTokenManager, tg *mocks.MockTokenGenerator) {
				tv.On("ValidateRefreshToken", refreshToken).Return(userID.String(), nil).Once()
				upByID.On("GetByID", ctx, userID.String()).Return(user, nil).Once()
				rtm.On("GetRefreshToken", ctx, userID.String()).Return(refreshToken, nil).Once()
				tg.On("Generate", *user).Return(newAccessToken, newRefreshToken, nil).Once()
				rtm.On("SaveRefreshToken", ctx, userID.String(), newRefreshToken, time.Duration(0)).Return(nil).Once()
			},
			expectErr:    false,
			expectTokens: true,
		},
		{
			name:     "successful refresh with nickname provided",
			token:    refreshToken,
			nickname: &nickname,
			setupMocks: func(tv *mocks.MockTokenValidator, upByID *mocks.MockUserProviderByID, up *mocks.MockUserProvider, rtm *mocks.MockRefreshTokenManager, tg *mocks.MockTokenGenerator) {
				tv.On("ValidateRefreshToken", refreshToken).Return("", nil).Once()
				up.On("Get", ctx, nickname).Return(user, nil).Once()
				rtm.On("GetRefreshToken", ctx, userID.String()).Return(refreshToken, nil).Once()
				tg.On("Generate", *user).Return(newAccessToken, newRefreshToken, nil).Once()
				rtm.On("SaveRefreshToken", ctx, userID.String(), newRefreshToken, time.Duration(0)).Return(nil).Once()
			},
			expectErr:    false,
			expectTokens: true,
		},
		{
			name:     "invalid refresh token",
			token:    "invalid_token",
			nickname: nil,
			setupMocks: func(tv *mocks.MockTokenValidator, upByID *mocks.MockUserProviderByID, up *mocks.MockUserProvider, rtm *mocks.MockRefreshTokenManager, tg *mocks.MockTokenGenerator) {
				tv.On("ValidateRefreshToken", "invalid_token").Return("", errors.New("invalid token")).Once()
			},
			expectErr:   true,
			expectErrIs: domain.ErrInvalidRefreshToken,
		},
		{
			name:     "no user ID in token and no nickname provided",
			token:    refreshToken,
			nickname: nil,
			setupMocks: func(tv *mocks.MockTokenValidator, upByID *mocks.MockUserProviderByID, up *mocks.MockUserProvider, rtm *mocks.MockRefreshTokenManager, tg *mocks.MockTokenGenerator) {
				tv.On("ValidateRefreshToken", refreshToken).Return("", nil).Once()
			},
			expectErr:   true,
			expectErrIs: domain.ErrInvalidRefreshToken,
		},
		{
			name:     "user not found by ID",
			token:    refreshToken,
			nickname: nil,
			setupMocks: func(tv *mocks.MockTokenValidator, upByID *mocks.MockUserProviderByID, up *mocks.MockUserProvider, rtm *mocks.MockRefreshTokenManager, tg *mocks.MockTokenGenerator) {
				tv.On("ValidateRefreshToken", refreshToken).Return(userID.String(), nil).Once()
				upByID.On("GetByID", ctx, userID.String()).Return(nil, domain.ErrUserNotFound).Once()
			},
			expectErr:   true,
			expectErrIs: domain.ErrUserNotFound,
		},
		{
			name:     "user not found by nickname",
			token:    refreshToken,
			nickname: &nickname,
			setupMocks: func(tv *mocks.MockTokenValidator, upByID *mocks.MockUserProviderByID, up *mocks.MockUserProvider, rtm *mocks.MockRefreshTokenManager, tg *mocks.MockTokenGenerator) {
				tv.On("ValidateRefreshToken", refreshToken).Return("", nil).Once()
				up.On("Get", ctx, nickname).Return(nil, domain.ErrUserNotFound).Once()
			},
			expectErr:   true,
			expectErrIs: domain.ErrUserNotFound,
		},
		{
			name:     "refresh token mismatch",
			token:    refreshToken,
			nickname: nil,
			setupMocks: func(tv *mocks.MockTokenValidator, upByID *mocks.MockUserProviderByID, up *mocks.MockUserProvider, rtm *mocks.MockRefreshTokenManager, tg *mocks.MockTokenGenerator) {
				tv.On("ValidateRefreshToken", refreshToken).Return(userID.String(), nil).Once()
				upByID.On("GetByID", ctx, userID.String()).Return(user, nil).Once()
				rtm.On("GetRefreshToken", ctx, userID.String()).Return("different_token", nil).Once()
			},
			expectErr:   true,
			expectErrIs: domain.ErrRefreshTokenMismatch,
		},
		{
			name:     "stored refresh token not found",
			token:    refreshToken,
			nickname: nil,
			setupMocks: func(tv *mocks.MockTokenValidator, upByID *mocks.MockUserProviderByID, up *mocks.MockUserProvider, rtm *mocks.MockRefreshTokenManager, tg *mocks.MockTokenGenerator) {
				tv.On("ValidateRefreshToken", refreshToken).Return(userID.String(), nil).Once()
				upByID.On("GetByID", ctx, userID.String()).Return(user, nil).Once()
				rtm.On("GetRefreshToken", ctx, userID.String()).Return("", domain.ErrRefreshTokenNotFound).Once()
			},
			expectErr:   true,
			expectErrIs: domain.ErrInvalidRefreshToken,
		},
		{
			name:     "error generating new tokens",
			token:    refreshToken,
			nickname: nil,
			setupMocks: func(tv *mocks.MockTokenValidator, upByID *mocks.MockUserProviderByID, up *mocks.MockUserProvider, rtm *mocks.MockRefreshTokenManager, tg *mocks.MockTokenGenerator) {
				tv.On("ValidateRefreshToken", refreshToken).Return(userID.String(), nil).Once()
				upByID.On("GetByID", ctx, userID.String()).Return(user, nil).Once()
				rtm.On("GetRefreshToken", ctx, userID.String()).Return(refreshToken, nil).Once()
				tg.On("Generate", *user).Return("", "", errors.New("token generation error")).Once()
			},
			expectErr: true,
		},
		{
			name:     "error saving new refresh token",
			token:    refreshToken,
			nickname: nil,
			setupMocks: func(tv *mocks.MockTokenValidator, upByID *mocks.MockUserProviderByID, up *mocks.MockUserProvider, rtm *mocks.MockRefreshTokenManager, tg *mocks.MockTokenGenerator) {
				tv.On("ValidateRefreshToken", refreshToken).Return(userID.String(), nil).Once()
				upByID.On("GetByID", ctx, userID.String()).Return(user, nil).Once()
				rtm.On("GetRefreshToken", ctx, userID.String()).Return(refreshToken, nil).Once()
				tg.On("Generate", *user).Return(newAccessToken, newRefreshToken, nil).Once()
				rtm.On("SaveRefreshToken", ctx, userID.String(), newRefreshToken, time.Duration(0)).Return(errors.New("save error")).Once()
			},
			expectErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			challengeManagerMock := mocks.NewMockchallengeManager(t)
			userProviderMock := mocks.NewMockUserProvider(t)
			userProviderByIDMock := mocks.NewMockUserProviderByID(t)
			tokenGeneratorMock := mocks.NewMockTokenGenerator(t)
			tokenValidatorMock := mocks.NewMockTokenValidator(t)
			refreshTokenManagerMock := mocks.NewMockRefreshTokenManager(t)

			tt.setupMocks(tokenValidatorMock, userProviderByIDMock, userProviderMock, refreshTokenManagerMock, tokenGeneratorMock)

			service := NewLoginService(logger, challengeManagerMock, userProviderMock, userProviderByIDMock, tokenGeneratorMock, tokenValidatorMock, refreshTokenManagerMock, 0, 0)

			access, refresh, err := service.Refresh(ctx, tt.token, tt.nickname)

			if tt.expectErr {
				assert.Error(t, err)
				if tt.expectErrIs != nil {
					assert.ErrorIs(t, err, tt.expectErrIs)
				}
				assert.Empty(t, access)
				assert.Empty(t, refresh)
			} else {
				assert.NoError(t, err)
			}

			if tt.expectTokens {
				assert.Equal(t, newAccessToken, access)
				assert.Equal(t, newRefreshToken, refresh)
			}

			tokenValidatorMock.AssertExpectations(t)
			userProviderByIDMock.AssertExpectations(t)
			userProviderMock.AssertExpectations(t)
			refreshTokenManagerMock.AssertExpectations(t)
			tokenGeneratorMock.AssertExpectations(t)
		})
	}
}
