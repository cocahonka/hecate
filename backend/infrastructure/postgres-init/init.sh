#!/bin/bash
set -e

# Create databases
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL
    CREATE DATABASE user_service;
    CREATE DATABASE chat_service;
EOSQL

# Init User Service DB
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "user_service" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    CREATE TABLE IF NOT EXISTS users (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       nickname VARCHAR(50) UNIQUE NOT NULL,
       pubkey_auth TEXT NOT NULL,
       pubkey_enc TEXT NOT NULL,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
EOSQL

# Init Chat Service DB
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "chat_service" <<-EOSQL
    CREATE TABLE chats (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        created_at TIMESTAMP NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    CREATE TABLE chat_members (
        chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
        user_id UUID NOT NULL,
        encrypted_key TEXT NOT NULL,
        joined_at TIMESTAMP NOT NULL DEFAULT NOW(),
        PRIMARY KEY (chat_id, user_id)
    );

    CREATE INDEX idx_chat_members_user_id ON chat_members(user_id);
EOSQL
