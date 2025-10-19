package handler

import (
	"net/http"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/cocahonka/hecate/backend/user_service/internal/service"
	"github.com/gin-gonic/gin"
)

var userServicePrefix = "/user"

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

	engine := gin.Default()
	routes := engine.Group(userServicePrefix)
	{
		routes.POST("/register/init", h.Init)
		routes.POST("/register/verify", h.Verify)
	}

	routes.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "pong",
		})
	})
	return engine
}
