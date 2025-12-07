package repository

import (
	"context"

	"github.com/cocahonka/hecate/backend/chat_service/internal/domain"
	"github.com/google/uuid"
)

// ChatRepository defines methods for interacting with chat data
type ChatRepository interface {
	Create(ctx context.Context, chat *domain.Chat) error
	CreateWithMembers(ctx context.Context, chat *domain.Chat, members []*domain.ChatMember) error
	GetByID(ctx context.Context, chatID uuid.UUID) (*domain.Chat, error)
	GetByParticipants(ctx context.Context, user1ID, user2ID uuid.UUID) (*domain.Chat, error)
	GetUserChats(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*domain.Chat, error)
}

// ChatMemberRepository defines methods for interacting with chat participants
type ChatMemberRepository interface {
	Create(ctx context.Context, member *domain.ChatMember) error
	IsMember(ctx context.Context, chatID, userID uuid.UUID) (bool, error)
	GetEncryptedKey(ctx context.Context, chatID, userID uuid.UUID) (string, error)
	GetChatMembers(ctx context.Context, chatID uuid.UUID) ([]*domain.ChatMember, error)
}