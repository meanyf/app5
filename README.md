# Платформа локальных событий и встреч

Мобильное приложение с картой событий и микросервисным бэкендом на FastAPI. Пользователи публикуют активности, подают заявки на встречи, оставляют комментарии и получают push-уведомления.

Два типа активностей:

- **Событие (`event`)** — публикация о происходящем рядом с описанием, координатами, временем и медиа.
- **Встреча (`meeting`)** — активность с заявками на участие и их одобрением или отклонением.

Клиент написан на Flutter и использует Яндекс Карты.

## Стек

- **Бэкенд:** Python 3.11, FastAPI, Pydantic, SQLAlchemy, Alembic.
- **Данные:** PostgreSQL, PostGIS, Redis.
- **Обмен сообщениями:** Apache Kafka, aiokafka.
- **Медиа:** MinIO.
- **Интеграции:** SMS.ru, Firebase Cloud Messaging.
- **Инфраструктура:** Docker Compose, Prometheus, Grafana.
- **Мобильное приложение:** Flutter, Dart, Yandex MapKit.

## API

Базовый адрес при локальном запуске: `http://localhost:8080`.

Запросы к прикладным эндпоинтам, кроме отправки и проверки OTP, требуют заголовка:

```http
Authorization: Bearer <access_token>
```

API Gateway проверяет JWT и передаёт идентификатор пользователя внутренним сервисам. Тела запросов — JSON, кроме загрузки файлов.

### Аутентификация

| Метод | Эндпоинт | Назначение |
| --- | --- | --- |
| POST | `/auth/send-otp` | Отправить SMS-код |
| POST | `/auth/verify-otp` | Проверить код и получить access-токен |

Отправка кода:

```json
{"phone": "79001234567"}
```

Проверка кода:

```json
{"phone": "79001234567", "code": "123456"}
```

Ответ при успешной проверке:

```json
{"access_token": "<jwt>", "token_type": "bearer"}
```

При первом входе пользователь регистрируется автоматически. OTP хранится в Redis с TTL и удаляется после успешной проверки. Отправка кода использует реальный API SMS.ru.

### Профили пользователей

| Метод | Эндпоинт | Назначение |
| --- | --- | --- |
| GET | `/users/me` | Получить свой профиль; создать, если его ещё нет |
| PATCH | `/users/me` | Обновить имя, описание, аватар или FCM-токен |
| GET | `/users/{user_id}` | Получить профиль по ID |
| POST | `/users/batch` | Получить несколько профилей: `{"ids": ["<user_id>"]}` |

Пример обновления профиля:

```json
{"name": "Амир", "description": "Ищу компанию для прогулок"}
```

При обновлении профиля передайте `description`; допускается значение `null`.

### События и встречи

| Метод | Эндпоинт | Назначение |
| --- | --- | --- |
| POST | `/activities/` | Создать активность |
| GET | `/activities/` | Получить опубликованные активности |
| GET | `/activities/{activity_id}` | Получить активность по ID |
| PATCH | `/activities/{activity_id}` | Обновить активность |
| DELETE | `/activities/{activity_id}` | Удалить активность |

Список поддерживает фильтры `creator_id` и `activity_type` (`event` или `meeting`), например: `/activities/?activity_type=meeting`.

Пример создания встречи:

```json
{
  "type": "meeting",
  "title": "Прогулка в парке",
  "description": "Собираем компанию на вечернюю прогулку",
  "latitude": 55.7298,
  "longitude": 37.6011,
  "address": "Москва, Парк Горького",
  "starts_at": "2026-10-01T15:00:00Z",
  "expires_at": "2026-10-01T18:00:00Z",
  "max_participants": 5,
  "media": []
}
```

Создание возвращает `201` и объект активности. Для прикрепления медиа сначала загрузите файл через `/media/upload`, затем передайте его `url` и `type` в массиве `media`.

Координаты хранятся как географическая точка PostGIS. Даты с часовым поясом приводятся к UTC. При обновлении координат `latitude` и `longitude` передаются вместе.

