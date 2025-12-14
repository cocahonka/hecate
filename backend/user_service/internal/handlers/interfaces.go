package handler

import (
	"context"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/google/uuid"
)

//go:generate mockery

// RegisterManager defines the interface for user registration operations.
type RegisterManager interface {
	Init(ctx context.Context, nickname string) (string, error)
	VerifyAndComplete(ctx context.Context, nickname, signedChallengeBase64, pub9c, pub9d string) error
}

// LoginManager defines the interface for user login operations.
type LoginManager interface {
	Init(ctx context.Context, nickname string) (string, error)
	Verify(ctx context.Context, nickname, signature string) (accessToken, refreshToken string, err error)
	Refresh(ctx context.Context, refreshToken string, nickname *string) (accessToken, newRefreshToken string, err error)
}

// UserManager defines the interface for user data operations.
type UserManager interface {
	Get(ctx context.Context, nickname string) (*domain.User, error)
	GetByID(ctx context.Context, userID uuid.UUID) (*domain.User, error)
}