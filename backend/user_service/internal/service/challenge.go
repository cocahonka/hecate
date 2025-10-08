package service

import (
	"crypto/rand"
	"encoding/base64"
)

func generateChallenge() string {
	challenge := make([]byte, 32)
	rand.Read(challenge)
	return base64.RawURLEncoding.EncodeToString(challenge)
}
