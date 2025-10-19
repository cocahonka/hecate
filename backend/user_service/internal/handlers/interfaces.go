package handler

import "context"

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
}
