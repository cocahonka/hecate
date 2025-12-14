package service

import (
	"context"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	handler "github.com/cocahonka/hecate/backend/user_service/internal/handlers"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

var _ handler.UserManager = (*UserService)(nil)

type UserService struct {
	logger       *zap.Logger
	userProvider UserProvider
}

func NewUserService(logger *zap.Logger, userProvider UserProvider) *UserService {
	return &UserService{
		logger:       logger,
		userProvider: userProvider,
	}
}

func (s *UserService) Get(ctx context.Context, nickname string) (*domain.User, error) {
	return s.userProvider.Get(ctx, nickname)
}

func (s *UserService) GetByID(ctx context.Context, userID uuid.UUID) (*domain.User, error) {
	return s.userProvider.GetByID(ctx, userID)
}
