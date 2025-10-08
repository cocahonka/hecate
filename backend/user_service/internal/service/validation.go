package service

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/x509"
	"encoding/pem"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
)

// validateECCP256Key validates that the given key is a valid ECP 256 key in PEM format
func validateECCP256Key(keyPEM string) error {
	if keyPEM == "" {
		return domain.ErrInvalidPublicKey
	}

	// Decode PEM block
	block, _ := pem.Decode([]byte(keyPEM))
	if block == nil {
		return domain.ErrInvalidPublicKey
	}

	// Parse the public key
	publicKey, err := x509.ParsePKIXPublicKey(block.Bytes)
	if err != nil {
		return domain.ErrInvalidPublicKey
	}

	// Check if it's an ECDSA key
	ecdsaKey, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		return domain.ErrFailedToConvertToECDSA
	}

	// Check if it's P-256 curve (secp256r1)
	if ecdsaKey.Curve != elliptic.P256() {
		return domain.ErrInvalidKeyType
	}

	return nil
}

// validate9cAnd9dKeys validates both 9c and 9d keys
func validate9cAnd9dKeys(pub9c, pub9d string) error {
	if err := validateECCP256Key(pub9c); err != nil {
		return err
	}
	if err := validateECCP256Key(pub9d); err != nil {
		return err
	}
	return nil
}