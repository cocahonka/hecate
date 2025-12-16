#!/bin/bash
set -e

echo "=========================================="
echo "Running all service tests with coverage"
echo "=========================================="
echo

echo "📦 USER SERVICE"
cd user_service
go test -cover ./internal/service/... 2>&1 | grep -E "PASS|FAIL|coverage"
echo

echo "📦 CHAT SERVICE"
cd ../chat_service
go test -cover ./internal/service/... 2>&1 | grep -E "PASS|FAIL|coverage"
echo

echo "📦 MESSAGE SERVICE"
cd ../message_service
go test -cover ./internal/service/... 2>&1 | grep -E "PASS|FAIL|coverage"
echo

echo "=========================================="
echo "✅ All tests completed successfully!"
echo "=========================================="
