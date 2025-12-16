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

	t.Run("error checking existing chat", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		u1 := uuid.New()
		u2 := uuid.New()

		expectedErr := assert.AnError
		chatRepo.On("GetByParticipants", ctx, u1, u2).Return(nil, expectedErr)

		chat, err := svc.CreateChat(ctx, u1, u2, "k1", "k2")
		assert.ErrorIs(t, err, expectedErr)
		assert.Nil(t, chat)

		chatRepo.AssertExpectations(t)
	})

	t.Run("error creating chat with members", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		u1 := uuid.New()
		u2 := uuid.New()

		chatRepo.On("GetByParticipants", ctx, u1, u2).Return(nil, domain.ErrChatNotFound)

		expectedErr := assert.AnError
		chatRepo.On("CreateWithMembers", ctx, mock.AnythingOfType("*domain.Chat"), mock.Anything).Return(expectedErr)

		chat, err := svc.CreateChat(ctx, u1, u2, "k1", "k2")
		assert.ErrorIs(t, err, expectedErr)
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

	t.Run("error checking membership", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		chatID := uuid.New()
		userID := uuid.New()

		expectedErr := assert.AnError
		memberRepo.On("IsMember", ctx, chatID, userID).Return(false, expectedErr)

		chat, err := svc.GetChatByID(ctx, chatID, userID)
		assert.ErrorIs(t, err, expectedErr)
		assert.Nil(t, chat)
	})

	t.Run("chat not found", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		chatID := uuid.New()
		userID := uuid.New()

		memberRepo.On("IsMember", ctx, chatID, userID).Return(true, nil)
		chatRepo.On("GetByID", ctx, chatID).Return(nil, domain.ErrChatNotFound)

		chat, err := svc.GetChatByID(ctx, chatID, userID)
		assert.ErrorIs(t, err, domain.ErrChatNotFound)
		assert.Nil(t, chat)
	})

	t.Run("error getting chat", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		chatID := uuid.New()
		userID := uuid.New()

		expectedErr := assert.AnError
		memberRepo.On("IsMember", ctx, chatID, userID).Return(true, nil)
		chatRepo.On("GetByID", ctx, chatID).Return(nil, expectedErr)

		chat, err := svc.GetChatByID(ctx, chatID, userID)
		assert.ErrorIs(t, err, expectedErr)
		assert.Nil(t, chat)
	})
}

func TestChatService_CheckUserIsMember(t *testing.T) {
	logger := zap.NewNop()

	t.Run("user is member", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		chatID := uuid.New()
		userID := uuid.New()

		memberRepo.On("IsMember", ctx, chatID, userID).Return(true, nil)

		isMember, err := svc.CheckUserIsMember(ctx, chatID, userID)
		assert.NoError(t, err)
		assert.True(t, isMember)
		memberRepo.AssertExpectations(t)
	})

	t.Run("user is not member", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		chatID := uuid.New()
		userID := uuid.New()

		memberRepo.On("IsMember", ctx, chatID, userID).Return(false, nil)

		isMember, err := svc.CheckUserIsMember(ctx, chatID, userID)
		assert.NoError(t, err)
		assert.False(t, isMember)
		memberRepo.AssertExpectations(t)
	})

	t.Run("error checking membership", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		chatID := uuid.New()
		userID := uuid.New()

		expectedErr := assert.AnError
		memberRepo.On("IsMember", ctx, chatID, userID).Return(false, expectedErr)

		isMember, err := svc.CheckUserIsMember(ctx, chatID, userID)
		assert.ErrorIs(t, err, expectedErr)
		assert.False(t, isMember)
		memberRepo.AssertExpectations(t)
	})
}

func TestChatService_GetUserChats(t *testing.T) {
	logger := zap.NewNop()

	t.Run("success", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		userID := uuid.New()
		limit := 10
		offset := 0

		expectedChats := []*domain.Chat{
			{ID: uuid.New(), CreatedAt: time.Now()},
			{ID: uuid.New(), CreatedAt: time.Now()},
		}

		chatRepo.On("GetUserChats", ctx, userID, limit, offset).Return(expectedChats, nil)

		chats, err := svc.GetUserChats(ctx, userID, limit, offset)
		assert.NoError(t, err)
		assert.Equal(t, expectedChats, chats)
		chatRepo.AssertExpectations(t)
	})

	t.Run("empty list", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		userID := uuid.New()
		limit := 10
		offset := 0

		chatRepo.On("GetUserChats", ctx, userID, limit, offset).Return([]*domain.Chat{}, nil)

		chats, err := svc.GetUserChats(ctx, userID, limit, offset)
		assert.NoError(t, err)
		assert.Empty(t, chats)
		chatRepo.AssertExpectations(t)
	})

	t.Run("repository error", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		userID := uuid.New()
		limit := 10
		offset := 0

		expectedErr := assert.AnError
		chatRepo.On("GetUserChats", ctx, userID, limit, offset).Return(nil, expectedErr)

		chats, err := svc.GetUserChats(ctx, userID, limit, offset)
		assert.ErrorIs(t, err, expectedErr)
		assert.Nil(t, chats)
		chatRepo.AssertExpectations(t)
	})
}

