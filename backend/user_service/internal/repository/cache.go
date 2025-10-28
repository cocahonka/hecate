package repository

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/go-redis/redis/v8"
)

type Cache struct {
	client *redis.Client
}

func NewCacheRepository(client *redis.Client) *Cache {
	return &Cache{
		client: client,
	}
}

func (r *Cache) Save(ctx context.Context, nickname, challenge string, ttl time.Duration) error {
	return r.client.Set(ctx, fmt.Sprintf("%s:%s", domain.CacheKeyPrefix, nickname), challenge, ttl).Err()
}

func (r *Cache) Load(ctx context.Context, nickname string) (string, error) {
	val, err := r.client.Get(ctx, fmt.Sprintf("%s:%s", domain.CacheKeyPrefix, nickname)).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return "", domain.ErrChallengeNotFound
		}
		return "", err
	}
	return val, nil
}

func (r *Cache) Delete(ctx context.Context, nickname string) error {
	_, err := r.client.Del(ctx, fmt.Sprintf("%s:%s", domain.CacheKeyPrefix, nickname)).Result()
	if err != nil {
		return err
	}
	return nil
}

func (r *Cache) SaveRefreshToken(ctx context.Context, userID, refreshToken string, ttl time.Duration) error {
	return r.client.Set(ctx, fmt.Sprintf("%s:%s", domain.RefreshTokenKeyPrefix, userID), refreshToken, ttl).Err()
}

func (r *Cache) GetRefreshToken(ctx context.Context, userID string) (string, error) {
	val, err := r.client.Get(ctx, fmt.Sprintf("%s:%s", domain.RefreshTokenKeyPrefix, userID)).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return "", domain.ErrRefreshTokenNotFound
		}
		return "", err
	}
	return val, nil
}

func (r *Cache) DeleteRefreshToken(ctx context.Context, userID string) error {
	_, err := r.client.Del(ctx, fmt.Sprintf("%s:%s", domain.RefreshTokenKeyPrefix, userID)).Result()
	return err
}
