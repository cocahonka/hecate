package handlers

import (
	"net/http"
	"strconv"

	"github.com/cocahonka/hecate/backend/message_service/internal/domain"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// SendMessage godoc
// @Summary      Send a message
// @Description  Send an encrypted message to a chat
// @Tags         messages
// @Accept       json
// @Produce      json
// @Param        input body SendMessageRequest true "Message payload"
// @Success      201  {object}  MessageResponse
// @Failure      400  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Failure      403  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     Bearer
// @Router       /messages [post]
func (h *Handler) sendMessage(c *gin.Context) {
	userID, token, err := getUserContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	var input SendMessageRequest
	if err := c.BindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	msg, err := h.service.SendMessage(c.Request.Context(), userID, input.ChatID, input.EncryptedPayload, token)
	if err != nil {
		if err == domain.ErrUserNotMember {
			c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toMessageResponse(msg))
}

// GetHistory godoc
// @Summary      Get message history
// @Description  Get messages for a specific chat with pagination
// @Tags         messages
// @Produce      json
// @Param        chat_id query     string  true   "Chat ID"
// @Param        limit   query     int     false  "Limit (default 50)"
// @Param        offset  query     int     false  "Offset (default 0)"
// @Success      200     {object}  HistoryResponse
// @Failure      400     {object}  map[string]string
// @Failure      401     {object}  map[string]string
// @Failure      403     {object}  map[string]string
// @Failure      500     {object}  map[string]string
// @Security     Bearer
// @Router       /messages [get]
func (h *Handler) getHistory(c *gin.Context) {
	userID, token, err := getUserContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	chatIDStr := c.Query("chat_id")
	if chatIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "chat_id is required"})
		return
	}
	chatID, err := uuid.Parse(chatIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid chat_id"})
		return
	}

	limit := 50
	offset := 0
	if l := c.Query("limit"); l != "" {
		if val, err := strconv.Atoi(l); err == nil {
			limit = val
		}
	}
	if o := c.Query("offset"); o != "" {
		if val, err := strconv.Atoi(o); err == nil {
			offset = val
		}
	}

	messages, err := h.service.GetHistory(c.Request.Context(), userID, chatID, limit, offset, token)
	if err != nil {
		if err == domain.ErrUserNotMember {
			c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	response := make([]*MessageResponse, len(messages))
	for i, m := range messages {
		response[i] = toMessageResponse(m)
	}

	c.JSON(http.StatusOK, HistoryResponse{Messages: response, Total: len(response)})
}

func getUserContext(c *gin.Context) (uuid.UUID, string, error) {
	idStr, exists := c.Get(userCtx)
	if !exists {
		return uuid.Nil, "", domain.ErrUserNotMember
	}
	token, exists := c.Get(tokenCtx)
	if !exists {
		return uuid.Nil, "", domain.ErrUserNotMember
	}
	id, err := uuid.Parse(idStr.(string))
	return id, token.(string), err
}

func toMessageResponse(msg *domain.Message) *MessageResponse {
	return &MessageResponse{
		ID:               msg.ID,
		ChatID:           msg.ChatID,
		SenderID:         msg.SenderID,
		EncryptedPayload: msg.EncryptedPayload,
		CreatedAt:        msg.CreatedAt,
	}
}