func TestChatService_GetEncryptedKey(t *testing.T) {
	logger := zap.NewNop()

	t.Run("success", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		chatID := uuid.New()
		userID := uuid.New()
		expectedKey := "encrypted_aes_key_base64"

		memberRepo.On("GetEncryptedKey", ctx, chatID, userID).Return(expectedKey, nil)

		key, err := svc.GetEncryptedKey(ctx, chatID, userID)
		assert.NoError(t, err)
		assert.Equal(t, expectedKey, key)
		memberRepo.AssertExpectations(t)
	})

	t.Run("user not member", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		chatID := uuid.New()
		userID := uuid.New()

		memberRepo.On("GetEncryptedKey", ctx, chatID, userID).Return("", domain.ErrUserNotMember)

		key, err := svc.GetEncryptedKey(ctx, chatID, userID)
		assert.ErrorIs(t, err, domain.ErrUserNotMember)
		assert.Empty(t, key)
		memberRepo.AssertExpectations(t)
	})

	t.Run("repository error", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		chatID := uuid.New()
		userID := uuid.New()

		expectedErr := assert.AnError
		memberRepo.On("GetEncryptedKey", ctx, chatID, userID).Return("", expectedErr)

		key, err := svc.GetEncryptedKey(ctx, chatID, userID)
		assert.ErrorIs(t, err, expectedErr)
		assert.Empty(t, key)
		memberRepo.AssertExpectations(t)
	})
}

func TestChatService_GetChatMembers(t *testing.T) {
	logger := zap.NewNop()

	t.Run("success", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		chatID := uuid.New()
		userID := uuid.New()

		expectedMembers := []*domain.ChatMember{
			{ChatID: chatID, UserID: uuid.New(), EncryptedKey: "key1", JoinedAt: time.Now()},
			{ChatID: chatID, UserID: uuid.New(), EncryptedKey: "key2", JoinedAt: time.Now()},
		}

		memberRepo.On("IsMember", ctx, chatID, userID).Return(true, nil)
		memberRepo.On("GetChatMembers", ctx, chatID).Return(expectedMembers, nil)

		members, err := svc.GetChatMembers(ctx, chatID, userID)
		assert.NoError(t, err)
		assert.Equal(t, expectedMembers, members)
		memberRepo.AssertExpectations(t)
	})

	t.Run("user not member", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		chatID := uuid.New()
		userID := uuid.New()

		memberRepo.On("IsMember", ctx, chatID, userID).Return(false, nil)

		members, err := svc.GetChatMembers(ctx, chatID, userID)
		assert.ErrorIs(t, err, domain.ErrUserNotMember)
		assert.Nil(t, members)
		memberRepo.AssertExpectations(t)
	})

	t.Run("error checking membership", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		chatID := uuid.New()
		userID := uuid.New()

		expectedErr := assert.AnError
		memberRepo.On("IsMember", ctx, chatID, userID).Return(false, expectedErr)

		members, err := svc.GetChatMembers(ctx, chatID, userID)
		assert.ErrorIs(t, err, expectedErr)
		assert.Nil(t, members)
		memberRepo.AssertExpectations(t)
	})

	t.Run("error getting members", func(t *testing.T) {
		chatRepo := new(mocks.ChatRepository)
		memberRepo := new(mocks.ChatMemberRepository)
		svc := NewChatService(chatRepo, memberRepo, logger)

		ctx := context.Background()
		chatID := uuid.New()
		userID := uuid.New()

		expectedErr := assert.AnError
		memberRepo.On("IsMember", ctx, chatID, userID).Return(true, nil)
		memberRepo.On("GetChatMembers", ctx, chatID).Return(nil, expectedErr)

		members, err := svc.GetChatMembers(ctx, chatID, userID)
		assert.ErrorIs(t, err, expectedErr)
		assert.Nil(t, members)
		memberRepo.AssertExpectations(t)
	})
}
