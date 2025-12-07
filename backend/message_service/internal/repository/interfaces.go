package repository

import (
	"context"

	"github.com/cocahonka/hecate/backend/message_service/internal/domain"
	"github.com/google/uuid"
)

type MessageRepository interface {
	Create(ctx context.Context, message *domain.Message) error
	GetByChatID(ctx context.Context, chatID uuid.UUID, limit, offset int) ([]*domain.Message, error)
}
