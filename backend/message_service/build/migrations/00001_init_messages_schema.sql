CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL,
    sender_id UUID NOT NULL,
    encrypted_payload TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Индекс для быстрого поиска истории чата
CREATE INDEX idx_messages_chat_created ON messages(chat_id, created_at DESC);
