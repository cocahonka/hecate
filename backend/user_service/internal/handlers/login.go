package handler

import (
	"errors"
	"net/http"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/gin-gonic/gin"
)

// InitLogin initializes the user login process. It checks if the provided nickname exists,
// generates a challenge, and saves it with a TTL. If the nickname is not found, it returns an error.
// @Summary Initialize user login
// @Description Initiate the login process by providing a nickname and receiving a challenge
// @Tags Login
// @Accept json
// @Produce json
// @Param request body InitLoginRequest true "Login initialization request"
// @Success 200 {object} InitLoginResponse "Challenge for login"
// @Failure 400 {object} ErrorResponse "Invalid request format"
// @Failure 404 {object} ErrorResponse "Nickname not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /login/init [post]
func (h *Handler) InitLogin(ctx *gin.Context) {
	var req InitLoginRequest

	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid request"})
		return
	}

	challenge, err := h.login.Init(ctx.Request.Context(), req.Nickname)
	if err != nil {
		if errors.Is(err, domain.ErrUserNotFound) {
			ctx.JSON(http.StatusNotFound, ErrorResponse{Error: "nickname not found"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, ErrorResponse{Error: "internal server error"})
		return
	}
	ctx.JSON(http.StatusOK, InitLoginResponse{Challenge: challenge})
}

// VerifyLogin verifies the signed challenge and returns JWT tokens upon success.
// @Summary Verify user login
// @Description Verify the signed challenge to complete the login process and receive JWT tokens.
// @Tags Login
// @Accept json
// @Produce json
// @Param request body VerifyLoginRequest true "Login verification request"
// @Success 200 {object} VerifyLoginResponse "Access and refresh tokens"
// @Failure 400 {object} ErrorResponse "Invalid request format"
// @Failure 401 {object} ErrorResponse "Invalid signature"
// @Failure 404 {object} ErrorResponse "Nickname not found or challenge expired"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /login/verify [post]
func (h *Handler) VerifyLogin(ctx *gin.Context) {
	var req VerifyLoginRequest

	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid request"})
		return
	}

	accessToken, refreshToken, err := h.login.Verify(ctx.Request.Context(), req.Nickname, req.Signature)
	if err != nil {
		if errors.Is(err, domain.ErrInvalidSignature) {
			ctx.JSON(http.StatusUnauthorized, ErrorResponse{Error: "invalid signature"})
			return
		}
		// This could also be a cache miss, which means the challenge expired.
		if errors.Is(err, domain.ErrUserNotFound) {
			ctx.JSON(http.StatusNotFound, ErrorResponse{Error: "nickname not found or challenge expired"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, ErrorResponse{Error: "internal server error"})
		return
	}

	ctx.JSON(http.StatusOK, VerifyLoginResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	})
}

// RefreshToken validates a refresh token and returns new access and refresh tokens.
// @Summary Refresh access token
// @Description Refresh access and refresh tokens using a valid refresh token
// @Tags Login
// @Accept json
// @Produce json
// @Param request body RefreshTokenRequest true "Refresh token request"
// @Success 200 {object} RefreshTokenResponse "New access and refresh tokens"
// @Failure 400 {object} ErrorResponse "Invalid request format"
// @Failure 401 {object} ErrorResponse "Invalid or expired refresh token"
// @Failure 404 {object} ErrorResponse "User not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /login/refresh [post]
func (h *Handler) RefreshToken(ctx *gin.Context) {
	var req RefreshTokenRequest

	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid request"})
		return
	}

	accessToken, refreshToken, err := h.login.Refresh(ctx.Request.Context(), req.RefreshToken, req.Nickname)
	if err != nil {
		if errors.Is(err, domain.ErrInvalidRefreshToken) {
			ctx.JSON(http.StatusUnauthorized, ErrorResponse{Error: "invalid or expired refresh token"})
			return
		}
		if errors.Is(err, domain.ErrRefreshTokenMismatch) {
			ctx.JSON(http.StatusUnauthorized, ErrorResponse{Error: "invalid or expired refresh token"})
			return
		}
		if errors.Is(err, domain.ErrUserNotFound) {
			ctx.JSON(http.StatusNotFound, ErrorResponse{Error: "user not found"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, ErrorResponse{Error: "internal server error"})
		return
	}

	ctx.JSON(http.StatusOK, RefreshTokenResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	})
}

