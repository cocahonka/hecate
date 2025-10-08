package service

import (
	"context"
	"encoding/base64"
	"time"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"go.uber.org/zap"
)

type nicknameChecker interface {
	// IsExists checks if a nickname already exists in the system.
	IsExists(ctx context.Context, nickname string) (bool, error)
}

type challengeManager interface {
	// Save stores the challenge for a given nickname with a specified TTL.
	Save(ctx context.Context, nickname, challenge string, ttl time.Duration) error
	// Load retrieves the challenge associated with the given nickname.
	Load(ctx context.Context, nickname string) (string, error)
	// Delete removes the challenge associated with the given nickname.
	Delete(ctx context.Context, nickname string) error
}

type UserSaver interface {
	// Create saves a new user with the provided nickname and public keys.
	Create(ctx context.Context, nickname, pub9c, pub9d string) error
}

// Register handles user registration, including nickname validation, challenge generation, and user creation.
type Register struct {
	logger           *zap.Logger
	checker          nicknameChecker
	challengeManager challengeManager
	userSaver        UserSaver
	challengeTTL     time.Duration
}

func NewRegisterService(logger *zap.Logger, checker nicknameChecker, manager challengeManager, userSaver UserSaver, challengeTTL time.Duration) *Register {
	return &Register{
		logger:           logger,
		checker:          checker,
		challengeManager: manager,
		userSaver:        userSaver,
		challengeTTL:     challengeTTL,
	}
}

// Init initiates the registration process by checking nickname uniqueness and generating a challenge.
func (r *Register) Init(ctx context.Context, nickname string) (string, error) {
	r.logger.Info("init register", zap.String("nickname", nickname))

	isExists, err := r.checker.IsExists(ctx, nickname)
	if err != nil {
		r.logger.Error("failed to check nickname", zap.String("nickname", nickname), zap.Error(err))
		return "", err
	}
	if isExists {
		r.logger.Info("nickname is not unique", zap.String("nickname", nickname))
		return "", domain.ErrNicknameIsNotUnique
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
	encSignedChallenge, err := base64.RawURLEncoding.DecodeString(signedChallengeBase64)
	if err != nil {
		return err
	}

	isValid, err := verifySignature([]byte(pub9c), []byte(challenge), encSignedChallenge)
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
