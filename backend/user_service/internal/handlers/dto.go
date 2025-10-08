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
