package domain

import "errors"

var CacheKeyPrefix = "register:challenge"

var ErrNicknameIsNotUnique = errors.New("nickname is not unique")
