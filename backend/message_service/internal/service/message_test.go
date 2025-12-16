package service

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/cocahonka/hecate/backend/message_service/internal/domain"
	repoMocks "github.com/cocahonka/hecate/backend/message_service/internal/repository/mocks"
	serviceMocks "github.com/cocahonka/hecate/backend/message_service/internal/service/mocks"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.uber.org/zap"
)

func TestMessageService_SendMessage(t *testing.T) {
	logger := zap.NewNop()

	t.Run("success", func(t *testing.T) {
		repo := new(repoMocks.MockMessageRepository)
		chatClient := new(serviceMocks.MockChatClient)
		svc := NewMessageService(repo, chatClient, logger)

		ctx := context.Background()
		senderID := uuid.New()
		chatID := uuid.New()
		payload := "encrypted_payload_base64"
		token := "jwt_token"

		// Expect CheckMembership -> true
		chatClient.On("CheckMembership", ctx, chatID, token).Return(true, nil)

		// Expect Create
		repo.On("Create", ctx, mock.MatchedBy(func(msg *domain.Message) bool {
			return msg.ChatID == chatID && msg.SenderID == senderID && msg.EncryptedPayload == payload
		})).Return(nil)

		msg, err := svc.SendMessage(ctx, senderID, chatID, payload, token)
		assert.NoError(t, err)
		assert.NotNil(t, msg)
		assert.Equal(t, chatID, msg.ChatID)
		assert.Equal(t, senderID, msg.SenderID)
		assert.Equal(t, payload, msg.EncryptedPayload)
		assert.NotEqual(t, uuid.Nil, msg.ID)

		chatClient.AssertExpectations(t)
		repo.AssertExpectations(t)
	})

	t.Run("user not member", func(t *testing.T) {
		repo := new(repoMocks.MockMessageRepository)
		chatClient := new(serviceMocks.MockChatClient)
		svc := NewMessageService(repo, chatClient, logger)

		ctx := context.Background()
		senderID := uuid.New()
		chatID := uuid.New()
		payload := "encrypted_payload_base64"
		token := "jwt_token"

		// Expect CheckMembership -> false
		chatClient.On("CheckMembership", ctx, chatID, token).Return(false, nil)

		msg, err := svc.SendMessage(ctx, senderID, chatID, payload, token)
		assert.ErrorIs(t, err, domain.ErrUserNotMember)
		assert.Nil(t, msg)

		chatClient.AssertExpectations(t)
		repo.AssertNotCalled(t, "Create")
	})

	t.Run("error checking membership", func(t *testing.T) {
		repo := new(repoMocks.MockMessageRepository)
		chatClient := new(serviceMocks.MockChatClient)
		svc := NewMessageService(repo, chatClient, logger)

		ctx := context.Background()
		senderID := uuid.New()
		chatID := uuid.New()
		payload := "encrypted_payload_base64"
		token := "jwt_token"

		expectedErr := errors.New("chat service error")
		chatClient.On("CheckMembership", ctx, chatID, token).Return(false, expectedErr)

		msg, err := svc.SendMessage(ctx, senderID, chatID, payload, token)
		assert.ErrorIs(t, err, expectedErr)
		assert.Nil(t, msg)

		chatClient.AssertExpectations(t)
		repo.AssertNotCalled(t, "Create")
	})

	t.Run("error creating message", func(t *testing.T) {
		repo := new(repoMocks.MockMessageRepository)
		chatClient := new(serviceMocks.MockChatClient)
		svc := NewMessageService(repo, chatClient, logger)

		ctx := context.Background()
		senderID := uuid.New()
		chatID := uuid.New()
		payload := "encrypted_payload_base64"
		token := "jwt_token"

		chatClient.On("CheckMembership", ctx, chatID, token).Return(true, nil)

		expectedErr := errors.New("database error")
		repo.On("Create", ctx, mock.AnythingOfType("*domain.Message")).Return(expectedErr)

		msg, err := svc.SendMessage(ctx, senderID, chatID, payload, token)
		assert.ErrorIs(t, err, expectedErr)
		assert.Nil(t, msg)

		chatClient.AssertExpectations(t)
		repo.AssertExpectations(t)
	})
}

