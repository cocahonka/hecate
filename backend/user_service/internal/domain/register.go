package domain

import "errors"

var CacheKeyPrefix = "register:challenge"
var RefreshTokenKeyPrefix = "refresh_token"

var ErrNicknameIsNotUnique = errors.New("nickname is not unique")
