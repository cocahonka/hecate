package service

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"testing"

	"github.com/cocahonka/hecate/backend/user_service/internal/service/mocks"
	"github.com/stretchr/testify/require"
)

// generateValidECP256Key generates a valid ECP 256 public key in PEM format for testing
func generateValidECP256Key(t *testing.T) string {
	t.Helper()

	privateKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	require.NoError(t, err)

	publicKeyDER, err := x509.MarshalPKIXPublicKey(&privateKey.PublicKey)
	require.NoError(t, err)

	publicKeyBlock := &pem.Block{
		Type:  "PUBLIC KEY",
		Bytes: publicKeyDER,
	}

	return string(pem.EncodeToMemory(publicKeyBlock))
}

// generateValidRSAKey generates a valid RSA public key in PEM format for testing
func generateValidRSAKey(t *testing.T) string {
	t.Helper()

	privateKey, err := rsa.GenerateKey(rand.Reader, 2048)
	require.NoError(t, err)

	publicKeyDER, err := x509.MarshalPKIXPublicKey(&privateKey.PublicKey)
	require.NoError(t, err)

	publicKeyBlock := &pem.Block{
		Type:  "PUBLIC KEY",
		Bytes: publicKeyDER,
	}

	return string(pem.EncodeToMemory(publicKeyBlock))
}

// generateTestKeyPair generates a pair of valid ECP 256 keys for testing
func generateTestKeyPair(t *testing.T) (pub9c, pub9d string) {
	t.Helper()

	pub9c = generateValidECP256Key(t)
	pub9d = generateValidECP256Key(t)

	return pub9c, pub9d
}

// generateKeyPairAndSignature generates a key pair and signature for testing
func generateKeyPairAndSignature(t *testing.T, challenge string) (pubKeyPEM, signature string, privateKey *ecdsa.PrivateKey) {
	t.Helper()

	// Generate private key
	privateKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	require.NoError(t, err)

	// Generate public key PEM
	publicKeyDER, err := x509.MarshalPKIXPublicKey(&privateKey.PublicKey)
	require.NoError(t, err)

	publicKeyBlock := &pem.Block{
		Type:  "PUBLIC KEY",
		Bytes: publicKeyDER,
	}
	pubKeyPEM = string(pem.EncodeToMemory(publicKeyBlock))

	// Sign challenge
	hash := sha256.Sum256([]byte(challenge))
	sig, err := ecdsa.SignASN1(rand.Reader, privateKey, hash[:])
	require.NoError(t, err)

	signature = base64.RawURLEncoding.EncodeToString(sig)

	return pubKeyPEM, signature, privateKey
}

// generateInvalidSignatureForKey generates an invalid signature for a given key
func generateInvalidSignatureForKey(t *testing.T, challenge string) string {
	t.Helper()

	// Generate a different key and sign with it
	_, wrongSig, _ := generateKeyPairAndSignature(t, challenge)
	return wrongSig
}

// setupTestMocks creates mock objects for testing
func setupTestMocks(t *testing.T) (*mocks.MocknicknameChecker, *mocks.MockchallengeManager, *mocks.MockUserSaver) {
	t.Helper()

	mockChecker := mocks.NewMocknicknameChecker(t)
	mockManager := mocks.NewMockchallengeManager(t)
	mockUserSaver := mocks.NewMockUserSaver(t)

	return mockChecker, mockManager, mockUserSaver
}

// setupTestMocksForRegister creates mock objects for register service testing
func setupTestMocksForRegister(t *testing.T) (*mocks.MockUserProvider, *mocks.MockchallengeManager, *mocks.MockUserSaver) {
	t.Helper()

	mockUserProvider := mocks.NewMockUserProvider(t)
	mockManager := mocks.NewMockchallengeManager(t)
	mockUserSaver := mocks.NewMockUserSaver(t)

	return mockUserProvider, mockManager, mockUserSaver
}
