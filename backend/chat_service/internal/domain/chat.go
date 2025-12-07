package domain

import (
	"time"

	"github.com/google/uuid"
)

// Chat represents a conversation between users
type Chat struct {
	ID        uuid.UUID `json:"id" db:"id"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// ChatMember represents a user participating in a chat with their specific encrypted key
type ChatMember struct {
	ChatID       uuid.UUID `json:"chat_id" db:"chat_id"`
	UserID       uuid.UUID `json:"user_id" db:"user_id"`
	EncryptedKey string    `json:"encrypted_key" db:"encrypted_key"`
	JoinedAt     time.Time `json:"joined_at" db:"joined_at"`
}
