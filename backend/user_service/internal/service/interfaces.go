package service

import (
	"context"
	"time"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
)

//go:generate mockery

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

// UserProvider defines the interface for retrieving user data.
type UserProvider interface {
	Get(ctx context.Context, nickname string) (*domain.User, error)
}

// TokenGenerator defines the interface for generating access and refresh tokens.
type TokenGenerator interface {
	Generate(user domain.User) (accessToken, refreshToken string, err error)
}
