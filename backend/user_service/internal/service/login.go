package service

import (
	"context"
	"encoding/base64"
	"time"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	handler "github.com/cocahonka/hecate/backend/user_service/internal/handlers"
	"go.uber.org/zap"
)

var _ handler.LoginManager = (*LoginService)(nil)

// LoginService handles the logic for user login.
type LoginService struct {
	logger           *zap.Logger
	challengeManager challengeManager
	userProvider     UserProvider
	tokenGenerator   TokenGenerator
	challengeTTL     time.Duration
}

// NewLoginService creates a new instance of LoginService.
func NewLoginService(
	logger *zap.Logger,
	challengeManager challengeManager,
	userProvider UserProvider,
	tokenGenerator TokenGenerator,
	challengeTTL time.Duration,
) *LoginService {
	return &LoginService{
		logger:           logger,
		challengeManager: challengeManager,
		userProvider:     userProvider,
		tokenGenerator:   tokenGenerator,
		challengeTTL:     challengeTTL,
	}
}

// Init generates and stores a challenge for a user who wants to log in.
func (s *LoginService) Init(ctx context.Context, nickname string) (string, error) {
	log := s.logger.With(zap.String("nickname", nickname))

	_, err := s.userProvider.Get(ctx, nickname)
	if err != nil {
		log.Warn("login attempt for non-existent user")
		return "", domain.ErrUserNotFound
	}

	challenge := generateChallenge()

	if err := s.challengeManager.Save(ctx, nickname, challenge, s.challengeTTL); err != nil {
		log.Error("failed to save challenge", zap.Error(err))
		return "", err
	}

	log.Info("login challenge saved")
	return challenge, nil
}

// Verify checks the signed challenge, and if valid, returns access and refresh tokens.
func (s *LoginService) Verify(ctx context.Context, nickname, signature string) (string, string, error) {
	log := s.logger.With(zap.String("nickname", nickname))

	challenge, err := s.challengeManager.Load(ctx, nickname)
	if err != nil {
		log.Error("failed to load challenge from cache", zap.Error(err))
		return "", "", err // Consider returning a domain-specific error
	}

	user, err := s.userProvider.Get(ctx, nickname)
	if err != nil {
		log.Error("failed to get user", zap.Error(err))
		return "", "", err // Consider returning domain.ErrUserNotFound
	}

	decodedSignature, err := base64.RawURLEncoding.DecodeString(signature)
	if err != nil {
		log.Error("failed to decode signature", zap.Error(err))
		return "", "", err // Consider returning a domain-specific error for bad request
	}

	isValid, err := verifySignature([]byte(user.Pub9c), []byte(challenge), decodedSignature)
	if err != nil {
		log.Error("error during signature verification", zap.Error(err))
		return "", "", err
	}

	if !isValid {
		log.Warn("invalid signature provided")
		return "", "", domain.ErrInvalidSignature
	}

	// Signature is valid, clean up the challenge
	defer func() {
		if err := s.challengeManager.Delete(ctx, nickname); err != nil {
			log.Error("failed to delete challenge after successful login", zap.Error(err))
		}
	}()

	accessToken, refreshToken, err := s.tokenGenerator.Generate(*user)
	if err != nil {
		log.Error("failed to generate tokens", zap.Error(err))
		return "", "", err
	}

	log.Info("user successfully verified")
	return accessToken, refreshToken, nil
}