func TestMessageService_GetHistory(t *testing.T) {
	logger := zap.NewNop()

	t.Run("success", func(t *testing.T) {
		repo := new(repoMocks.MockMessageRepository)
		chatClient := new(serviceMocks.MockChatClient)
		svc := NewMessageService(repo, chatClient, logger)

		ctx := context.Background()
		userID := uuid.New()
		chatID := uuid.New()
		token := "jwt_token"
		limit := 50
		offset := 0

		expectedMessages := []*domain.Message{
			{
				ID:               uuid.New(),
				ChatID:           chatID,
				SenderID:         uuid.New(),
				EncryptedPayload: "payload1",
				CreatedAt:        time.Now(),
			},
			{
				ID:               uuid.New(),
				ChatID:           chatID,
				SenderID:         uuid.New(),
				EncryptedPayload: "payload2",
				CreatedAt:        time.Now(),
			},
		}

		chatClient.On("CheckMembership", ctx, chatID, token).Return(true, nil)
		repo.On("GetByChatID", ctx, chatID, limit, offset).Return(expectedMessages, nil)

		messages, err := svc.GetHistory(ctx, userID, chatID, limit, offset, token)
		assert.NoError(t, err)
		assert.Equal(t, expectedMessages, messages)

		chatClient.AssertExpectations(t)
		repo.AssertExpectations(t)
	})

	t.Run("empty history", func(t *testing.T) {
		repo := new(repoMocks.MockMessageRepository)
		chatClient := new(serviceMocks.MockChatClient)
		svc := NewMessageService(repo, chatClient, logger)

		ctx := context.Background()
		userID := uuid.New()
		chatID := uuid.New()
		token := "jwt_token"
		limit := 50
		offset := 0

		chatClient.On("CheckMembership", ctx, chatID, token).Return(true, nil)
		repo.On("GetByChatID", ctx, chatID, limit, offset).Return([]*domain.Message{}, nil)

		messages, err := svc.GetHistory(ctx, userID, chatID, limit, offset, token)
		assert.NoError(t, err)
		assert.Empty(t, messages)

		chatClient.AssertExpectations(t)
		repo.AssertExpectations(t)
	})

	t.Run("user not member", func(t *testing.T) {
		repo := new(repoMocks.MockMessageRepository)
		chatClient := new(serviceMocks.MockChatClient)
		svc := NewMessageService(repo, chatClient, logger)

		ctx := context.Background()
		userID := uuid.New()
		chatID := uuid.New()
		token := "jwt_token"
		limit := 50
		offset := 0

		chatClient.On("CheckMembership", ctx, chatID, token).Return(false, nil)

		messages, err := svc.GetHistory(ctx, userID, chatID, limit, offset, token)
		assert.ErrorIs(t, err, domain.ErrUserNotMember)
		assert.Nil(t, messages)

		chatClient.AssertExpectations(t)
		repo.AssertNotCalled(t, "GetByChatID")
	})

	t.Run("error checking membership", func(t *testing.T) {
		repo := new(repoMocks.MockMessageRepository)
		chatClient := new(serviceMocks.MockChatClient)
		svc := NewMessageService(repo, chatClient, logger)

		ctx := context.Background()
		userID := uuid.New()
		chatID := uuid.New()
		token := "jwt_token"
		limit := 50
		offset := 0

		expectedErr := errors.New("chat service error")
		chatClient.On("CheckMembership", ctx, chatID, token).Return(false, expectedErr)

		messages, err := svc.GetHistory(ctx, userID, chatID, limit, offset, token)
		assert.ErrorIs(t, err, expectedErr)
		assert.Nil(t, messages)

		chatClient.AssertExpectations(t)
		repo.AssertNotCalled(t, "GetByChatID")
	})

	t.Run("error getting messages from repository", func(t *testing.T) {
		repo := new(repoMocks.MockMessageRepository)
		chatClient := new(serviceMocks.MockChatClient)
		svc := NewMessageService(repo, chatClient, logger)

		ctx := context.Background()
		userID := uuid.New()
		chatID := uuid.New()
		token := "jwt_token"
		limit := 50
		offset := 0

		expectedErr := errors.New("database error")
		chatClient.On("CheckMembership", ctx, chatID, token).Return(true, nil)
		repo.On("GetByChatID", ctx, chatID, limit, offset).Return(nil, expectedErr)

		messages, err := svc.GetHistory(ctx, userID, chatID, limit, offset, token)
		assert.ErrorIs(t, err, expectedErr)
		assert.Nil(t, messages)

		chatClient.AssertExpectations(t)
		repo.AssertExpectations(t)
	})

	t.Run("with pagination", func(t *testing.T) {
		repo := new(repoMocks.MockMessageRepository)
		chatClient := new(serviceMocks.MockChatClient)
		svc := NewMessageService(repo, chatClient, logger)

		ctx := context.Background()
		userID := uuid.New()
		chatID := uuid.New()
		token := "jwt_token"
		limit := 10
		offset := 20

		expectedMessages := make([]*domain.Message, limit)
		for i := 0; i < limit; i++ {
			expectedMessages[i] = &domain.Message{
				ID:               uuid.New(),
				ChatID:           chatID,
				SenderID:         uuid.New(),
				EncryptedPayload: "payload",
				CreatedAt:        time.Now(),
			}
		}

		chatClient.On("CheckMembership", ctx, chatID, token).Return(true, nil)
		repo.On("GetByChatID", ctx, chatID, limit, offset).Return(expectedMessages, nil)

		messages, err := svc.GetHistory(ctx, userID, chatID, limit, offset, token)
		assert.NoError(t, err)
		assert.Len(t, messages, limit)

		chatClient.AssertExpectations(t)
		repo.AssertExpectations(t)
	})
}
