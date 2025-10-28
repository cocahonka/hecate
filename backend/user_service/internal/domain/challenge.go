package domain

import "errors"

var ErrChallengeNotFound = errors.New("challenge not found")
var ErrRefreshTokenNotFound = errors.New("refresh token not found")
