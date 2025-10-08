package service

import (
	"testing"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"github.com/stretchr/testify/assert"
)

func TestValidateECCP256Key(t *testing.T) {
	tests := []struct {
		name    string
		keyPEM  func() string
		wantErr error
	}{
		{
			name:    "empty key",
			keyPEM:  func() string { return "" },
			wantErr: domain.ErrInvalidPublicKey,
		},
		{
			name:    "invalid PEM format",
			keyPEM:  func() string { return "invalid-pem-data" },
			wantErr: domain.ErrInvalidPublicKey,
		},
		{
			name:    "valid ECP256 public key",
			keyPEM:  func() string { return generateValidECP256Key(t) },
			wantErr: nil,
		},
		{
			name:    "RSA key (should fail)",
			keyPEM:  func() string { return generateValidRSAKey(t) },
			wantErr: domain.ErrFailedToConvertToECDSA,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := validateECCP256Key(tt.keyPEM())
			if tt.wantErr != nil {
				assert.Error(t, err)
				assert.Equal(t, tt.wantErr, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestValidate9cAnd9dKeys(t *testing.T) {
	validKey1 := generateValidECP256Key(t)
	validKey2 := generateValidECP256Key(t)
	invalidKey := "invalid-key"

	tests := []struct {
		name    string
		pub9c   string
		pub9d   string
		wantErr error
	}{
		{
			name:    "both keys valid",
			pub9c:   validKey1,
			pub9d:   validKey2,
			wantErr: nil,
		},
		{
			name:    "9c invalid",
			pub9c:   invalidKey,
			pub9d:   validKey1,
			wantErr: domain.ErrInvalidPublicKey,
		},
		{
			name:    "9d invalid",
			pub9c:   validKey1,
			pub9d:   invalidKey,
			wantErr: domain.ErrInvalidPublicKey,
		},
		{
			name:    "both keys invalid",
			pub9c:   invalidKey,
			pub9d:   invalidKey,
			wantErr: domain.ErrInvalidPublicKey,
		},
		{
			name:    "9c empty (required)",
			pub9c:   "",
			pub9d:   validKey1,
			wantErr: domain.ErrInvalidPublicKey,
		},
		{
			name:    "9d empty (required)",
			pub9c:   validKey1,
			pub9d:   "",
			wantErr: domain.ErrInvalidPublicKey,
		},
		{
			name:    "both keys empty",
			pub9c:   "",
			pub9d:   "",
			wantErr: domain.ErrInvalidPublicKey,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := validate9cAnd9dKeys(tt.pub9c, tt.pub9d)
			if tt.wantErr != nil {
				assert.Error(t, err)
				assert.Equal(t, tt.wantErr, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}
