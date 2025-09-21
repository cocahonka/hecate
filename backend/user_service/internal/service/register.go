package service

import (
	"context"
	"time"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/twinj/uuid"
	"go.uber.org/zap"
)

type nicknameChecker interface {
	IsExists(ctx context.Context, nickname string) (bool, error)
}

type challengeSaver interface {
	Save(ctx context.Context, nickname, challenge string, ttl time.Duration) error
}

type Register struct {
	logger       *zap.Logger
	checker      nicknameChecker
	saver        challengeSaver
	challengeTTL time.Duration
}

func NewRegisterService(logger *zap.Logger, checker nicknameChecker, saver challengeSaver, challengeTTL time.Duration) *Register {
	return &Register{
		logger:       logger,
		checker:      checker,
		saver:        saver,
		challengeTTL: challengeTTL,
	}
}

func (u *Register) Init(ctx context.Context, nickname string) (string, error) {
	u.logger.Info("init register", zap.String("nickname", nickname))

	isExists, err := u.checker.IsExists(ctx, nickname)
	if err != nil {
		u.logger.Error("failed to check nickname", zap.String("nickname", nickname), zap.Error(err))
		return "", err
	}
	if isExists {
		u.logger.Info("nickname is not unique", zap.String("nickname", nickname))
		return "", domain.ErrNicknameIsNotUnique
	}

	challenge := generateChallenge()

	if err := u.saver.Save(ctx, nickname, challenge, u.challengeTTL); err != nil {
		u.logger.Error("failed to save challenge", zap.String("nickname", nickname), zap.Error(err))
		return "", err
	}

	u.logger.Info("challenge saved", zap.String("nickname", nickname))
	return challenge, nil
}

func generateChallenge() string {
	return uuid.NewV4().String()
}
