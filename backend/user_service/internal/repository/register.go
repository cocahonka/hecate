package repository

import (
	"context"

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
