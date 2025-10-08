package domain

import "errors"

var ErrInvalidSignature = errors.New("invalid signature")
var ErrFailedToConvertToECDSA = errors.New("failed to convert to ECDSA public key")
var ErrInvalidPublicKey = errors.New("invalid public key")
var ErrInvalidKeyType = errors.New("invalid key type, expected ECP 256")