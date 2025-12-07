package main

import (
	"bytes"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io"
	"net/http"
)

const (
	userBaseURL    = "http://localhost:8082/user"
	chatBaseURL    = "http://localhost:8083/api/v1/chats"
	messageBaseURL = "http://localhost:8084/api/v1/messages"
)

// --- DTOs ---

type InitRegisterRequest struct {
	Nickname string `json:"nickname"`
}

type InitRegisterResponse struct {
	Challenge string `json:"challenge"`
}

type VerifyRegisterRequest struct {
	Nickname        string `json:"nickname"`
	SignedChallenge string `json:"signed_challenge"`
	Pub9c           string `json:"pub9c"`
	Pub9d           string `json:"pub9d"`
}

type InitLoginRequest struct {
	Nickname string `json:"nickname"`
}

type InitLoginResponse struct {
	Challenge string `json:"challenge"`
}

type VerifyLoginRequest struct {
	Nickname  string `json:"nickname"`
	Signature string `json:"signature"`
}

type VerifyLoginResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}

type GetUserResponse struct {
	ID       string `json:"id"`
	Nickname string `json:"nickname"`
	Pub9c    string `json:"pub9c"`
	Pub9d    string `json:"pub9d"`
}

type CreateChatRequest struct {
	ParticipantID           string `json:"participant_id"`
	MyEncryptedKey          string `json:"my_encrypted_key"`
	ParticipantEncryptedKey string `json:"participant_encrypted_key"`
}

type ChatResponse struct {
	ID string `json:"id"`
}

type SendMessageRequest struct {
	ChatID           string `json:"chat_id"`
	EncryptedPayload string `json:"encrypted_payload"`
}

type MessageResponse struct {
	ID               string `json:"id"`
	ChatID           string `json:"chat_id"`
	SenderID         string `json:"sender_id"`
	EncryptedPayload string `json:"encrypted_payload"`
	CreatedAt        string `json:"created_at"`
}

type HistoryResponse struct {
	Messages []*MessageResponse `json:"messages"`
	Total    int                `json:"total"`
}

// --- Main ---

func main() {
	// 1. Register & Login Alice
	alicePriv, alicePub, err := generateKeys()
	if err != nil {
		panic(err)
	}
	if err := registerUser("alice", alicePriv, alicePub); err != nil {
		fmt.Printf("Alice register/check failed (might already exist): %v\n", err)
	}
	aliceToken, err := loginUser("alice", alicePriv)
	if err != nil {
		panic(fmt.Sprintf("Alice login failed: %v", err))
	}
	fmt.Println("Alice logged in!")

	// 2. Register & Login Bob
	bobPriv, bobPub, err := generateKeys()
	if err != nil {
		panic(err)
	}
	if err := registerUser("bob", bobPriv, bobPub); err != nil {
		fmt.Printf("Bob register/check failed (might already exist): %v\n", err)
	}
	// We need Bob's ID
	bobInfo, err := getUser("bob")
	if err != nil {
		panic(fmt.Sprintf("Get Bob failed: %v", err))
	}
	fmt.Printf("Bob ID: %s\n", bobInfo.ID)

	// 3. Create Chat (Alice creates chat with Bob)
	fmt.Println("Creating chat...")
	req := CreateChatRequest{
		ParticipantID:           bobInfo.ID,
		MyEncryptedKey:          "key_for_alice",
		ParticipantEncryptedKey: "key_for_bob",
	}
	reqBytes, _ := json.Marshal(req)
	
	createResp, err := doRequest("POST", chatBaseURL, reqBytes, aliceToken)
	if err != nil {
		panic(fmt.Sprintf("Create chat failed: %v", err))
	}
	fmt.Printf("Chat created: %s\n", string(createResp))

	var chatInfo ChatResponse
	json.Unmarshal(createResp, &chatInfo)

	// 4. Send Message (Alice -> Bob)
	fmt.Println("Sending message...")
	msgReq := SendMessageRequest{
		ChatID:           chatInfo.ID,
		EncryptedPayload: "SGVsbG8gQm9iIQ==", // "Hello Bob!" base64
	}
	msgReqBytes, _ := json.Marshal(msgReq)
	msgResp, err := doRequest("POST", messageBaseURL, msgReqBytes, aliceToken)
	if err != nil {
		panic(fmt.Sprintf("Send message failed: %v", err))
	}
	fmt.Printf("Message sent: %s\n", string(msgResp))

	// 5. Get History (Alice)
	fmt.Println("Getting history...")
	histResp, err := doRequest("GET", fmt.Sprintf("%s?chat_id=%s", messageBaseURL, chatInfo.ID), nil, aliceToken)
	if err != nil {
		panic(fmt.Sprintf("Get history failed: %v", err))
	}
	fmt.Printf("History: %s\n", string(histResp))
}

