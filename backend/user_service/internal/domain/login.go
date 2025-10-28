package domain

import "errors"

var ErrUserNotFound = errors.New("user not found")
var ErrInvalidRefreshToken = errors.New("invalid refresh token")
var ErrRefreshTokenExpired = errors.New("refresh token expired")
var ErrRefreshTokenMismatch = errors.New("refresh token mismatch")
