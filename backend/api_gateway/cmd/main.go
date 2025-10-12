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

	"go.uber.org/zap"

	"github.com/cocahonka/hecate/backend/api_gateway/config"
	"github.com/cocahonka/hecate/backend/api_gateway/internal/handler"
	"github.com/cocahonka/hecate/backend/api_gateway/pkg/logger"
)

func main() {
	path := flag.String("config", ".env", "Path to config file")
	flag.Parse()

	cfg := config.MustLoad(*path)

	logger := logger.MustLoad(cfg.Env)

	defer logger.Sync()

	logger.Debug("configuration loaded", zap.Any("config", cfg))

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	handler := handler.NewHandler(logger)
	router := handler.InitRoutes(cfg.Env, cfg.ServiceURLs)

	srv := &http.Server{
		Addr:    fmt.Sprintf(":%s", cfg.ServerPort),
		Handler: router,
	}

	go func() {
		logger.Info("Starting HTTP server", zap.String("address", srv.Addr))
		if err := srv.ListenAndServe(); err != nil {
			if !errors.Is(err, http.ErrServerClosed) {
				logger.Fatal("failed to start HTTP server", zap.Error(err))
			}
		}
	}()

	ch := make(chan os.Signal, 1)
	signal.Notify(ch, os.Interrupt, syscall.SIGTERM)
	<-ch
	logger.Info("Shutting down")
	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("failed to shutdown HTTP server", zap.Error(err))
	}
	cancel()
}
