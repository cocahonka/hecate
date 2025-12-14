package service

import (
	"context"
	"errors"
	"time"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	handler "github.com/cocahonka/hecate/backend/user_service/internal/handlers"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

var _ handler.LoginManager = (*LoginService)(nil)

// LoginService handles the logic for user login.
type LoginService struct {
	logger              *zap.Logger
	challengeManager    challengeManager
	userProvider        UserProvider
	tokenGenerator      TokenGenerator
	tokenValidator      TokenValidator
	refreshTokenManager RefreshTokenManager
	challengeTTL        time.Duration
	refreshTokenTTL     time.Duration
}

// NewLoginService creates a new instance of LoginService.
func NewLoginService(
	logger *zap.Logger,
	challengeManager challengeManager,
	userProvider UserProvider,
	tokenGenerator TokenGenerator,
	tokenValidator TokenValidator,
	refreshTokenManager RefreshTokenManager,
	challengeTTL time.Duration,
	refreshTokenTTL time.Duration,
) *LoginService {
	return &LoginService{
		logger:              logger,
		challengeManager:    challengeManager,
		userProvider:        userProvider,
		tokenGenerator:      tokenGenerator,
		tokenValidator:      tokenValidator,
		refreshTokenManager: refreshTokenManager,
		challengeTTL:        challengeTTL,
		refreshTokenTTL:     refreshTokenTTL,
	}
}

// Init generates and stores a challenge for a user who wants to log in.
func (s *LoginService) Init(ctx context.Context, nickname string) (string, error) {
	log := s.logger.With(zap.String("nickname", nickname))

	_, err := s.userProvider.Get(ctx, nickname)
	if err != nil {
		if errors.Is(err, domain.ErrUserNotFound) {
			log.Warn("login attempt for non-existent user")
			return "", domain.ErrUserNotFound
		}

		log.Error("failed to get user during login init", zap.Error(err))
		return "", err
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

	isValid, err := verifySignature([]byte(user.Pub9c), challenge, signature)
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

	if err := s.refreshTokenManager.SaveRefreshToken(ctx, user.ID.String(), refreshToken, s.refreshTokenTTL); err != nil {
		log.Error("failed to save refresh token", zap.Error(err))
		return "", "", err
	}

	log.Info("user successfully verified")
	return accessToken, refreshToken, nil
}

// Refresh validates a refresh token and generates new access and refresh tokens.
func (s *LoginService) Refresh(ctx context.Context, refreshToken string, nickname *string) (string, string, error) {
	log := s.logger

	userID, err := s.tokenValidator.ValidateRefreshToken(refreshToken)
	if err != nil {
		log.Warn("invalid refresh token", zap.Error(err))
		return "", "", domain.ErrInvalidRefreshToken
	}

	var user *domain.User
	if userID == "" {
		if nickname == nil || *nickname == "" {
			log.Warn("user ID not found in token and nickname not provided")
			return "", "", domain.ErrInvalidRefreshToken
		}
		user, err = s.userProvider.Get(ctx, *nickname)
		if err != nil {
			log.Error("failed to get user by nickname", zap.Error(err))
			return "", "", err
		}
		userID = user.ID.String()
	} else {
		uid, err := uuid.Parse(userID)
		if err != nil {
			log.Error("failed to parse user ID", zap.Error(err))
			return "", "", err
		}
		user, err = s.userProvider.GetByID(ctx, uid)
		if err != nil {
			log.Error("failed to get user by ID", zap.Error(err))
			return "", "", err
		}
	}

	log = log.With(zap.String("userID", userID))

	storedToken, err := s.refreshTokenManager.GetRefreshToken(ctx, userID)
	if err != nil {
		log.Error("failed to get stored refresh token", zap.Error(err))
		return "", "", domain.ErrInvalidRefreshToken
	}

	if storedToken != refreshToken {
		log.Warn("refresh token mismatch")
		return "", "", domain.ErrRefreshTokenMismatch
	}

	newAccessToken, newRefreshToken, err := s.tokenGenerator.Generate(*user)
	if err != nil {
		log.Error("failed to generate new tokens", zap.Error(err))
		return "", "", err
	}

	if err := s.refreshTokenManager.SaveRefreshToken(ctx, userID, newRefreshToken, s.refreshTokenTTL); err != nil {
		log.Error("failed to save new refresh token", zap.Error(err))
		return "", "", err
	}

	log.Info("tokens successfully refreshed")
	return newAccessToken, newRefreshToken, nil
}
