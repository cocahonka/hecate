package mocks

import (
	"context"

	"github.com/cocahonka/hecate/backend/chat_service/internal/domain"
	"github.com/google/uuid"
	"github.com/stretchr/testify/mock"
)

type ChatMemberRepository struct {
	mock.Mock
}

func (m *ChatMemberRepository) Create(ctx context.Context, member *domain.ChatMember) error {
	ret := m.Called(ctx, member)
	return ret.Error(0)
}

func (m *ChatMemberRepository) IsMember(ctx context.Context, chatID, userID uuid.UUID) (bool, error) {
	ret := m.Called(ctx, chatID, userID)
	return ret.Bool(0), ret.Error(1)
}

func (m *ChatMemberRepository) GetEncryptedKey(ctx context.Context, chatID, userID uuid.UUID) (string, error) {
	ret := m.Called(ctx, chatID, userID)
	return ret.String(0), ret.Error(1)
}

func (m *ChatMemberRepository) GetChatMembers(ctx context.Context, chatID uuid.UUID) ([]*domain.ChatMember, error) {
	ret := m.Called(ctx, chatID)
	var r0 []*domain.ChatMember
	if rf, ok := ret.Get(0).(func(context.Context, uuid.UUID) []*domain.ChatMember); ok {
		r0 = rf(ctx, chatID)
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).([]*domain.ChatMember)
		}
	}
	return r0, ret.Error(1)
}
