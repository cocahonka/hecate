# Chat Service

Service for managing 1-to-1 zero-knowledge chats.

## Tech Stack
- Go 1.24
- Gin Web Framework
- PostgreSQL (Storage)
- Redis (Cache/Optional)
- Zap Logger

## Features
- Create 1-to-1 chats with E2EE key exchange.
- Check membership.
- Retrieve encrypted keys.

## API Documentation
Swagger documentation is generated in `docs/`. 
Run `make gen_swagger` to regenerate.

## Usage

### Build
```bash
make build
```

### Run
```bash
make run
```

### Test
```bash
make test
```

## Configuration
See `.example.env` for environment variables.
