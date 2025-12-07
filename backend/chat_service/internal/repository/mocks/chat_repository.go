package mocks

import (
	"context"

	"github.com/cocahonka/hecate/backend/chat_service/internal/domain"
	"github.com/google/uuid"
	"github.com/stretchr/testify/mock"
)

type ChatRepository struct {
	mock.Mock
}

func (m *ChatRepository) Create(ctx context.Context, chat *domain.Chat) error {
	ret := m.Called(ctx, chat)
	return ret.Error(0)
}

func (m *ChatRepository) CreateWithMembers(ctx context.Context, chat *domain.Chat, members []*domain.ChatMember) error {
	ret := m.Called(ctx, chat, members)
	return ret.Error(0)
}

func (m *ChatRepository) GetByID(ctx context.Context, chatID uuid.UUID) (*domain.Chat, error) {
	ret := m.Called(ctx, chatID)
	var r0 *domain.Chat
	if rf, ok := ret.Get(0).(func(context.Context, uuid.UUID) *domain.Chat); ok {
		r0 = rf(ctx, chatID)
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).(*domain.Chat)
		}
	}
	return r0, ret.Error(1)
}

func (m *ChatRepository) GetByParticipants(ctx context.Context, user1ID, user2ID uuid.UUID) (*domain.Chat, error) {
	ret := m.Called(ctx, user1ID, user2ID)
	var r0 *domain.Chat
	if rf, ok := ret.Get(0).(func(context.Context, uuid.UUID, uuid.UUID) *domain.Chat); ok {
		r0 = rf(ctx, user1ID, user2ID)
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).(*domain.Chat)
		}
	}
	return r0, ret.Error(1)
}

func (m *ChatRepository) GetUserChats(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*domain.Chat, error) {
	ret := m.Called(ctx, userID, limit, offset)
	var r0 []*domain.Chat
	if rf, ok := ret.Get(0).(func(context.Context, uuid.UUID, int, int) []*domain.Chat); ok {
		r0 = rf(ctx, userID, limit, offset)
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).([]*domain.Chat)
		}
	}
	return r0, ret.Error(1)
}
