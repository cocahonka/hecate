package service

import (
	"crypto/ecdsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
)

// verifySignature verifies an ES256 signature produced by the PIV device.
//
// Both challenge and signature are expected to be base64url-encoded strings
// without padding, matching the format used by the PIV bindings and the
// user_service API. The function decodes them and verifies the ASN.1 DER
// ECDSA signature against the decoded challenge bytes.
func verifySignature(publicKeyPem []byte, challengeBase64url, signatureBase64url string) (bool, error) {
	block, _ := pem.Decode(publicKeyPem)
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

	challengeBytes, err := base64.RawURLEncoding.DecodeString(challengeBase64url)
	if err != nil {
		return false, err
	}

	signatureBytes, err := base64.RawURLEncoding.DecodeString(signatureBase64url)
	if err != nil {
		return false, err
	}

	hash := sha256.Sum256(challengeBytes)
	return ecdsa.VerifyASN1(ecdsaKey, hash[:], signatureBytes), nil
}
