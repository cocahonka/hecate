package domain

import "errors"

var (
	ErrChatNotFound      = errors.New("chat not found")
	ErrChatAlreadyExists = errors.New("chat already exists")
	ErrUserNotMember     = errors.New("user is not a member of this chat")
)
