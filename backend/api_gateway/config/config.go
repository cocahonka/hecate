package config

import (
	"github.com/ilyakaznacheev/cleanenv"
)

type Config struct {
	Env         string `env:"ENV" env-default:"production"`
	ServerPort  string `env:"SERVER_PORT" env-default:"8081"`
	ServiceURLs ServiceURLs
}

type ServiceURLs struct {
	UserServiceURL string `env:"USER_SERVICE_URL" env-required:"true"`
}

func MustLoad(path string) *Config {
	var cfg Config
	if err := cleanenv.ReadConfig(path, &cfg); err != nil {
		panic(err)
	}
	return &cfg
}
