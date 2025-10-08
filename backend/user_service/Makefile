gen_swagger:
	rm -rf ./docs
	swag init -g cmd/main.go -o docs/

gen_mocks:
	rm -rf ./service/mocks
	mockery
