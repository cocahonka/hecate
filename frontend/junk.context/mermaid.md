---
config:
  theme: mc
---
sequenceDiagram
  participant C as Клиент
  participant Y as YubiKey
  participant US as User Service
  participant CS as Chat Service
  participant MS as Message Service
  participant DS as Delivery Service
  participant DB as PostgreSQL
  participant K as Kafka
  participant WS as WebSocket
  participant CH as Cache
  Note over C, Y: 1. Инициализация при первом запуске
  C ->> Y: Генерация ключей в слотах 9c и 9d
  Y -->> C: Ключи сгенерированы
  Note over C, DB: 2. Регистрация пользователя
  C ->> US: POST /register/init (nickname)
  US ->> US: Генерация challenge
  US ->> CH: Сохранение nickname/challenge в кеш (TTL)
  US -->> C: challenge
  C ->> Y: Подпись challenge приватным ключом 9c
  Y -->> C: signed_challenge
  C ->> US: POST /register/verify (signed_challenge, nickname, public_key_9c, public_key_9d)
  US ->> US: Проверка подписи
  US ->> CH: Очистка challenge из кеша
  US ->> DB: Сохранение public_key + nickname
  US -->> C: Регистрация успешна
  Note over C, DB: 3. Авторизация
  C ->> US: POST /login/init (nickname)
  US ->> US: Генерация challenge
  US ->> CH: Сохранение challenge в кеш (TTL)
  US -->> C: challenge
  C ->> Y: Подпись challenge приватным ключом 9c
  Y -->> C: signed_challenge
  C ->> US: POST /login/verify (signed_challenge, nickname)
  US ->> US: Проверка подписи
  US ->> CH: Очистка challenge из кеша
  US -->> C: JWT токен
  Note over C, CS: 4. Получение списка чатов
  C ->> CS: GET /chats (JWT)
  CS ->> DB: Запрос чатов пользователя
  CS -->> C: Список чатов
  Note over C, CS: 5. Создание нового чата
  C ->> CS: POST /check-chat (user1_id, user2_id, JWT)
  CS ->> DB: Проверка существования общего чата
  CS -->> C: false (чат не существует)
  C ->> US: GET /user/public-key (user2_id, JWT)
  US ->> DB: Получение публичного ключа user2
  US -->> C: public_key_user2
  C ->> C: Генерация AES ключа
  C ->> C: Шифрование AES ключа своим публичным ключом (9d)
  Y -->> C: enc_aes1
  C ->> C: Шифрование AES ключа публичным ключом user2
  C -->> C: enc_aes2
  C ->> CS: POST /create (user1_id, user2_id, enc_aes1, enc_aes2, JWT)
  CS ->> DB: Создание записей для обоих участников
  CS -->> C: chatID
  Note over C, MS: 6. Получение истории чата
  C ->> MS: GET /history (userID, chatID, limit, offset, JWT)
  MS ->> CS: Проверка участия пользователя в чате
  CS ->> DB: Проверка участия
  CS -->> MS: true
  MS ->> DB: Получение последних n сообщений
  MS -->> C: Зашифрованные сообщения
  C ->> CS: GET /aes-key (chatID, userID, JWT)
  CS ->> DB: Получение enc_aes
  CS -->> C: enc_aes
  C ->> Y: Расшифровка AES ключа приватным ключом 9d
  Y -->> C: aes_key
  C ->> C: Расшифровка всех сообщений AES ключом
  Note over C, WS: 7. Установка WebSocket соединения
  C ->> DS: WebSocket подключение (chatID, JWT)
  DS ->> K: Подписка на топик message.{chatID}
  DS -->> C: WebSocket соединение установлено
  Note over C, K: 8. Отправка сообщения
  C ->> CS: GET /aes-key (chatID, userID, JWT)
  CS -->> C: enc_aes
  C ->> Y: Расшифровка AES ключа
  Y -->> C: aes_key
  C ->> C: Шифрование сообщения AES ключом
  C ->> MS: POST /send (userID, chatID, encrypted_payload, JWT)
  MS ->> CS: Проверка участия в чате
  CS -->> MS: true
  MS ->> DB: Сохранение сообщения
  MS ->> K: Публикация в топик message.{chatID}
  MS -->> C: Сообщение отправлено
  Note over DS, WS: 9. Доставка сообщений
  K -->> DS: Новое сообщение из топика
  DS ->> WS: Push сообщения через WebSocket
  WS -->> C: Получение нового сообщения
  C ->> C: Идемпотентная обработка (избежание дублей)
