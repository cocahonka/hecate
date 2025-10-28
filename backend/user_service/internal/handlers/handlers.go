package handler

import (
	"net/http"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/gin-gonic/gin"
)

var userServicePrefix = "/user"

type Handler struct {
	register RegisterManager
	login    LoginManager
}

func NewHandler(register RegisterManager, login LoginManager) *Handler {
	return &Handler{
		register: register,
		login:    login,
	}
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
		routes.POST("/login/init", h.InitLogin)
		routes.POST("/login/verify", h.VerifyLogin)
		routes.POST("/login/refresh", h.RefreshToken)
	}

	routes.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "pong",
		})
	})
	return engine
}
