package handler

import (
	"net/http"
	"net/http/httputil"
	"net/url"

	"github.com/cocahonka/hecate/backend/api_gateway/config"
	"github.com/cocahonka/hecate/backend/api_gateway/internal/domain"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

type Handler struct {
	logger *zap.Logger
}

func NewHandler(logger *zap.Logger) *Handler {
	return &Handler{
		logger: logger,
	}
}

func (h *Handler) InitRoutes(env string, urls config.ServiceURLs) http.Handler {
	if env == domain.EnvProduction {
		gin.SetMode(gin.ReleaseMode)
	}

	routes := gin.Default()
	{
		routes.Any("/user-service/*path", h.setupProxy(urls.UserServiceURL))
	}

	routes.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "pong",
		})
	})
	return routes
}

func (h *Handler) setupProxy(target string) gin.HandlerFunc {
	return func(c *gin.Context) {
		remote, err := url.Parse(target)
		if err != nil {
			h.logger.Error("error parsing target url: %v", zap.Error(err))
			c.JSON(http.StatusInternalServerError, ErrorResponse{
				Error: "Internal server error",
			})
			return
		}

		proxy := httputil.NewSingleHostReverseProxy(remote)
		proxy.ServeHTTP(c.Writer, c.Request)
	}
}
