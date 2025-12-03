API gateway
Маршрутизирует запросы 
между микросервисами,
проверяет JWT токен

---

User service
/register/init - пользователь отправляет на сервер 
свой никнейм. Сервер генерирует challenge, сохраняет
в кеше пару никнейм/challenge и отдает challenge
клиенту
/register/verify - клиент подписывает challenge 
приватным ключом и отправляет на сервер никнейм,
публичный ключ и подписанный challenge. Сервер 
верифицирует подпись и если она валидна, сохраняет
в БД никнейм и публичный ключ пользователя

/login/init - пользователь отправляет на сервер 
юзернейм. Сервер генерирует challenge, сохраняет
пару юзернейм/челендж с ttl и отправляет 
challenge клиенту
/login/verify - пользователь отправляет
подписанный challenge и никнейм. Сервер получает
по никнейму публичный ключ из БД, оригинальный
challenge из кеша и проверяет подпись. Если она
валидна, клиенту отправляется JWT токен

/key/public/get(user int) - получение публичного
ключа пользователя
/jwt/public/get - отдает публичный ключ для валидации jwt

---

Chat service
/is_exists(user1, user2 int) - проверяет, был ли
ранее создан чат между пользователями
/create(user1, user2 int, enc_aes1, enc_aes2 string) -
создается чат между двумя участниками, в БД 
сохраняются айди участников и зашифрованные aes
ключи
/aes/get(chatID, userID int) - получение зашифрован-
ного aes ключа на клиенте для расшифровки сообщений
/is-participant(userID, chatID int) - проверяет что
пользователь является участником чата
/all(userID int) - получение всех чатов пользователя

---

Message service

/send(senderID, chatID int, encPayload string) - 
сохраняет сообщение в БД и отправялет в кафку для
передачи через вебсокет

/history/get(userID, chatID, limit, offset int) - получаем
историю сообщений

---

Delivery service

/connect(websocket) - устанавливает вебсокет
соединение с чатом для мгновенной доставки сообщений

/disconnect(userID int) - разрывает вебсокет
соединение и очищает ресурсы

---

Message service -> KAFKA (pub message.{chatID})
KAFKA -> Delivery service (sub message.{chatID})

---

POSTGRES

Users
id int
nickname string
public_key string

Chats
id int
participantID int
encrypted_aes string

Messages
id int
chatID int
senderID int
encrypted_payload string
timestamp time
