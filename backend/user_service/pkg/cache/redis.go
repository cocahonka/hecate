package cache

import (
	"context"

	"github.com/go-redis/redis/v8"
)

func NewRedis(ctx context.Context, addr, password string) (*redis.Client, error) {

	client := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: password,
	})
	if err := client.Ping(ctx).Err(); err != nil {
		return nil, err
	}
	return client, nil
}
