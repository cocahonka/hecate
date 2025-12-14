package repository

import (
	"context"
	"errors"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

type User struct {
	pool *pgxpool.Pool
}

func NewUserRepository(pool *pgxpool.Pool) *User {
	return &User{
		pool: pool,
	}
}

func (r *User) Create(ctx context.Context, nickname, pub9c, pub9d string) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO users (nickname, pubkey_auth, pubkey_enc) VALUES ($1, $2, $3)`,
		nickname, pub9c, pub9d)
	if err != nil {
		// Check if error is due to unique constraint violation
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == "23505" { // unique_violation
			return domain.ErrNicknameIsNotUnique
		}
		return err
	}
	return nil
}

func (r *User) Get(ctx context.Context, nickname string) (*domain.User, error) {
	user := &domain.User{}
	err := r.pool.QueryRow(ctx,
		"SELECT id, nickname, pubkey_auth, pubkey_enc FROM users WHERE nickname=$1",
		nickname).Scan(&user.ID, &user.Nickname, &user.Pub9c, &user.Pub9d)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, domain.ErrUserNotFound
		}
		return nil, err
	}
	return user, nil
}

func (r *User) GetByID(ctx context.Context, userID uuid.UUID) (*domain.User, error) {
	user := &domain.User{}
	err := r.pool.QueryRow(ctx,
		"SELECT id, nickname, pubkey_auth, pubkey_enc FROM users WHERE id=$1",
		userID).Scan(&user.ID, &user.Nickname, &user.Pub9c, &user.Pub9d)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, domain.ErrUserNotFound
		}
		return nil, err
	}
	return user, nil
}
