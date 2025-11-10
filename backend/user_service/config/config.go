package config

import (
	"errors"
	"time"

	"github.com/ilyakaznacheev/cleanenv"
)

var ErrUnknownEnv = errors.New("unknown enviroment")

type Config struct {
	Database     DatabaseConfig
	Cache        CacheConfig
	JWT          JWTConfig
	Env          string        `env:"ENV" env-default:"production"`
	ChallengeTTL time.Duration `env:"CHALLENGE_TTL" env-default:"3m"` // in seconds
	ServerPort   string        `env:"SERVER_PORT" env-default:"8080"`
}

type JWTConfig struct {
	Secret          string        `env:"JWT_SECRET" env-required:"true"`
	AccessTokenTTL  time.Duration `env:"ACCESS_TOKEN_TTL" env-default:"15m"`
	RefreshTokenTTL time.Duration `env:"REFRESH_TOKEN_TTL" env-default:"24h"`
}
type DatabaseConfig struct {
	Port     string `env:"DB_PORT"`
	Host     string `env:"DB_HOST"`
	Name     string `env:"DB_NAME"`
	User     string `env:"DB_USER"`
	Password string `env:"DB_PASSWORD"`
}

type CacheConfig struct {
	Port     string `env:"CACHE_PORT"`
	Host     string `env:"CACHE_HOST"`
	Password string `env:"CACHE_PASSWORD"`
}

func MustLoad(path string) *Config {
	var cfg Config
	
	// If path is empty or file doesn't exist, read only from env vars
	if path == "" {
		if err := cleanenv.ReadEnv(&cfg); err != nil {
			panic(err)
		}
	} else {
		if err := cleanenv.ReadConfig(path, &cfg); err != nil {
			panic(err)
		}
	}
	return &cfg
}
