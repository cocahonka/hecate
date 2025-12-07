package service

import (
	"context"
	"testing"
	"time"

	"github.com/cocahonka/hecate/backend/chat_service/internal/domain"
	"github.com/cocahonka/hecate/backend/chat_service/internal/repository/mocks"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.uber.org/zap"
)

func TestChatService_CreateChat(t *testing.T) {
	logger := zap.NewNop()

	t.Run("success", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		u1 := uuid.New()
		u2 := uuid.New()
		k1 := "key1"
		k2 := "key2"

		// Expect check for existing chat -> returns NotFound (which means we can proceed)
		chatRepo.On("GetByParticipants", ctx, u1, u2).Return(nil, domain.ErrChatNotFound)

		// Expect CreateWithMembers
		chatRepo.On("CreateWithMembers", ctx, mock.AnythingOfType("*domain.Chat"), mock.MatchedBy(func(members []*domain.ChatMember) bool {
			return len(members) == 2 && members[0].UserID == u1 && members[1].UserID == u2
		})).Return(nil)

		chat, err := svc.CreateChat(ctx, u1, u2, k1, k2)
		assert.NoError(t, err)
		assert.NotNil(t, chat)
		assert.NotEqual(t, uuid.Nil, chat.ID)

		chatRepo.AssertExpectations(t)
	})

	t.Run("already exists", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		u1 := uuid.New()
		u2 := uuid.New()
		existingChat := &domain.Chat{ID: uuid.New()}

		// Expect check -> returns existing chat
		chatRepo.On("GetByParticipants", ctx, u1, u2).Return(existingChat, nil)

		chat, err := svc.CreateChat(ctx, u1, u2, "k1", "k2")
		assert.ErrorIs(t, err, domain.ErrChatAlreadyExists)
		assert.Nil(t, chat)

		chatRepo.AssertExpectations(t)
	})
}

func TestChatService_GetChatByID(t *testing.T) {
	logger := zap.NewNop()

	t.Run("success", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		chatID := uuid.New()
		userID := uuid.New()

		// Expect IsMember check -> true
		memberRepo.On("IsMember", ctx, chatID, userID).Return(true, nil)

		// Expect GetByID -> chat
		expectedChat := &domain.Chat{ID: chatID, CreatedAt: time.Now()}
		chatRepo.On("GetByID", ctx, chatID).Return(expectedChat, nil)

		chat, err := svc.GetChatByID(ctx, chatID, userID)
		assert.NoError(t, err)
		assert.Equal(t, expectedChat, chat)
	})

	t.Run("not member", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		chatID := uuid.New()
		userID := uuid.New()

		// Expect IsMember check -> false
		memberRepo.On("IsMember", ctx, chatID, userID).Return(false, nil)

		chat, err := svc.GetChatByID(ctx, chatID, userID)
		assert.ErrorIs(t, err, domain.ErrUserNotMember)
		assert.Nil(t, chat)
	})
}
