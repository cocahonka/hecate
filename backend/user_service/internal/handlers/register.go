package handler

import (
	"errors"
	"net/http"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/gin-gonic/gin"
)

// Init initializes the user registration process. It checks if the provided nickname is unique,
// generates a challenge, and saves it with a TTL. If the nickname is not unique, it returns an error.
// @Summary Initialize user registration
// @Description Initiate the registration process by providing a nickname and receiving a challenge
// @Tags Registration
// @Accept json
// @Produce json
// @Param request body InitRegisterRequest true "Registration initialization request"
// @Success 200 {object} InitRegisterResponse "Challenge for registration"
// @Failure 400 {object} ErrorResponse "Invalid request format"
// @Failure 409 {object} ErrorResponse "Nickname is not unique"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /register/init [post]
func (h *Handler) Init(ctx *gin.Context) {
	var req InitRegisterRequest

	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid request"})
		return
	}

	challenge, err := h.register.Init(ctx.Request.Context(), req.Nickname)
	if err != nil {
		if errors.Is(err, domain.ErrNicknameIsNotUnique) {
			ctx.JSON(http.StatusConflict, ErrorResponse{Error: "nickname is not unique"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, ErrorResponse{Error: "internal server error"})
		return
	}
	ctx.JSON(http.StatusOK, InitRegisterResponse{Challenge: challenge})
}
