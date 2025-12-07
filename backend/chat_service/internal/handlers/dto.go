package handlers

import (
	"time"

	"github.com/google/uuid"
)

type CreateChatRequest struct {
	ParticipantID           uuid.UUID `json:"participant_id" binding:"required"`
	MyEncryptedKey          string    `json:"my_encrypted_key" binding:"required"`
	ParticipantEncryptedKey string    `json:"participant_encrypted_key" binding:"required"`
}

type ChatResponse struct {
	ID        uuid.UUID `json:"id"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type ChatListResponse struct {
	Chats []*ChatResponse `json:"chats"`
	Total int             `json:"total"` // Optional, if we implement count
}

type IsMemberResponse struct {
	IsMember bool `json:"is_member"`
}

type EncryptedKeyResponse struct {
	EncryptedKey string `json:"encrypted_key"`
}
