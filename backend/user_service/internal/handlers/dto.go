package handler

type InitRegisterRequest struct {
	Nickname string `json:"nickname" binding:"required,min=3,max=30"`
}

type InitRegisterResponse struct {
	Challenge string `json:"challenge"`
}

type ErrorResponse struct {
	Error string `json:"error"`
}
