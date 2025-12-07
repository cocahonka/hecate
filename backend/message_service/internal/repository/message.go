package repository

import (
	"context"

	"github.com/cocahonka/hecate/backend/message_service/internal/domain"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Message struct {
	pool *pgxpool.Pool
}

func NewMessageRepository(pool *pgxpool.Pool) *Message {
	return &Message{
		pool: pool,
	}
}

func (r *Message) Create(ctx context.Context, message *domain.Message) error {
	_, err := r.pool.Exec(ctx,
		"INSERT INTO messages (id, chat_id, sender_id, encrypted_payload, created_at) VALUES ($1, $2, $3, $4, $5)",
		message.ID, message.ChatID, message.SenderID, message.EncryptedPayload, message.CreatedAt)
	return err
}

func (r *Message) GetByChatID(ctx context.Context, chatID uuid.UUID, limit, offset int) ([]*domain.Message, error) {
	rows, err := r.pool.Query(ctx,
		"SELECT id, chat_id, sender_id, encrypted_payload, created_at FROM messages WHERE chat_id=$1 ORDER BY created_at DESC LIMIT $2 OFFSET $3",
		chatID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var messages []*domain.Message
	for rows.Next() {
		m := &domain.Message{}
		if err := rows.Scan(&m.ID, &m.ChatID, &m.SenderID, &m.EncryptedPayload, &m.CreatedAt); err != nil {
			return nil, err
		}
		messages = append(messages, m)
	}
	return messages, nil
}
