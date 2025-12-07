package repository

import (
	"context"
	"errors"

	"github.com/cocahonka/hecate/backend/chat_service/internal/domain"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Chat struct {
	pool *pgxpool.Pool
}

func NewChatRepository(pool *pgxpool.Pool) *Chat {
	return &Chat{
		pool: pool,
	}
}

func (r *Chat) Create(ctx context.Context, chat *domain.Chat) error {
	_, err := r.pool.Exec(ctx,
		"INSERT INTO chats (id, created_at, updated_at) VALUES ($1, $2, $3)",
		chat.ID, chat.CreatedAt, chat.UpdatedAt)
	return err
}

func (r *Chat) CreateWithMembers(ctx context.Context, chat *domain.Chat, members []*domain.ChatMember) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// Create Chat
	_, err = tx.Exec(ctx,
		"INSERT INTO chats (id, created_at, updated_at) VALUES ($1, $2, $3)",
		chat.ID, chat.CreatedAt, chat.UpdatedAt)
	if err != nil {
		return err
	}

	// Create Members
	for _, m := range members {
		_, err = tx.Exec(ctx,
			"INSERT INTO chat_members (chat_id, user_id, encrypted_key, joined_at) VALUES ($1, $2, $3, $4)",
			m.ChatID, m.UserID, m.EncryptedKey, m.JoinedAt)
		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}

func (r *Chat) GetByID(ctx context.Context, chatID uuid.UUID) (*domain.Chat, error) {
	c := &domain.Chat{}
	err := r.pool.QueryRow(ctx,
		"SELECT id, created_at, updated_at FROM chats WHERE id=$1",
		chatID).Scan(&c.ID, &c.CreatedAt, &c.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, domain.ErrChatNotFound
		}
		return nil, err
	}
	return c, nil
}

func (r *Chat) GetByParticipants(ctx context.Context, user1ID, user2ID uuid.UUID) (*domain.Chat, error) {
	c := &domain.Chat{}
	// Find a chat where both users are members.
	// Assuming 1-to-1 chats, a chat with exactly these 2 members (or at least these 2).
	query := `
		SELECT c.id, c.created_at, c.updated_at
		FROM chats c
		JOIN chat_members cm1 ON c.id = cm1.chat_id
		JOIN chat_members cm2 ON c.id = cm2.chat_id
		WHERE cm1.user_id = $1 AND cm2.user_id = $2
		LIMIT 1
	`
	err := r.pool.QueryRow(ctx, query, user1ID, user2ID).Scan(&c.ID, &c.CreatedAt, &c.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, domain.ErrChatNotFound
		}
		return nil, err
	}
	return c, nil
}

func (r *Chat) GetUserChats(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*domain.Chat, error) {
	query := `
		SELECT c.id, c.created_at, c.updated_at
		FROM chats c
		JOIN chat_members cm ON c.id = cm.chat_id
		WHERE cm.user_id = $1
		ORDER BY c.updated_at DESC
		LIMIT $2 OFFSET $3
	`
	rows, err := r.pool.Query(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var chats []*domain.Chat
	for rows.Next() {
		c := &domain.Chat{}
		if err := rows.Scan(&c.ID, &c.CreatedAt, &c.UpdatedAt); err != nil {
			return nil, err
		}
		chats = append(chats, c)
	}
	return chats, nil
}
