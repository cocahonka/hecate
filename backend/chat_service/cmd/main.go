package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/cocahonka/hecate/backend/chat_service/config"
	"github.com/cocahonka/hecate/backend/chat_service/internal/handlers"
	"github.com/cocahonka/hecate/backend/chat_service/internal/repository"
	"github.com/cocahonka/hecate/backend/chat_service/internal/service"
	"github.com/cocahonka/hecate/backend/chat_service/pkg/cache"
	"github.com/cocahonka/hecate/backend/chat_service/pkg/database"
	"github.com/cocahonka/hecate/backend/chat_service/pkg/logger"
	"go.uber.org/zap"
)

// @title           Chat Service API
// @version         1.0
// @description     API Server for Chat Service

// @host      localhost:8083
// @BasePath  /api/v1

// @securityDefinitions.apikey Bearer
// @in header
// @name Authorization
func main() {
	// 1. Config
	cfg := config.MustLoad(".env") // Or flag

	// 2. Logger
	log := logger.MustLoad(cfg.Env)
	defer log.Sync()
	log.Info("Chat Service starting...", zap.String("env", cfg.Env))

	// 3. Database
	ctx := context.Background()
	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s", cfg.Database.User, cfg.Database.Password, cfg.Database.Host, cfg.Database.Port, cfg.Database.Name)
	pool, err := database.NewPostgres(ctx, dsn)
	if err != nil {
		log.Fatal("Failed to connect to postgres", zap.Error(err))
	}
	defer pool.Close()
	log.Info("Connected to PostgreSQL")

	// 4. Redis (Not used in service logic yet, but kept as per Plan TASK-3)
	redisAddr := fmt.Sprintf("%s:%s", cfg.Cache.Host, cfg.Cache.Port)
	redisClient, err := cache.NewRedis(ctx, redisAddr, cfg.Cache.Password)
	if err != nil {
		log.Fatal("Failed to connect to redis", zap.Error(err))
	}
	defer redisClient.Close()
	log.Info("Connected to Redis")

	// 5. Repositories
	chatRepo := repository.NewChatRepository(pool)
	memberRepo := repository.NewChatMemberRepository(pool)

	// 6. Services
	chatService := service.NewChatService(chatRepo, memberRepo, log)

	// 7. Handlers & Routes
	h := handlers.NewHandler(chatService, cfg)
	srv := &http.Server{
		Addr:    fmt.Sprintf(":%s", cfg.ServerPort),
		Handler: h.InitRoutes(cfg.Env),
	}

	// 8. Start Server
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
	log.Info("Chat Service shutting down...")

	if err := srv.Shutdown(ctx); err != nil {
		log.Error("Server forced to shutdown", zap.Error(err))
	}
	log.Info("Server exiting")
}