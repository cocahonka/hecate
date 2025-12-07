package handlers

import (
	"net/http"
	"strconv"

	"github.com/cocahonka/hecate/backend/chat_service/internal/domain"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// CreateChat godoc
// @Summary      Create a new chat
// @Description  Creates a new one-to-one chat between the current user and a participant
// @Tags         chats
// @Accept       json
// @Produce      json
// @Param        input body CreateChatRequest true "Chat creation parameters"
// @Success      201  {object}  ChatResponse
// @Failure      400  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Failure      409  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     Bearer
// @Router       /chats [post]
func (h *Handler) createChat(c *gin.Context) {
	userID, err := getUserId(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	var input CreateChatRequest
	if err := c.BindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	chat, err := h.service.CreateChat(c.Request.Context(), userID, input.ParticipantID, input.MyEncryptedKey, input.ParticipantEncryptedKey)
	if err != nil {
		if err == domain.ErrChatAlreadyExists {
			c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toChatResponse(chat))
}

// GetUserChats godoc
// @Summary      Get user chats
// @Description  Get a list of chats for the current user with pagination
// @Tags         chats
// @Produce      json
// @Param        limit   query     int  false  "Limit (default 20)"
// @Param        offset  query     int  false  "Offset (default 0)"
// @Success      200     {object}  ChatListResponse
// @Failure      401     {object}  map[string]string
// @Failure      500     {object}  map[string]string
// @Security     Bearer
// @Router       /chats [get]
func (h *Handler) getUserChats(c *gin.Context) {
	userID, err := getUserId(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	limit := 20
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

	chats, err := h.service.GetUserChats(c.Request.Context(), userID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	response := make([]*ChatResponse, len(chats))
	for i, chat := range chats {
		response[i] = toChatResponse(chat)
	}

	c.JSON(http.StatusOK, ChatListResponse{Chats: response, Total: len(response)})
}

// GetChat godoc
// @Summary      Get chat by ID
// @Description  Get details of a specific chat
// @Tags         chats
// @Produce      json
// @Param        id   path      string  true  "Chat ID"
// @Success      200  {object}  ChatResponse
// @Failure      400  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Failure      403  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     Bearer
// @Router       /chats/{id} [get]
func (h *Handler) getChat(c *gin.Context) {
	userID, err := getUserId(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	chatID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid chat id"})
		return
	}

	chat, err := h.service.GetChatByID(c.Request.Context(), chatID, userID)
	if err != nil {
		if err == domain.ErrUserNotMember {
			c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
			return
		}
		if err == domain.ErrChatNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, toChatResponse(chat))
}

// CheckMember godoc
// @Summary      Check membership
// @Description  Check if the current user is a member of the chat
// @Tags         chats
// @Produce      json
// @Param        id   path      string  true  "Chat ID"
// @Success      200  {object}  IsMemberResponse
// @Failure      400  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     Bearer
// @Router       /chats/{id}/member [get]
func (h *Handler) checkMember(c *gin.Context) {
	userID, err := getUserId(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	chatID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid chat id"})
		return
	}

	isMember, err := h.service.CheckUserIsMember(c.Request.Context(), chatID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, IsMemberResponse{IsMember: isMember})
}

// GetEncryptedKey godoc
// @Summary      Get encrypted key
// @Description  Get the encrypted AES key for the current user in the chat
// @Tags         chats
// @Produce      json
// @Param        id   path      string  true  "Chat ID"
// @Success      200  {object}  EncryptedKeyResponse
// @Failure      400  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Failure      403  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     Bearer
// @Router       /chats/{id}/key [get]
func (h *Handler) getEncryptedKey(c *gin.Context) {
	userID, err := getUserId(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	chatID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid chat id"})
		return
	}

	key, err := h.service.GetEncryptedKey(c.Request.Context(), chatID, userID)
	if err != nil {
		if err == domain.ErrUserNotMember {
			c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, EncryptedKeyResponse{EncryptedKey: key})
}

func getUserId(c *gin.Context) (uuid.UUID, error) {
	idStr, exists := c.Get(userCtx)
	if !exists {
		return uuid.Nil, domain.ErrUserNotMember // Internal error really
	}
	return uuid.Parse(idStr.(string))
}

func toChatResponse(chat *domain.Chat) *ChatResponse {
	return &ChatResponse{
		ID:        chat.ID,
		CreatedAt: chat.CreatedAt,
		UpdatedAt: chat.UpdatedAt,
	}
}
