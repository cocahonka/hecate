package handler

import (
	"errors"
	"net/http"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/gin-gonic/gin"
)

// GetUser gets user info by nickname.
// @Summary Get user info
// @Description Get public user info by nickname
// @Tags User
// @Produce json
// @Param nickname path string true "User Nickname"
// @Success 200 {object} GetUserResponse "User info"
// @Failure 404 {object} ErrorResponse "User not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /user/{nickname} [get]
func (h *Handler) GetUser(ctx *gin.Context) {
	nickname := ctx.Param("nickname")
	if nickname == "" {
		ctx.JSON(http.StatusBadRequest, ErrorResponse{Error: "nickname is required"})
		return
	}

	user, err := h.user.Get(ctx.Request.Context(), nickname)
	if err != nil {
		if errors.Is(err, domain.ErrUserNotFound) {
			ctx.JSON(http.StatusNotFound, ErrorResponse{Error: "user not found"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, ErrorResponse{Error: "internal server error"})
		return
	}

	ctx.JSON(http.StatusOK, GetUserResponse{
		ID:       user.ID.String(),
		Nickname: user.Nickname,
		Pub9c:    user.Pub9c,
		Pub9d:    user.Pub9d,
	})
}
