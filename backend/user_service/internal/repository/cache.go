package repository

import (
	"context"
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
