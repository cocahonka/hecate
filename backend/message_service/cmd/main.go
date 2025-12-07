package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/cocahonka/hecate/backend/message_service/config"
	"github.com/cocahonka/hecate/backend/message_service/internal/handlers"
	"github.com/cocahonka/hecate/backend/message_service/internal/repository"
	"github.com/cocahonka/hecate/backend/message_service/internal/service"
	"github.com/cocahonka/hecate/backend/message_service/pkg/cache"
	"github.com/cocahonka/hecate/backend/message_service/pkg/database"
	"github.com/cocahonka/hecate/backend/message_service/pkg/logger"
	"go.uber.org/zap"
)

// @title           Message Service API
// @version         1.0
// @description     API Server for Message Service

// @host      localhost:8084
// @BasePath  /api/v1

// @securityDefinitions.apikey Bearer
// @in header
// @name Authorization
func main() {
	// 1. Config
	cfg := config.MustLoad(".env")

	// 2. Logger
	log := logger.MustLoad(cfg.Env)
	defer log.Sync()
	log.Info("Message Service starting...", zap.String("env", cfg.Env))

	// 3. Database
	ctx := context.Background()
	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s", cfg.Database.User, cfg.Database.Password, cfg.Database.Host, cfg.Database.Port, cfg.Database.Name)
	pool, err := database.NewPostgres(ctx, dsn)
	if err != nil {
		log.Fatal("Failed to connect to postgres", zap.Error(err))
	}
	defer pool.Close()
	log.Info("Connected to PostgreSQL")

	// 4. Redis
	redisAddr := fmt.Sprintf("%s:%s", cfg.Cache.Host, cfg.Cache.Port)
	redisClient, err := cache.NewRedis(ctx, redisAddr, cfg.Cache.Password)
	if err != nil {
		log.Fatal("Failed to connect to redis", zap.Error(err))
	}
	defer redisClient.Close()
	log.Info("Connected to Redis")

	// 5. Repository
	repo := repository.NewMessageRepository(pool)

	// 6. Service
	chatClient := service.NewChatClient(cfg.ChatServiceURL, log)
	svc := service.NewMessageService(repo, chatClient, log)

	// 7. Handlers
	h := handlers.NewHandler(svc, cfg)
	srv := &http.Server{
		Addr:    fmt.Sprintf(":%s", cfg.ServerPort),
		Handler: h.InitRoutes(cfg.Env),
	}

	// 8. Start
	go func() {
		log.Info("Starting HTTP server", zap.String("address", srv.Addr))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal("failed to start HTTP server", zap.Error(err))
		}
	}()

	// 9. Graceful Shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Info("Message Service shutting down...")

	if err := srv.Shutdown(ctx); err != nil {
		log.Error("Server forced to shutdown", zap.Error(err))
	}
	log.Info("Server exiting")
}
