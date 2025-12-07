package domain

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrChatNotFound = errors.New("chat not found")
	ErrUserNotMember = errors.New("user is not a member of this chat")
)

type Message struct {
	ID               uuid.UUID `json:"id" db:"id"`
	ChatID           uuid.UUID `json:"chat_id" db:"chat_id"`
	SenderID         uuid.UUID `json:"sender_id" db:"sender_id"`
	EncryptedPayload string    `json:"encrypted_payload" db:"encrypted_payload"`
	CreatedAt        time.Time `json:"created_at" db:"created_at"`
}
