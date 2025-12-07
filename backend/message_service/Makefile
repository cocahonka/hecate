build:
	go build -o bin/message-service cmd/main.go

run:
	go run cmd/main.go

test:
	go test -v ./...

gen_swagger:
	rm -rf ./docs
	swag init -g cmd/main.go -o docs/

gen_mocks:
	rm -rf ./internal/repository/mocks
	mockery --name MessageRepository --dir internal/repository --output internal/repository/mocks --outpkg mocks --with-expecter
