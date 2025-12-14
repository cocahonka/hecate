package handlers

import (
	"net/http"

	"github.com/cocahonka/hecate/backend/chat_service/config"
	"github.com/cocahonka/hecate/backend/chat_service/internal/domain"
	"github.com/gin-gonic/gin"
)

type Handler struct {
	service    ChatService
	middleware *Middleware
}

func NewHandler(service ChatService, cfg *config.Config) *Handler {
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

	// Swagger (TASK-23) - Placeholder, need to import gin-swagger
	// router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	api := router.Group("/api/v1")
	{
		chats := api.Group("/chats", h.middleware.UserIdentity)
		{
			chats.POST("", h.createChat)
			chats.GET("", h.getUserChats)
			chats.GET("/:id", h.getChat)
			chats.GET("/:id/member", h.checkMember)
			chats.GET("/:id/key", h.getEncryptedKey)
			chats.GET("/:id/members", h.getChatMembers)
		}
	}

	return router
}
