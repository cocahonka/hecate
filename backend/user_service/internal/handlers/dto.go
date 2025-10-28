package handler

type InitRegisterRequest struct {
	Nickname string `json:"nickname" binding:"required,min=3,max=30"`
}

type InitRegisterResponse struct {
	Challenge string `json:"challenge"`
}

type VerifyRegisterRequest struct {
	Nickname          string `json:"nickname" binding:"required,min=3,max=30"`
	SignedChallenge   string `json:"signed_challenge" binding:"required"`
	Pub9c            string `json:"pub9c" binding:"required"`
	Pub9d            string `json:"pub9d" binding:"required"`
}

type VerifyRegisterResponse struct {
	Success bool `json:"success"`
}

type ErrorResponse struct {
	Error string `json:"error"`
}

type InitLoginRequest struct {
	Nickname string `json:"nickname" binding:"required,min=3,max=30"`
}

type InitLoginResponse struct {
	Challenge string `json:"challenge"`
}

type VerifyLoginRequest struct {
	Nickname  string `json:"nickname" binding:"required"`
	Signature string `json:"signature" binding:"required"`
}

type VerifyLoginResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}

type RefreshTokenRequest struct {
	RefreshToken string  `json:"refresh_token" binding:"required"`
	Nickname     *string `json:"nickname,omitempty"`
}

type RefreshTokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}
