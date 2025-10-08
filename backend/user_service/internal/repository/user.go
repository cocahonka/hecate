package repository

import (
	"context"
	"errors"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
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

func (r *User) IsExists(ctx context.Context, nickname string) (bool, error) {
	var exists bool
	err := r.pool.QueryRow(
		ctx,
		"SELECT EXISTS(SELECT 1 FROM users WHERE nickname=$1)",
		nickname,
	).Scan(&exists)
	if err != nil {
		return false, err
	}
	return exists, nil
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
