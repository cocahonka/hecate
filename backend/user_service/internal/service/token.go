package service

import (
	"time"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/golang-jwt/jwt/v5"
)

// TokenService is responsible for generating JWT access and refresh tokens.
type TokenService struct {
	secret          string
	accessTokenTTL  time.Duration
	refreshTokenTTL time.Duration
}

// NewTokenService creates a new instance of TokenService.
func NewTokenService(secret string, accessTokenTTL, refreshTokenTTL time.Duration) *TokenService {
	return &TokenService{
		secret:          secret,
		accessTokenTTL:  accessTokenTTL,
		refreshTokenTTL: refreshTokenTTL,
	}
}

// Generate creates a new pair of access and refresh tokens for the given user.
func (s *TokenService) Generate(user domain.User) (string, string, error) {
	// Create access token
	accesClaims := jwt.MapClaims{
		"sub": user.ID,
		"exp": time.Now().Add(s.accessTokenTTL).Unix(),
		"iat": time.Now().Unix(),
	}
	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accesClaims)
	accessTokenString, err := accessToken.SignedString([]byte(s.secret))
	if err != nil {
		return "", "", err
	}

	// Create refresh token
	refreshClaims := jwt.MapClaims{
		"sub": user.ID,
		"exp": time.Now().Add(s.refreshTokenTTL).Unix(),
		"iat": time.Now().Unix(),
	}
	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	refreshTokenString, err := refreshToken.SignedString([]byte(s.secret))
	if err != nil {
		return "", "", err
	}

	return accessTokenString, refreshTokenString, nil
}
