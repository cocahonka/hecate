build:
	go build -o bin/chat-service cmd/main.go

run:
	go run cmd/main.go

test:
	go test -v ./...

gen_swagger:
	rm -rf ./docs
	swag init -g cmd/main.go -o docs/

gen_mocks:
	# Note: Requires mockery v2.x
	rm -rf ./internal/repository/mocks
	mockery --name ChatRepository --dir internal/repository --output internal/repository/mocks --outpkg mocks --with-expecter
	mockery --name ChatMemberRepository --dir internal/repository --output internal/repository/mocks --outpkg mocks --with-expecter