Активности имеют статусы `pending`, `published` и `rejected`. Список возвращает опубликованные активности, а обработчик событий `activity.moderated` обновляет статус по результату модерации.

### Заявки на встречи

| Метод | Эндпоинт | Назначение |
| --- | --- | --- |
| POST | `/meetings/` | Подать заявку: `{"activity_id": "<activity_id>"}` |
| GET | `/meetings/my` | Получить свои заявки |
| GET | `/meetings/activity/{activity_id}` | Получить заявки на активность |
| PATCH | `/meetings/{request_id}` | Изменить статус заявки |

Новая заявка имеет статус `pending`. Для изменения передаётся `{"status": "approved"}` или `{"status": "rejected"}`. При создании заявки сервис публикует событие в Kafka для уведомления организатора.

### Комментарии

| Метод | Эндпоинт | Назначение |
| --- | --- | --- |
| GET | `/comments/{activity_id}` | Получить комментарии активности |
| POST | `/comments/{activity_id}` | Добавить комментарий: `{"text": "Где встречаемся?"}` |
| DELETE | `/comments/{comment_id}` | Удалить свой комментарий |

Для WebSocket-подключения к `chat-service` используется адрес `ws://localhost:8001/comments/ws/{activity_id}` с заголовком `x-user-id`.

### Загрузка медиа

**POST `/media/upload`** — загрузить файл через `multipart/form-data`, поле `file`.

- Фото: `.jpg`, `.jpeg`, `.png`, `.webp`, до 10 МБ.
- Видео: `.mp4`, `.mov`, `.avi`, до 100 МБ.

Ответ содержит `url`, `type` (`photo` или `video`) и `file_name`. Файл сохраняется в MinIO; при загрузке видео публикуется событие `media.video.uploaded`.

## Детали реализации

### Микросервисы

| Сервис | Ответственность | Хранилище |
| --- | --- | --- |
| `api-gateway` | Проверка JWT и HTTP-проксирование | — |
| `auth-service` | SMS-коды, регистрация и выдача JWT | PostgreSQL, Redis |
| `user-service` | Профили и FCM-токены | PostgreSQL |
| `activity-service` | Активности и заявки на встречи | PostgreSQL / PostGIS |
| `chat-service` | Комментарии и WebSocket-обработчики | PostgreSQL |
| `media-service` | Загрузка фото и видео | MinIO |
| `notification-service` | Обработка событий Kafka и отправка push | Получает профиль через HTTP |

У сервисов авторизации, пользователей, активностей и чата отдельные базы данных и миграции Alembic. Для запросов к БД используется асинхронный SQLAlchemy.

Сервисы взаимодействуют через HTTP и Kafka. Например, после создания заявки `notification-service` получает событие, запрашивает FCM-токен организатора у `user-service` и отправляет уведомление через Firebase.

### События Kafka

| Топик | Назначение | Данные |
| --- | --- | --- |
| `meeting_request_created` | Уведомление организатора о новой заявке | ID активности, организатора и заявителя |
| `media.video.uploaded` | Событие загрузки видео в MinIO | Имя файла и URL |
| `activity.moderated` | Обновление статуса активности | ID активности и статус `published` или `rejected` |

Kafka запускается в режиме KRaft. Обработчик результатов модерации работает в фоновой задаче `asyncio`, сервис уведомлений — отдельным процессом.

## Структура

```text
app5/
├── mobile/                     # Flutter-приложение
│   ├── lib/                    # Карта, лента, профили, активности и чат
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── services/
│   ├── api-gateway/
│   ├── auth-service/
│   ├── user-service/
│   ├── activity-service/
│   ├── chat-service/
│   ├── media-service/
│   ├── notification-service/
│   ├── moderation-service/
│   └── video-worker/
├── infra/
│   ├── prometheus/
│   ├── grafana/
│   └── kafka/
├── docker-compose.yml
├── .env.example
└── README.md
```

