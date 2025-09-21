package logger

import (
	"fmt"

	"github.com/cocahonka/hecate/backend/user_service/internal/domain"
	"go.uber.org/zap"
)

func MustLoad(Enviroment string) *zap.Logger {
	var (
		logger *zap.Logger
		err    error
	)
	switch Enviroment {
	case domain.EnvProduction:
		logger, err = zap.NewProduction()
	case domain.EnvDevelopment:
		logger, err = zap.NewDevelopment()
	default:
		err = fmt.Errorf(`unknown enviroment: %s. Use "production" or "development"`, Enviroment)
	}
	if err != nil {
		panic(err)
	}
	return logger
}
