package handlers

import (
	"net/http"

	"github.com/cocahonka/hecate/backend/message_service/config"
	"github.com/cocahonka/hecate/backend/message_service/internal/domain"
	"github.com/gin-gonic/gin"
)

type Handler struct {
	service    MessageService
	middleware *Middleware
}

func NewHandler(service MessageService, cfg *config.Config) *Handler {
	return &Handler{
		service:    service,
		middleware: NewMiddleware(cfg),
	}
}

func (h *Handler) InitRoutes(env string) http.Handler {
	if env == domain.EnvProduction {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.Default()
	
	// TODO: Swagger setup

	api := router.Group("/api/v1")
	{
		messages := api.Group("/messages", h.middleware.UserIdentity)
		{
			messages.POST("", h.sendMessage)
			messages.GET("", h.getHistory)
		}
	}

	return router
}
