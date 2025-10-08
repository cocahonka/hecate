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

// Verify verifies the signed challenge and completes the user registration.
// @Summary Verify user registration
// @Description Verify the signed challenge and complete the registration process
// @Tags Registration
// @Accept json
// @Produce json
// @Param request body VerifyRegisterRequest true "Registration verification request"
// @Success 200 {object} VerifyRegisterResponse "Registration completed successfully"
// @Failure 400 {object} ErrorResponse "Invalid request format"
// @Failure 401 {object} ErrorResponse "Invalid signature"
// @Failure 404 {object} ErrorResponse "Challenge not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /register/verify [post]
func (h *Handler) Verify(ctx *gin.Context) {
	var req VerifyRegisterRequest

	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid request"})
		return
	}

	err := h.register.VerifyAndComplete(ctx.Request.Context(), req.Nickname, req.SignedChallenge, req.Pub9c, req.Pub9d)
	if err != nil {
		if errors.Is(err, domain.ErrInvalidSignature) {
			ctx.JSON(http.StatusUnauthorized, ErrorResponse{Error: "invalid signature"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, ErrorResponse{Error: "internal server error"})
		return
	}
	ctx.JSON(http.StatusOK, VerifyRegisterResponse{Success: true})
}