Внутри сервисов код разделён на маршруты (`routers`), схемы (`schemas`), модели (`models`), бизнес-логику (`services`) и работу с БД (`db`). Обработчики Kafka находятся в `kafka`, миграции — в `alembic`.

## Запуск через Docker

### 1. Настройка окружения

Нужны Docker с поддержкой Docker Compose и учётные данные SMS.ru. Для push-уведомлений нужен Firebase-проект и JSON-ключ сервисного аккаунта.

Для первого запуска скопируйте [.env.example](.env.example) в `.env`:

```bash
cp .env.example .env
```

Проверьте настройки:

| Переменная | Значение для вашего окружения |
| --- | --- |
| `JWT_SECRET` | Общий секрет для `auth-service` и `api-gateway` |
| `SMS_RU_API_ID` | Ваш ключ SMS.ru |
| `AUTH_DATABASE_URL`, `ACTIVITY_DATABASE_URL`, `CHAT_DATABASE_URL`, `USER_DATABASE_URL` | Подключения к БД из Docker Compose |
| `REDIS_URL` | `redis://redis-app:6379/0` |
| `KAFKA_BOOTSTRAP_SERVERS` | `kafka:9092` |
| `MINIO_ENDPOINT` | `minio:9000` — адрес внутри Docker |
| `MINIO_PUBLIC_URL` | Адрес MinIO, доступный клиенту: `http://localhost:9000` для ПК или `http://<IP-компьютера>:9000` для телефона |
| `FIREBASE_CREDENTIALS_PATH` | `/app/firebase-credentials.json` — путь внутри контейнера |

Для уведомлений разместите свой JSON-ключ Firebase в `infra/firebase-credentials.json`: Compose монтирует его в контейнер. Значения адресов и ключей из примера необходимо адаптировать под своё окружение.

### 2. Сборка и запуск

Из корня проекта:

```bash
docker compose up --build -d
```

### 3. Миграции

После запуска контейнеров примените миграции к четырём базам данных:

```bash
docker compose exec auth-service alembic upgrade head
docker compose exec user-service alembic upgrade head
docker compose exec activity-service alembic upgrade head
docker compose exec chat-service alembic upgrade head
```

### 4. Проверка и логи

```bash
docker compose ps
docker compose logs -f api-gateway activity-service notification-service
```

Проверка шлюза: `GET http://localhost:8080/ping` возвращает `{"status": "ok"}`.

| Компонент | Локальный адрес |
| --- | --- |
| API Gateway | http://localhost:8080 |
| Swagger: активности и заявки | http://localhost:8000/docs |
| Swagger: комментарии | http://localhost:8001/docs |
| Swagger: медиа | http://localhost:8002/docs |
| Swagger: авторизация | http://localhost:8003/docs |
| Swagger: пользователи | http://localhost:8004/docs |
| MinIO Console | http://localhost:9001 |
| Prometheus | http://localhost:9090 |
| Grafana | http://localhost:3000 |

Swagger шлюза показывает маршруты проксирования, а схемы тел запросов доступны в Swagger отдельных сервисов. При прямом обращении к сервисам маршруты с идентификацией пользователя требуют заголовок `x-user-id`.

Prometheus настроен на сбор метрик API Gateway. В Grafana добавьте источник Prometheus с адресом `http://prometheus:9090` и импортируйте нужные JSON-дашборды из `infra/grafana/dashboards/`.

Остановка контейнеров:

```bash
docker compose down
```

### Мобильное приложение

Для клиента нужны Flutter, Android SDK или окружение сборки iOS, а также настройки Firebase и Yandex MapKit для выбранной платформы.

Укажите адрес шлюза в `mobile/lib/core/api_client.dart` (`baseUrl`). Для телефона используйте IP компьютера в локальной сети; адрес `MINIO_PUBLIC_URL` тоже должен быть доступен устройству. Настройте ключ Yandex MapKit и конфигурацию Firebase для своего приложения.

```bash
cd mobile
flutter pub get
flutter run
```
