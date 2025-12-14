package handlers

import (
	"context"

	"github.com/cocahonka/hecate/backend/chat_service/internal/domain"
	"github.com/google/uuid"
)

// ChatService defines the business logic contract for chat operations
type ChatService interface {
	CreateChat(ctx context.Context, creatorID, participantID uuid.UUID, creatorKey, participantKey string) (*domain.Chat, error)
	GetChatByID(ctx context.Context, chatID, userID uuid.UUID) (*domain.Chat, error)
	CheckUserIsMember(ctx context.Context, chatID, userID uuid.UUID) (bool, error)
	GetUserChats(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*domain.Chat, error)
	GetEncryptedKey(ctx context.Context, chatID, userID uuid.UUID) (string, error)
	GetChatMembers(ctx context.Context, chatID, userID uuid.UUID) ([]*domain.ChatMember, error)
}
