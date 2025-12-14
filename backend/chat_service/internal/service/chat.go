package service

import (
	"context"
	"time"

	"github.com/cocahonka/hecate/backend/chat_service/internal/domain"
	"github.com/cocahonka/hecate/backend/chat_service/internal/repository"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

type ChatService struct {
	chatRepo   repository.ChatRepository
	memberRepo repository.ChatMemberRepository
	logger     *zap.Logger
}

func NewChatService(chatRepo repository.ChatRepository, memberRepo repository.ChatMemberRepository, logger *zap.Logger) *ChatService {
	return &ChatService{
		chatRepo:   chatRepo,
		memberRepo: memberRepo,
		logger:     logger,
	}
}

func (s *ChatService) CreateChat(ctx context.Context, creatorID, participantID uuid.UUID, creatorKey, participantKey string) (*domain.Chat, error) {
	// 1. Check if chat already exists
	existing, err := s.chatRepo.GetByParticipants(ctx, creatorID, participantID)
	if err == nil && existing != nil {
		return nil, domain.ErrChatAlreadyExists
	}
	if err != nil && err != domain.ErrChatNotFound {
		s.logger.Error("failed to check existing chat", zap.Error(err))
		return nil, err
	}

	// 2. Create Chat object
	now := time.Now().UTC()
	chat := &domain.Chat{
		ID:        uuid.New(),
		CreatedAt: now,
		UpdatedAt: now,
	}

	// 3. Create Members
	members := []*domain.ChatMember{
		{
			ChatID:       chat.ID,
			UserID:       creatorID,
			EncryptedKey: creatorKey,
			JoinedAt:     now,
		},
		{
			ChatID:       chat.ID,
			UserID:       participantID,
			EncryptedKey: participantKey,
			JoinedAt:     now,
		},
	}

	// 4. Save to DB (Transactional)
	if err := s.chatRepo.CreateWithMembers(ctx, chat, members); err != nil {
		s.logger.Error("failed to create chat with members", zap.Error(err))
		return nil, err
	}

	return chat, nil
}

func (s *ChatService) GetChatByID(ctx context.Context, chatID, userID uuid.UUID) (*domain.Chat, error) {
	// 1. Check membership
	isMember, err := s.memberRepo.IsMember(ctx, chatID, userID)
	if err != nil {
		s.logger.Error("failed to check membership", zap.Error(err))
		return nil, err
	}
	if !isMember {
		return nil, domain.ErrUserNotMember
	}

	// 2. Get Chat
	chat, err := s.chatRepo.GetByID(ctx, chatID)
	if err != nil {
		if err != domain.ErrChatNotFound {
			s.logger.Error("failed to get chat", zap.Error(err))
		}
		return nil, err
	}

	return chat, nil
}

func (s *ChatService) CheckUserIsMember(ctx context.Context, chatID, userID uuid.UUID) (bool, error) {
	return s.memberRepo.IsMember(ctx, chatID, userID)
}

func (s *ChatService) GetUserChats(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*domain.Chat, error) {
	return s.chatRepo.GetUserChats(ctx, userID, limit, offset)
}

func (s *ChatService) GetEncryptedKey(ctx context.Context, chatID, userID uuid.UUID) (string, error) {
	// Note: We might want to check if the requester is a member of the chat as well?
	// The plan says "GetEncryptedKey... Получение зашифрованного AES ключа для *конкретного* пользователя".
	// Usually, this is "Get MY key" or "Get OTHER user's key"?
	// TASK-22 says: "Получение зашифрованного AES ключа для *текущего* пользователя".
	// So userID here is the CurrentUser.
	// But TASK-15 just says "Check access rights".

	// Implementation: Just call repo, which checks if row exists (key exists).
	// If the user is not in the chat, IsMember logic in repo implicitly handles "no row found".
	// But we need to distinguish "not member" vs "error".

	key, err := s.memberRepo.GetEncryptedKey(ctx, chatID, userID)
	if err != nil {
		return "", err
	}
	return key, nil
}

func (s *ChatService) GetChatMembers(ctx context.Context, chatID, userID uuid.UUID) ([]*domain.ChatMember, error) {
	// 1. Check membership
	isMember, err := s.memberRepo.IsMember(ctx, chatID, userID)
	if err != nil {
		s.logger.Error("failed to check membership", zap.Error(err))
		return nil, err
	}
	if !isMember {
		return nil, domain.ErrUserNotMember
	}

	// 2. Get members
	members, err := s.memberRepo.GetChatMembers(ctx, chatID)
	if err != nil {
		s.logger.Error("failed to get chat members", zap.Error(err))
		return nil, err
	}

	return members, nil
}
