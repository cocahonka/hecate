package handler

import (
	"net/http"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/cocahonka/hecate/backend/user_service/internal/service"
	"github.com/gin-gonic/gin"
)

type Handler struct {
	register *service.Register
}

func NewHandler(register *service.Register) *Handler {
	return &Handler{register: register}
}

func (h *Handler) InitRoutes(env string) http.Handler {
	if env == domain.EnvProduction {
		gin.SetMode(gin.ReleaseMode)
	}

	routes := gin.Default()
	{
		routes.POST("/register/init", h.Init)
	}

	routes.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "pong",
		})
	})
	return routes
}