// --- Helpers ---

func generateKeys() (*ecdsa.PrivateKey, string, error) {
	priv, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return nil, "", err
	}
	pubBytes, _ := x509.MarshalPKIXPublicKey(&priv.PublicKey)
	pubPem := string(pem.EncodeToMemory(&pem.Block{Type: "PUBLIC KEY", Bytes: pubBytes}))
	return priv, pubPem, nil
}

func registerUser(nickname string, priv *ecdsa.PrivateKey, pubPem string) error {
	// Init
	initReq := InitRegisterRequest{Nickname: nickname}
	reqBody, _ := json.Marshal(initReq)
	respBytes, err := doRequest("POST", userBaseURL+"/register/init", reqBody, "")
	if err != nil {
		return err
	}
	var initData InitRegisterResponse
	json.Unmarshal(respBytes, &initData)

	// Sign
	sigStr, err := signChallenge(initData.Challenge, priv)
	if err != nil {
		return err
	}

	// Verify
	verifyReq := VerifyRegisterRequest{
		Nickname:        nickname,
		SignedChallenge: sigStr,
		Pub9c:           pubPem,
		Pub9d:           pubPem,
	}
	reqBytes, _ := json.Marshal(verifyReq)
	_, err = doRequest("POST", userBaseURL+"/register/verify", reqBytes, "")
	return err
}

func loginUser(nickname string, priv *ecdsa.PrivateKey) (string, error) {
	// Init
	initReq := InitLoginRequest{Nickname: nickname}
	reqBody, _ := json.Marshal(initReq)
	respBytes, err := doRequest("POST", userBaseURL+"/login/init", reqBody, "")
	if err != nil {
		return "", err
	}
	var initData InitLoginResponse
	json.Unmarshal(respBytes, &initData)

	// Sign
	sigStr, err := signChallenge(initData.Challenge, priv)
	if err != nil {
		return "", err
	}

	// Verify
	verifyReq := VerifyLoginRequest{
		Nickname:  nickname,
		Signature: sigStr,
	}
	reqBytes, _ := json.Marshal(verifyReq)
	respBytes, err = doRequest("POST", userBaseURL+"/login/verify", reqBytes, "")
	if err != nil {
		return "", err
	}

	var loginData VerifyLoginResponse
	json.Unmarshal(respBytes, &loginData)
	return loginData.AccessToken, nil
}

func getUser(nickname string) (*GetUserResponse, error) {
	respBytes, err := doRequest("GET", userBaseURL+"/user/"+nickname, nil, "")
	if err != nil {
		return nil, err
	}
	var user GetUserResponse
	json.Unmarshal(respBytes, &user)
	return &user, nil
}

func signChallenge(challenge string, priv *ecdsa.PrivateKey) (string, error) {
	challengeBytes, err := base64.RawURLEncoding.DecodeString(challenge)
	if err != nil {
		return "", err
	}
	hash := sha256.Sum256(challengeBytes)
	signature, err := ecdsa.SignASN1(rand.Reader, priv, hash[:])
	if err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(signature), nil
}

func doRequest(method, url string, body []byte, token string) ([]byte, error) {
	req, err := http.NewRequest(method, url, bytes.NewBuffer(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	respBody, _ := io.ReadAll(resp.Body)

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("status %d: %s", resp.StatusCode, string(respBody))
	}
	return respBody, nil
}
