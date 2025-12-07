package handlers

import (
	"time"

	"github.com/google/uuid"
)

type SendMessageRequest struct {
	ChatID           uuid.UUID `json:"chat_id" binding:"required"`
	EncryptedPayload string    `json:"encrypted_payload" binding:"required"`
}

type MessageResponse struct {
	ID               uuid.UUID `json:"id"`
	ChatID           uuid.UUID `json:"chat_id"`
	SenderID         uuid.UUID `json:"sender_id"`
	EncryptedPayload string    `json:"encrypted_payload"`
	CreatedAt        time.Time `json:"created_at"`
}

type HistoryResponse struct {
	Messages []*MessageResponse `json:"messages"`
	Total    int                `json:"total"`
}
