package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/cocahonka/hecate/backend/user_service/config"
	handler "github.com/cocahonka/hecate/backend/user_service/internal/handlers"
	"github.com/cocahonka/hecate/backend/user_service/internal/repository"
	"github.com/cocahonka/hecate/backend/user_service/internal/service"
	"github.com/cocahonka/hecate/backend/user_service/pkg/cache"
	"github.com/cocahonka/hecate/backend/user_service/pkg/database"
	"github.com/cocahonka/hecate/backend/user_service/pkg/logger"
	"go.uber.org/zap"
)

// @title User Service API
// @version 1.0
// @description API для сервиса управления пользователями

// @BasePath /
// @schemes http
func main() {
	path := flag.String("config", ".env", "Path to config file")
	flag.Parse()

	cfg := config.MustLoad(*path)

	logger := logger.MustLoad(cfg.Env)

	defer logger.Sync()

	logger.Debug("configuration loaded", zap.Any("config", cfg))

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	addr := cfg.Cache.Host + ":" + cfg.Cache.Port

	rClient, err := cache.NewRedis(ctx, addr, cfg.Cache.Password)
	if err != nil {
		logger.Fatal("failed to connect to redis", zap.Error(err))
	}
	defer rClient.Close()

	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		cfg.Database.Host,
		cfg.Database.Port,
		cfg.Database.User,
		cfg.Database.Password,
		cfg.Database.Name)
	pConn, err := database.NewPostgres(ctx, dsn)
	if err != nil {
		logger.Fatal("failed to connect to postgres", zap.Error(err))
	}
	defer pConn.Close()

	logger.Debug("successfully connected to infrastructure services", zap.String("redis_addr", addr), zap.String("postgres_dsn", dsn))

	cacheRepo := repository.NewCacheRepository(rClient)
	userRepo := repository.NewUserRepository(pConn)
	tokenService := service.NewTokenService(cfg.JWT.Secret, cfg.JWT.AccessTokenTTL, cfg.JWT.RefreshTokenTTL)

	RegisterService := service.NewRegisterService(logger, userRepo, cacheRepo, userRepo, cfg.ChallengeTTL)
	LoginService := service.NewLoginService(logger, cacheRepo, userRepo, tokenService, cfg.ChallengeTTL)

	//Создание HTTP сервера
	handlers := handler.NewHandler(RegisterService, LoginService)
	srv := &http.Server{
		Addr:    fmt.Sprintf(":%s", cfg.ServerPort),
		Handler: handlers.InitRoutes(cfg.Env),
	}
	//Запуск HTTP сервера
	go func() {
		logger.Info("Starting HTTP server", zap.String("address", srv.Addr))
		if err := srv.ListenAndServe(); err != nil {
			if !errors.Is(err, http.ErrServerClosed) {
				logger.Fatal("failed to start HTTP server", zap.Error(err))

			}
		}
	}()

	//Graceful shutdown
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, os.Interrupt, syscall.SIGTERM)
	<-ch
	logger.Info("Shutting down")
	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("failed to shutdown HTTP server", zap.Error(err))
	}
	cancel()
}
