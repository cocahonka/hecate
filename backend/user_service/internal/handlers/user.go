package handler

import (
	"errors"
	"net/http"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
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

// GetUserByID gets user info by ID.
// @Summary Get user info by ID
// @Description Get public user info by user ID
// @Tags User
// @Produce json
// @Param id path string true "User ID"
// @Success 200 {object} GetUserResponse "User info"
// @Failure 400 {object} ErrorResponse "Invalid user ID"
// @Failure 404 {object} ErrorResponse "User not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /user/id/{id} [get]
func (h *Handler) GetUserByID(ctx *gin.Context) {
	idStr := ctx.Param("id")
	if idStr == "" {
		ctx.JSON(http.StatusBadRequest, ErrorResponse{Error: "id is required"})
		return
	}

	userID, err := uuid.Parse(idStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid user id"})
		return
	}

	user, err := h.user.GetByID(ctx.Request.Context(), userID)
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
