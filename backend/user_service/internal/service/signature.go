package service

import (
	"crypto/ecdsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/pem"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
)

func verifySignature(publicKeyPem, challenge, signature []byte) (bool, error) {
	block, _ := pem.Decode([]byte(publicKeyPem))
	if block == nil {
		return false, domain.ErrInvalidPublicKey
	}
	publicKey, err := x509.ParsePKIXPublicKey(block.Bytes)
	if err != nil {
		return false, err
	}
	ecdsaKey, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		return false, domain.ErrFailedToConvertToECDSA
	}

	hash := sha256.Sum256(challenge)
	return ecdsa.VerifyASN1(ecdsaKey, hash[:], signature), nil
}
