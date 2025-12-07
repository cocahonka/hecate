package repository

import (
	"context"
	"errors"

	"github.com/cocahonka/hecate/backend/chat_service/internal/domain"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type ChatMember struct {
	pool *pgxpool.Pool
}

func NewChatMemberRepository(pool *pgxpool.Pool) *ChatMember {
	return &ChatMember{
		pool: pool,
	}
}

func (r *ChatMember) Create(ctx context.Context, member *domain.ChatMember) error {
	_, err := r.pool.Exec(ctx,
		"INSERT INTO chat_members (chat_id, user_id, encrypted_key, joined_at) VALUES ($1, $2, $3, $4)",
		member.ChatID, member.UserID, member.EncryptedKey, member.JoinedAt)
	return err
}

func (r *ChatMember) IsMember(ctx context.Context, chatID, userID uuid.UUID) (bool, error) {
	var exists bool
	err := r.pool.QueryRow(ctx,
		"SELECT EXISTS(SELECT 1 FROM chat_members WHERE chat_id=$1 AND user_id=$2)",
		chatID, userID).Scan(&exists)
	return exists, err
}

func (r *ChatMember) GetEncryptedKey(ctx context.Context, chatID, userID uuid.UUID) (string, error) {
	var key string
	err := r.pool.QueryRow(ctx,
		"SELECT encrypted_key FROM chat_members WHERE chat_id=$1 AND user_id=$2",
		chatID, userID).Scan(&key)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return "", domain.ErrUserNotMember
		}
		return "", err
	}
	return key, nil
}

func (r *ChatMember) GetChatMembers(ctx context.Context, chatID uuid.UUID) ([]*domain.ChatMember, error) {
	rows, err := r.pool.Query(ctx,
		"SELECT chat_id, user_id, encrypted_key, joined_at FROM chat_members WHERE chat_id=$1",
		chatID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var members []*domain.ChatMember
	for rows.Next() {
		m := &domain.ChatMember{}
		if err := rows.Scan(&m.ChatID, &m.UserID, &m.EncryptedKey, &m.JoinedAt); err != nil {
			return nil, err
		}
		members = append(members, m)
	}
	return members, nil
}
