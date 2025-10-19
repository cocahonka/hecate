package service

import (
	"context"
	"encoding/base64"
	"errors"
	"testing"
	"time"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/cocahonka/hecate/backend/user_service/internal/service/mocks"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.uber.org/zap"
)

const (
	testNickname  = "testuser"
	testChallenge = "test_challenge"
	existingUser  = "existinguser"
	challengeTTL  = 5 * time.Minute
)

func setupRegisterService(t *testing.T) (*Register, *mocks.MockUserProvider, *mocks.MockchallengeManager, *mocks.MockUserSaver) {
	t.Helper()

	logger := zap.NewNop()
	mockUserProvider, mockManager, mockUserSaver := setupTestMocksForRegister(t)

	service := NewRegisterService(logger, mockUserProvider, mockManager, mockUserSaver, challengeTTL)
	return service, mockUserProvider, mockManager, mockUserSaver
}

func TestRegister_Init(t *testing.T) {
	tests := []struct {
		name     string
		nickname string
		setup    func(*mocks.MockUserProvider, *mocks.MockchallengeManager)
		wantErr  error
	}{
		{
			name:     "successful registration",
			nickname: testNickname,
			setup: func(userProvider *mocks.MockUserProvider, manager *mocks.MockchallengeManager) {
				userProvider.EXPECT().
					Get(mock.Anything, testNickname).
					Return(nil, domain.ErrUserNotFound).Once()
				manager.EXPECT().
					Save(mock.Anything, testNickname, mock.AnythingOfType("string"), challengeTTL).
					Return(nil).Once()
			},
			wantErr: nil,
		},
		{
			name:     "nickname already exists",
			nickname: existingUser,
			setup: func(userProvider *mocks.MockUserProvider, manager *mocks.MockchallengeManager) {
				userProvider.EXPECT().
					Get(mock.Anything, existingUser).
					Return(&domain.User{}, nil).Once()
			},
			wantErr: domain.ErrNicknameIsNotUnique,
		},
		{
			name:     "nickname check error",
			nickname: testNickname,
			setup: func(userProvider *mocks.MockUserProvider, manager *mocks.MockchallengeManager) {
				dbError := errors.New("database connection error")
				userProvider.EXPECT().
					Get(mock.Anything, testNickname).
					Return(nil, dbError).Once()
			},
			wantErr: errors.New("database connection error"),
		},
		{
			name:     "challenge save error",
			nickname: testNickname,
			setup: func(userProvider *mocks.MockUserProvider, manager *mocks.MockchallengeManager) {
				saveError := errors.New("redis connection error")
				userProvider.EXPECT().
					Get(mock.Anything, testNickname).
					Return(nil, domain.ErrUserNotFound).Once()
				manager.EXPECT().
					Save(mock.Anything, testNickname, mock.AnythingOfType("string"), challengeTTL).
					Return(saveError).Once()
			},
			wantErr: errors.New("redis connection error"),
		},
		{
			name:     "context cancellation",
			nickname: testNickname,
			setup: func(userProvider *mocks.MockUserProvider, manager *mocks.MockchallengeManager) {
				userProvider.EXPECT().
					Get(mock.Anything, testNickname).
					Return(nil, context.Canceled).Once()
			},
			wantErr: context.Canceled,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			service, mockUserProvider, mockManager, _ := setupRegisterService(t)

			// Apply test-specific setup
			if tt.setup != nil {
				tt.setup(mockUserProvider, mockManager)
			}

			ctx := context.Background()
			if tt.name == "context cancellation" {
				var cancel context.CancelFunc
				ctx, cancel = context.WithCancel(context.Background())
				cancel() // Cancel context immediately
			}

			challenge, err := service.Init(ctx, tt.nickname)

			if tt.wantErr != nil {
				assert.Error(t, err)
				assert.Equal(t, tt.wantErr.Error(), err.Error())
				assert.Empty(t, challenge)
			} else {
				assert.NoError(t, err)
				assert.NotEmpty(t, challenge)
			}

			mockUserProvider.AssertExpectations(t)
			mockManager.AssertExpectations(t)
		})
	}
}

func TestGenerateChallenge(t *testing.T) {
	t.Run("generates unique challenges", func(t *testing.T) {
		challenge1 := generateChallenge()
		challenge2 := generateChallenge()

		assert.NotEmpty(t, challenge1)
		assert.NotEmpty(t, challenge2)
		assert.NotEqual(t, challenge1, challenge2)
	})

	t.Run("challenge format validation", func(t *testing.T) {
		challenge := generateChallenge()

		challengeDecoded, err := base64.RawURLEncoding.DecodeString(challenge)

		assert.NoError(t, err)
		assert.Len(t, challengeDecoded, 32)
	})
}

