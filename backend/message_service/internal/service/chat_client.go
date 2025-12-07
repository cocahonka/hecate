package service

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"
)

type HTTPChatClient struct {
	baseURL string
	client  *http.Client
	logger  *zap.Logger
}

func NewChatClient(baseURL string, logger *zap.Logger) *HTTPChatClient {
	return &HTTPChatClient{
		baseURL: baseURL,
		client: &http.Client{
			Timeout: 5 * time.Second,
		},
		logger: logger,
	}
}

type checkMemberResponse struct {
	IsMember bool `json:"is_member"`
}

func (c *HTTPChatClient) CheckMembership(ctx context.Context, chatID uuid.UUID, token string) (bool, error) {
	url := fmt.Sprintf("%s/api/v1/chats/%s/member", c.baseURL, chatID.String())
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return false, err
	}

	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := c.client.Do(req)
	if err != nil {
		c.logger.Error("failed to request chat service", zap.Error(err))
		return false, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		c.logger.Warn("chat service returned non-200 status", zap.Int("status", resp.StatusCode))
		return false, nil // Or error depending on requirements. Assuming false if check fails.
	}

	var result checkMemberResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return false, err
	}

	return result.IsMember, nil
}
