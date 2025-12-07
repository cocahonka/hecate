package service

import (
	"context"
	"time"

	"github.com/cocahonka/hecate/backend/message_service/internal/domain"
	"github.com/cocahonka/hecate/backend/message_service/internal/repository"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

type Message struct {
	repo       repository.MessageRepository
	chatClient ChatClient
	logger     *zap.Logger
}

func NewMessageService(repo repository.MessageRepository, chatClient ChatClient, logger *zap.Logger) *Message {
	return &Message{
		repo:       repo,
		chatClient: chatClient,
		logger:     logger,
	}
}

func (s *Message) SendMessage(ctx context.Context, senderID, chatID uuid.UUID, payload, token string) (*domain.Message, error) {
	// 1. Check Membership
	isMember, err := s.chatClient.CheckMembership(ctx, chatID, token)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, domain.ErrUserNotMember
	}

	// 2. Create Message
	msg := &domain.Message{
		ID:               uuid.New(),
		ChatID:           chatID,
		SenderID:         senderID,
		EncryptedPayload: payload,
		CreatedAt:        time.Now().UTC(),
	}

	if err := s.repo.Create(ctx, msg); err != nil {
		s.logger.Error("failed to save message", zap.Error(err))
		return nil, err
	}

	return msg, nil
}

func (s *Message) GetHistory(ctx context.Context, userID, chatID uuid.UUID, limit, offset int, token string) ([]*domain.Message, error) {
	// 1. Check Membership
	isMember, err := s.chatClient.CheckMembership(ctx, chatID, token)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, domain.ErrUserNotMember
	}

	// 2. Get History
	return s.repo.GetByChatID(ctx, chatID, limit, offset)
}