func TestRegister_VerifyAndComplete(t *testing.T) {
	nickname := testNickname
	challenge := testChallenge

	// Generate valid key pair and signature for successful tests
	pubKeyPEM, encodedSig, _ := generateKeyPairAndSignature(t, challenge)
	pub9d := generateValidECP256Key(t)

	tests := []struct {
		name      string
		nickname  string
		signature string
		pub9c     string
		pub9d     string
		setup     func(*mocks.MockchallengeManager, *mocks.MockUserSaver)
		wantErr   error
	}{
		{
			name:      "successful verification and user creation",
			nickname:  nickname,
			signature: encodedSig,
			pub9c:     pubKeyPEM,
			pub9d:     pub9d,
			setup: func(manager *mocks.MockchallengeManager, saver *mocks.MockUserSaver) {
				manager.EXPECT().Load(mock.Anything, nickname).Return(challenge, nil).Once()
				saver.EXPECT().Create(mock.Anything, nickname, pubKeyPEM, pub9d).Return(nil).Once()
				manager.EXPECT().Delete(mock.Anything, nickname).Return(nil).Once()
			},
			wantErr: nil,
		},
		{
			name:      "challenge load error",
			nickname:  nickname,
			signature: encodedSig,
			pub9c:     pubKeyPEM,
			pub9d:     pub9d,
			setup: func(manager *mocks.MockchallengeManager, saver *mocks.MockUserSaver) {
				loadErr := errors.New("load error")
				manager.EXPECT().Load(mock.Anything, nickname).Return("", loadErr).Once()
				manager.EXPECT().Delete(mock.Anything, nickname).Return(nil).Once()
			},
			wantErr: errors.New("load error"),
		},
		{
			name:      "challenge not found",
			nickname:  nickname,
			signature: encodedSig,
			pub9c:     pubKeyPEM,
			pub9d:     pub9d,
			setup: func(manager *mocks.MockchallengeManager, saver *mocks.MockUserSaver) {
				manager.EXPECT().Load(mock.Anything, nickname).Return("", domain.ErrChallengeNotFound).Once()
				manager.EXPECT().Delete(mock.Anything, nickname).Return(nil).Once()
			},
			wantErr: domain.ErrChallengeNotFound,
		},
		{
			name:      "invalid base64 encoded signature",
			nickname:  nickname,
			signature: "invalid-signature!!!",
			pub9c:     pubKeyPEM,
			pub9d:     pub9d,
			setup: func(manager *mocks.MockchallengeManager, saver *mocks.MockUserSaver) {
				manager.EXPECT().Load(mock.Anything, nickname).Return(challenge, nil).Once()
				manager.EXPECT().Delete(mock.Anything, nickname).Return(nil).Once()
			},
			wantErr: errors.New("illegal base64 data"),
		},
		{
			name:      "invalid signature verification",
			nickname:  nickname,
			signature: base64.RawURLEncoding.EncodeToString([]byte("invalid-signature-bytes")),
			pub9c:     pubKeyPEM,
			pub9d:     pub9d,
			setup: func(manager *mocks.MockchallengeManager, saver *mocks.MockUserSaver) {
				manager.EXPECT().Load(mock.Anything, nickname).Return(challenge, nil).Once()
				manager.EXPECT().Delete(mock.Anything, nickname).Return(nil).Once()
			},
			wantErr: domain.ErrInvalidSignature,
		},
		{
			name:      "wrong challenge signed",
			nickname:  nickname,
			signature: generateInvalidSignatureForKey(t, "different_challenge"),
			pub9c:     pubKeyPEM,
			pub9d:     pub9d,
			setup: func(manager *mocks.MockchallengeManager, saver *mocks.MockUserSaver) {
				manager.EXPECT().Load(mock.Anything, nickname).Return(challenge, nil).Once()
				manager.EXPECT().Delete(mock.Anything, nickname).Return(nil).Once()
			},
			wantErr: domain.ErrInvalidSignature,
		},
		{
			name:      "different key used for signature",
			nickname:  nickname,
			signature: encodedSig,
			pub9c:     generateValidECP256Key(t), // Different key
			pub9d:     pub9d,
			setup: func(manager *mocks.MockchallengeManager, saver *mocks.MockUserSaver) {
				manager.EXPECT().Load(mock.Anything, nickname).Return(challenge, nil).Once()
				manager.EXPECT().Delete(mock.Anything, nickname).Return(nil).Once()
			},
			wantErr: domain.ErrInvalidSignature,
		},
		{
			name:      "invalid public key format",
			nickname:  nickname,
			signature: encodedSig,
			pub9c:     "invalid-public-key",
			pub9d:     pub9d,
			setup: func(manager *mocks.MockchallengeManager, saver *mocks.MockUserSaver) {
				manager.EXPECT().Delete(mock.Anything, nickname).Return(nil).Once()
			},
			wantErr: domain.ErrInvalidPublicKey,
		},
		{
			name:      "empty public key 9c",
			nickname:  nickname,
			signature: encodedSig,
			pub9c:     "",
			pub9d:     pub9d,
			setup: func(manager *mocks.MockchallengeManager, saver *mocks.MockUserSaver) {
				manager.EXPECT().Delete(mock.Anything, nickname).Return(nil).Once()
			},
			wantErr: domain.ErrInvalidPublicKey,
		},
		{
			name:      "invalid public key 9d",
			nickname:  nickname,
			signature: encodedSig,
			pub9c:     pubKeyPEM,
			pub9d:     "invalid-key",
			setup: func(manager *mocks.MockchallengeManager, saver *mocks.MockUserSaver) {
				manager.EXPECT().Delete(mock.Anything, nickname).Return(nil).Once()
			},
			wantErr: domain.ErrInvalidPublicKey,
		},
		{
			name:      "empty public key 9d",
			nickname:  nickname,
			signature: encodedSig,
			pub9c:     pubKeyPEM,
			pub9d:     "",
			setup: func(manager *mocks.MockchallengeManager, saver *mocks.MockUserSaver) {
				manager.EXPECT().Delete(mock.Anything, nickname).Return(nil).Once()
			},
			wantErr: domain.ErrInvalidPublicKey,
		},
		{
			name:      "user creation error",
			nickname:  nickname,
			signature: encodedSig,
			pub9c:     pubKeyPEM,
			pub9d:     pub9d,
			setup: func(manager *mocks.MockchallengeManager, saver *mocks.MockUserSaver) {
				createErr := errors.New("database error")
				manager.EXPECT().Load(mock.Anything, nickname).Return(challenge, nil).Once()
				saver.EXPECT().Create(mock.Anything, nickname, pubKeyPEM, pub9d).Return(createErr).Once()
				manager.EXPECT().Delete(mock.Anything, nickname).Return(nil).Once()
			},
			wantErr: errors.New("database error"),
		},
		{
			name:      "challenge deletion error does not affect result",
			nickname:  nickname,
			signature: encodedSig,
			pub9c:     pubKeyPEM,
			pub9d:     pub9d,
			setup: func(manager *mocks.MockchallengeManager, saver *mocks.MockUserSaver) {
				deleteErr := errors.New("redis error")
				manager.EXPECT().Load(mock.Anything, nickname).Return(challenge, nil).Once()
				saver.EXPECT().Create(mock.Anything, nickname, pubKeyPEM, pub9d).Return(nil).Once()
				manager.EXPECT().Delete(mock.Anything, nickname).Return(deleteErr).Once()
			},
			wantErr: nil, // deletion error should not affect the result
		},
		{
			name:      "context cancellation during load",
			nickname:  nickname,
			signature: encodedSig,
			pub9c:     pubKeyPEM,
			pub9d:     pub9d,
			setup: func(manager *mocks.MockchallengeManager, saver *mocks.MockUserSaver) {
				manager.EXPECT().Load(mock.Anything, nickname).Return("", context.Canceled).Once()
				manager.EXPECT().Delete(mock.Anything, nickname).Return(nil).Once()
			},
			wantErr: context.Canceled,
		},
		{
			name:      "context cancellation during user creation",
			nickname:  nickname,
			signature: encodedSig,
			pub9c:     pubKeyPEM,
			pub9d:     pub9d,
			setup: func(manager *mocks.MockchallengeManager, saver *mocks.MockUserSaver) {
				manager.EXPECT().Load(mock.Anything, nickname).Return(challenge, nil).Once()
				saver.EXPECT().Create(mock.Anything, nickname, pubKeyPEM, pub9d).Return(context.Canceled).Once()
				manager.EXPECT().Delete(mock.Anything, nickname).Return(nil).Once()
			},
			wantErr: context.Canceled,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			service, _, mockManager, mockUserSaver := setupRegisterService(t)

			if tt.setup != nil {
				tt.setup(mockManager, mockUserSaver)
			}

			ctx := context.Background()
			if tt.name == "context cancellation during load" || tt.name == "context cancellation during user creation" {
				var cancel context.CancelFunc
				ctx, cancel = context.WithCancel(context.Background())
				cancel()
			}

			err := service.VerifyAndComplete(ctx, tt.nickname, tt.signature, tt.pub9c, tt.pub9d)

			if tt.wantErr != nil {
				assert.Error(t, err)
				if tt.wantErr.Error() != "illegal base64 data" {
					assert.Equal(t, tt.wantErr.Error(), err.Error())
				} else {
					// For base64 errors, just check that it's an error
					assert.Contains(t, err.Error(), "illegal")
				}
			} else {
				assert.NoError(t, err)
			}

			mockManager.AssertExpectations(t)
			mockUserSaver.AssertExpectations(t)
		})
	}
}
