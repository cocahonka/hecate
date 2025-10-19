package domain

import "github.com/google/uuid"

// User represents a user in the system.
// It holds all the necessary information about a user.
type User struct {
	ID       uuid.UUID `db:"id"`
	Nickname string    `db:"nickname"`
	Pub9c    string    `db:"pub9c"`
	Pub9d    string    `db:"pub9d"`
}
