package service

import (
	"context"
	"errors"
	"time"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"go.uber.org/zap"
)

// Register handles user registration, including nickname validation, challenge generation, and user creation.
type Register struct {
	logger           *zap.Logger
	userProvider     UserProvider
	challengeManager challengeManager
	userSaver        UserSaver
	challengeTTL     time.Duration
}

func NewRegisterService(logger *zap.Logger, userProvider UserProvider, manager challengeManager, userSaver UserSaver, challengeTTL time.Duration) *Register {
	return &Register{
		logger:           logger,
		userProvider:     userProvider,
		challengeManager: manager,
		userSaver:        userSaver,
		challengeTTL:     challengeTTL,
	}
}

// Init initiates the registration process by checking nickname uniqueness and generating a challenge.
func (r *Register) Init(ctx context.Context, nickname string) (string, error) {
	r.logger.Info("init register", zap.String("nickname", nickname))

	_, err := r.userProvider.Get(ctx, nickname)
	if err == nil {
		r.logger.Info("nickname is not unique", zap.String("nickname", nickname))
		return "", domain.ErrNicknameIsNotUnique
	}
	if !errors.Is(err, domain.ErrUserNotFound) {
		r.logger.Error("failed to check nickname", zap.String("nickname", nickname), zap.Error(err))
		return "", err
	}

	challenge := generateChallenge()

	if err := r.challengeManager.Save(ctx, nickname, challenge, r.challengeTTL); err != nil {
		r.logger.Error("failed to save challenge", zap.String("nickname", nickname), zap.Error(err))
		return "", err
	}

	r.logger.Info("challenge saved", zap.String("nickname", nickname))
	return challenge, nil
}

// VerifyAndComplete verifies the signed challenge and completes the registration by saving the user.
func (r *Register) VerifyAndComplete(ctx context.Context, nickname, signedChallengeBase64, pub9c, pub9d string) error {
	defer func() {
		err := r.challengeManager.Delete(ctx, nickname)
		if err != nil {
			r.logger.Error("failed to remove challenge from cache", zap.String("nickname", nickname))
		}
	}()

	// Validate 9c and 9d keys
	if err := validate9cAnd9dKeys(pub9c, pub9d); err != nil {
		r.logger.Error("invalid keys provided", zap.String("nickname", nickname), zap.Error(err))
		return err
	}

	challenge, err := r.challengeManager.Load(ctx, nickname)
	if err != nil {
		r.logger.Error("failed to load challenge from cache")
		return err
	}

	isValid, err := verifySignature([]byte(pub9c), challenge, signedChallengeBase64)
	if err != nil {
		return err
	}
	if !isValid {
		return domain.ErrInvalidSignature
	}
	err = r.userSaver.Create(ctx, nickname, pub9c, pub9d)
	if err != nil {
		return err
	}
	return nil
}
