package handlers

import (
	"context"

	"github.com/cocahonka/hecate/backend/message_service/internal/domain"
	"github.com/google/uuid"
)

type MessageService interface {
	SendMessage(ctx context.Context, senderID, chatID uuid.UUID, payload, token string) (*domain.Message, error)
	GetHistory(ctx context.Context, userID, chatID uuid.UUID, limit, offset int, token string) ([]*domain.Message, error)
}
