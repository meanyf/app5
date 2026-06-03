# Первый запуск (сборка)
docker compose up --build

docker compose up media-service activity-service chat-service auth-service api-gateway user-service

docker compose up api-gateway prometheus grafana kafka postgres-activity activity-service

docker compose up --build api-gateway activity-service postgres-activity prometheus grafana

docker compose up --no-deps api-gateway activity-service postgres-activity kafka prometheus grafana

# Обычный запуск после изменений
docker compose up -d && docker compose logs -f media-service activity-service chat-service auth-service api-gateway user-service

docker compose up -d
docker compose logs -f media-service activity-service chat-service auth-service

docker compose exec chat-service alembic upgrade head
docker compose exec activity-service alembic revision --autogenerate -m "creator_id to string"

docker compose exec postgres-activity psql -U postgres -d activity_db -c "UPDATE activities SET status = 'published';"

flutter run 2>&1 | grep -E "flutter|ERROR|EXCEPTION|Error|dart"

docker exec -it postgres-chat psql -U postgres -d chat_db -c "SELECT * FROM comments LIMIT 5;"


docker compose down
## Мобильное приложение для быстрого обмена событиями и встречами
Общая идея
Мобильное приложение объединяет карту локальных событий и инструмент для организации встреч между людьми. Основная идея — дать пользователям возможность видеть, что происходит вокруг, и находить людей для совместных действий, общения и решения задач.
Приложение ориентировано на локальное взаимодействие: всё, что происходит на карте, привязано к реальному месту и времени. Пользователь открывает приложение и сразу видит актуальную картину вокруг себя — как публичные активности, так и возможности для личного участия.

Ключевые сущности
Приложение строится вокруг двух типов активностей: событий и встреч.
События — это публичные пользовательские метки на карте, отражающие происходящее в реальном мире. Это могут быть уличные выступления, локальные активности, интересные места или любые другие ситуации, которые пользователь хочет показать окружающим. Событие открыто для всех: любой желающий может его увидеть, посмотреть детали и оставить комментарий.
Встречи — это активности, ориентированные на взаимодействие между конкретными людьми. Они также отображаются на карте и в ленте, однако предполагают участие ограниченного числа людей. Для участия во встрече пользователь подаёт заявку, после чего организатор принимает или отклоняет её. Встречи позволяют объединяться вокруг общего интереса или конкретной цели и взаимодействовать в небольших группах.
Оба типа активностей отображаются на карте и в ленте, имеют единую базовую структуру и управляются схожей логикой, что позволяет объединить их в одну доменную сущность — активность — с признаком типа.

Структура активности
Каждая активность включает:

заголовок и описание
медиафайлы (фото или видео)
адрес и геометку на карте
время начала и продолжительность
максимальное число участников (для встреч)
чат: открытые комментарии для событий, групповой чат участников для встреч


## Техническая архитектура
Общая структура
Приложение построено на микросервисной архитектуре. Каждый сервис инкапсулирует свою зону ответственности, имеет собственную базу данных и взаимодействует с остальными сервисами асинхронно через брокер сообщений Kafka. Синхронное взаимодействие между сервисами не используется — это исключает прямую связанность и повышает отказоустойчивость системы.
Все сервисы развёртываются в контейнерах через Docker Compose на одной машине.

Клиентское приложение
Мобильное приложение разработано на Flutter, что обеспечивает единую кодовую базу для iOS и Android. Карта реализована через Яндекс Карты SDK. Приложение взаимодействует исключительно с API Gateway — прямого доступа к отдельным сервисам у клиента нет.

Сетевой слой
Nginx
Выступает как reverse proxy — единая точка входа для всех входящих HTTP-запросов. Принимает запросы от клиента и перенаправляет их на API Gateway. Обеспечивает терминацию TLS.
API Gateway
Отдельный сервис на FastAPI. Отвечает за:

маршрутизацию запросов к нужным микросервисам
валидацию JWT-токенов
rate limiting — ограничение числа создаваемых активностей в день на пользователя


Микросервисы
Все сервисы написаны на FastAPI (Python).
auth-service
Авторизация по номеру телефона. Генерирует и отправляет OTP-код через СМС.ру, проверяет его, выдаёт JWT access-токен и refresh-токен. OTP-коды хранятся в Redis с TTL. Refresh-токены и номера телефонов хранятся в auth-db.
user-service
Управление профилями пользователей. Хранит данные в users-db.
activity-service
Центральный сервис. Управляет событиями и встречами:

создание, редактирование, удаление активностей
геопоиск через PostGIS — поиск активностей в заданном радиусе
управление статусами (на модерации / опубликовано / завершено)
TTL логика — автоматическое снятие активности по истечении времени, возможность продления
приём и обработка заявок на участие во встречах

Хранит данные в activities-db.
media-service
Принимает загружаемые файлы (фото и видео), сохраняет их в MinIO. При получении видео публикует задачу в Kafka для асинхронной обработки. Возвращает клиенту ссылку на файл.
video-worker
Отдельный воркер, подписанный на Kafka-топик с задачами на обработку видео. Использует FFmpeg для сжатия видео и генерации превью (thumbnail). После обработки обновляет ссылку на файл в MinIO.
moderation-service
Подписан на Kafka-топик с новыми активностями. Проверяет текстовое содержимое и медиафайлы. После проверки публикует результат в Kafka — activity-service меняет статус активности на «опубликовано» или «отклонено».
chat-service
Обеспечивает два типа коммуникации:

комментарии к событиям — открыты для всех пользователей
групповой чат встречи — доступен только принятым участникам

Хранит сообщения в chat-db. Real-time доставка сообщений — через WebSocket.
notification-service
Подписан на Kafka-топики: публикация новой активности, принятие/отклонение заявки на встречу, новые сообщения в чате. Отправляет push-уведомления через FCM. Геозонная логика: при появлении новой активности определяет пользователей в фиксированном радиусе и рассылает им уведомление.

Брокер сообщений
Kafka в режиме KRaft
Основные топики:
Топик	Производитель	Потребитель
activity.created	activity-service	moderation-service, notification-service
activity.moderated	moderation-service	activity-service
media.video.uploaded	media-service	video-worker
meeting.request.updated	activity-service	notification-service
chat.message.sent	chat-service	notification-service
Для визуального мониторинга топиков и сообщений используется Kafka UI.

Хранилища данных
PostgreSQL — 4 инстанса
auth-db — обслуживает auth-service. Хранит номера телефонов и refresh-токены.
users-db — обслуживает user-service. Хранит профили пользователей.
activities-db — обслуживает activity-service и moderation-service. Хранит активности, геометки (PostGIS), заявки на встречи, статусы модерации. Moderation-service пишет результат напрямую в эту БД, что обосновано тесной связью между результатом модерации и статусом активности.
chat-db — обслуживает chat-service. Хранит сообщения и комментарии.
PgBouncer
Один общий инстанс PgBouncer в режиме transaction pooling перед всеми четырьмя PostgreSQL. Управляет пулом соединений, предотвращает исчерпание лимита соединений при одновременной работе нескольких сервисов.
Redis
Один инстанс. Используется auth-service (OTP с TTL) и API Gateway (счётчики rate limiting, JWT blacklist).
MinIO
S3-совместимое объектное хранилище для фото и видео. Разворачивается одним контейнером. Media-service и video-worker работают с MinIO напрямую.

Миграции
Alembic — управление миграциями схем базы данных. Каждый сервис, имеющий собственную БД, содержит свой набор миграций Alembic. Миграции применяются при старте сервиса.

Мониторинг
Prometheus собирает метрики со всех сервисов. Каждый FastAPI-сервис экспортирует метрики через prometheus-fastapi-instrumentator — latency запросов, количество ошибок, нагрузка.
Grafana визуализирует метрики из Prometheus в виде дашбордов.

```
```
```
app5
├──infra
│   ├──grafana
│   │   ├──dashboards
│   │   │   ├──activity_service.json
│   │   │   ├──chat_service.json
│   │   │   └──gateway.json
│   │   └──datasources
│   │   │   └──prometheus.yml
│   ├──kafka
│   │   └──kraft-server.properties
│   ├──nginx
│   │   ├──ssl
│   │   │   └──.gitkeep
│   │   └──nginx.conf
│   ├──pgbouncer
│   │   └──pgbouncer.ini
│   └──prometheus
│   │   └──prometheus.yml
├──mobile
│   ├──android
│   │   ├──app
│   │   │   ├──src
│   │   │   │   ├──debug
│   │   │   │   │   └──AndroidManifest.xml
│   │   │   │   ├──main
│   │   │   │   │   ├──java
│   │   │   │   │   │   └──io
│   │   │   │   │   │   │   └──flutter
│   │   │   │   │   │   │   │   └──plugins
│   │   │   │   │   ├──kotlin
│   │   │   │   │   │   └──com
│   │   │   │   │   │   │   └──example
│   │   │   │   │   │   │   │   └──app5
│   │   │   │   │   │   │   │   │   └──MainActivity.kt
│   │   │   │   │   ├──res
│   │   │   │   │   │   ├──drawable
│   │   │   │   │   │   │   └──launch_background.xml
│   │   │   │   │   │   ├──drawable-v21
│   │   │   │   │   │   │   └──launch_background.xml
│   │   │   │   │   │   ├──mipmap-hdpi
│   │   │   │   │   │   │   └──ic_launcher.png
│   │   │   │   │   │   ├──mipmap-mdpi
│   │   │   │   │   │   │   └──ic_launcher.png
│   │   │   │   │   │   ├──mipmap-xhdpi
│   │   │   │   │   │   │   └──ic_launcher.png
│   │   │   │   │   │   ├──mipmap-xxhdpi
│   │   │   │   │   │   │   └──ic_launcher.png
│   │   │   │   │   │   ├──mipmap-xxxhdpi
│   │   │   │   │   │   │   └──ic_launcher.png
│   │   │   │   │   │   ├──values
│   │   │   │   │   │   │   └──styles.xml
│   │   │   │   │   │   └──values-night
│   │   │   │   │   │   │   └──styles.xml
│   │   │   │   │   └──AndroidManifest.xml
│   │   │   │   └──profile
│   │   │   │   │   └──AndroidManifest.xml
│   │   │   ├──build.gradle.kts
│   │   │   └──google-services.json
│   │   ├──gradle
│   │   │   └──wrapper
│   │   │   │   ├──gradle-wrapper.jar
│   │   │   │   └──gradle-wrapper.properties
│   │   ├──build.gradle.kts
│   │   ├──gradle.properties
│   │   ├──gradlew
│   │   ├──gradlew.bat
│   │   ├──settings.gradle.kts
│   │   └──.gitignore
│   ├──assets
│   │   ├──event.png
│   │   ├──exmeeting.png
│   │   ├──expin.png
│   │   ├──meeting.png
│   │   └──pin.png
│   ├──ios
│   │   ├──Flutter
│   │   │   ├──AppFrameworkInfo.plist
│   │   │   ├──Debug.xcconfig
│   │   │   └──Release.xcconfig
│   │   ├──Runner
│   │   │   ├──Assets.xcassets
│   │   │   │   ├──AppIcon.appiconset
│   │   │   │   │   ├──Contents.json
│   │   │   │   │   ├──Icon-App-1024x1024@1x.png
│   │   │   │   │   ├──Icon-App-20x20@1x.png
│   │   │   │   │   ├──Icon-App-20x20@2x.png
│   │   │   │   │   ├──Icon-App-20x20@3x.png
│   │   │   │   │   ├──Icon-App-29x29@1x.png
│   │   │   │   │   ├──Icon-App-29x29@2x.png
│   │   │   │   │   ├──Icon-App-29x29@3x.png
│   │   │   │   │   ├──Icon-App-40x40@1x.png
│   │   │   │   │   ├──Icon-App-40x40@2x.png
│   │   │   │   │   ├──Icon-App-40x40@3x.png
│   │   │   │   │   ├──Icon-App-60x60@2x.png
│   │   │   │   │   ├──Icon-App-60x60@3x.png
│   │   │   │   │   ├──Icon-App-76x76@1x.png
│   │   │   │   │   ├──Icon-App-76x76@2x.png
│   │   │   │   │   └──Icon-App-83.5x83.5@2x.png
│   │   │   │   └──LaunchImage.imageset
│   │   │   │   │   ├──Contents.json
│   │   │   │   │   ├──LaunchImage.png
│   │   │   │   │   ├──LaunchImage@2x.png
│   │   │   │   │   ├──LaunchImage@3x.png
│   │   │   │   │   └──README.md
│   │   │   ├──Base.lproj
│   │   │   │   ├──LaunchScreen.storyboard
│   │   │   │   └──Main.storyboard
│   │   │   ├──AppDelegate.swift
│   │   │   ├──Info.plist
│   │   │   ├──Runner-Bridging-Header.h
│   │   │   └──SceneDelegate.swift
│   │   ├──Runner.xcodeproj
│   │   │   ├──project.xcworkspace
│   │   │   │   ├──xcshareddata
│   │   │   │   │   ├──IDEWorkspaceChecks.plist
│   │   │   │   │   └──WorkspaceSettings.xcsettings
│   │   │   │   └──contents.xcworkspacedata
│   │   │   ├──xcshareddata
│   │   │   │   └──xcschemes
│   │   │   │   │   └──Runner.xcscheme
│   │   │   └──project.pbxproj
│   │   ├──Runner.xcworkspace
│   │   │   ├──xcshareddata
│   │   │   │   ├──IDEWorkspaceChecks.plist
│   │   │   │   └──WorkspaceSettings.xcsettings
│   │   │   └──contents.xcworkspacedata
│   │   ├──RunnerTests
│   │   │   └──RunnerTests.swift
│   │   └──.gitignore
│   ├──lib
│   │   ├──activity
│   │   │   ├──activity_service.dart
│   │   │   ├──activity_sheet.dart
│   │   │   ├──activity_widgets.dart
│   │   │   └──activity.dart
│   │   ├──auth
│   │   │   ├──auth_screen.dart
│   │   │   ├──otp_screen.dart
│   │   │   └──setup_profile_screen.dart
│   │   ├──chat
│   │   │   ├──chat_screen.dart
│   │   │   ├──comment_service.dart
│   │   │   ├──comment_widget.dart
│   │   │   └──comment.dart
│   │   ├──core
│   │   │   ├──api_client.dart
│   │   │   └──media_service.dart
│   │   ├──feed
│   │   │   └──feed_screen.dart
│   │   ├──map
│   │   │   ├──address_search_sheet.dart
│   │   │   ├──create_activity_sheet.dart
│   │   │   └──map_screen.dart
│   │   ├──meetings
│   │   │   ├──meeting_request.dart
│   │   │   ├──meeting_service.dart
│   │   │   └──meeting_sheet.dart
│   │   ├──profile
│   │   │   └──profile_screen.dart
│   │   ├──user
│   │   │   ├──user_service.dart
│   │   │   └──user.dart
│   │   └──main.dart
│   ├──linux
│   │   ├──flutter
│   │   │   └──CMakeLists.txt
│   │   ├──runner
│   │   │   ├──CMakeLists.txt
│   │   │   ├──main.cc
│   │   │   ├──my_application.cc
│   │   │   └──my_application.h
│   │   ├──CMakeLists.txt
│   │   └──.gitignore
│   ├──macos
│   │   ├──Flutter
│   │   │   ├──Flutter-Debug.xcconfig
│   │   │   └──Flutter-Release.xcconfig
│   │   ├──Runner
│   │   │   ├──Assets.xcassets
│   │   │   │   └──AppIcon.appiconset
│   │   │   │   │   ├──app_icon_1024.png
│   │   │   │   │   ├──app_icon_128.png
│   │   │   │   │   ├──app_icon_16.png
│   │   │   │   │   ├──app_icon_256.png
│   │   │   │   │   ├──app_icon_32.png
│   │   │   │   │   ├──app_icon_512.png
│   │   │   │   │   ├──app_icon_64.png
│   │   │   │   │   └──Contents.json
│   │   │   ├──Base.lproj
│   │   │   │   └──MainMenu.xib
│   │   │   ├──Configs
│   │   │   │   ├──AppInfo.xcconfig
│   │   │   │   ├──Debug.xcconfig
│   │   │   │   ├──Release.xcconfig
│   │   │   │   └──Warnings.xcconfig
│   │   │   ├──AppDelegate.swift
│   │   │   ├──DebugProfile.entitlements
│   │   │   ├──Info.plist
│   │   │   ├──MainFlutterWindow.swift
│   │   │   └──Release.entitlements
│   │   ├──Runner.xcodeproj
│   │   │   ├──project.xcworkspace
│   │   │   │   └──xcshareddata
│   │   │   │   │   └──IDEWorkspaceChecks.plist
│   │   │   ├──xcshareddata
│   │   │   │   └──xcschemes
│   │   │   │   │   └──Runner.xcscheme
│   │   │   └──project.pbxproj
│   │   ├──Runner.xcworkspace
│   │   │   ├──xcshareddata
│   │   │   │   └──IDEWorkspaceChecks.plist
│   │   │   └──contents.xcworkspacedata
│   │   ├──RunnerTests
│   │   │   └──RunnerTests.swift
│   │   └──.gitignore
│   ├──test
│   │   └──widget_test.dart
│   ├──web
│   │   ├──icons
│   │   │   ├──Icon-192.png
│   │   │   ├──Icon-512.png
│   │   │   ├──Icon-maskable-192.png
│   │   │   └──Icon-maskable-512.png
│   │   ├──favicon.png
│   │   ├──index.html
│   │   └──manifest.json
│   ├──windows
│   │   ├──flutter
│   │   │   └──CMakeLists.txt
│   │   ├──runner
│   │   │   ├──resources
│   │   │   │   └──app_icon.ico
│   │   │   ├──CMakeLists.txt
│   │   │   ├──flutter_window.cpp
│   │   │   ├──flutter_window.h
│   │   │   ├──main.cpp
│   │   │   ├──resource.h
│   │   │   ├──runner.exe.manifest
│   │   │   ├──Runner.rc
│   │   │   ├──utils.cpp
│   │   │   ├──utils.h
│   │   │   ├──win32_window.cpp
│   │   │   └──win32_window.h
│   │   ├──CMakeLists.txt
│   │   └──.gitignore
│   ├──analysis_options.yaml
│   ├──devtools_options.yaml
│   ├──output.txt
│   ├──pubspec.lock
│   ├──pubspec.yaml
│   ├──README.md
│   └──.metadata
├──services
│   ├──activity-service
│   │   ├──alembic
│   │   │   ├──versions
│   │   │   │   ├──005_creator_id_to_string.py
│   │   │   │   ├──006_create_meeting_requests.py
│   │   │   │   ├──ac7af778082d_create_activities_table.py
│   │   │   │   ├──add_activity_media.py
│   │   │   │   ├──add_status.py
│   │   │   │   └──second_migration.py
│   │   │   ├──env.py
│   │   │   ├──README
│   │   │   └──script.py.mako
│   │   ├──app
│   │   │   ├──db
│   │   │   │   ├──__init__.py
│   │   │   │   ├──base.py
│   │   │   │   └──session.py
│   │   │   ├──kafka
│   │   │   │   ├──__init__.py
│   │   │   │   ├──consumer.py
│   │   │   │   └──producer.py
│   │   │   ├──models
│   │   │   │   ├──__init__.py
│   │   │   │   ├──activity.py
│   │   │   │   └──meeting_request.py
│   │   │   ├──routers
│   │   │   │   ├──__init__.py
│   │   │   │   ├──activities.py
│   │   │   │   └──meetings.py
│   │   │   ├──schemas
│   │   │   │   ├──__init__.py
│   │   │   │   ├──activity.py
│   │   │   │   └──meeting.py
│   │   │   ├──services
│   │   │   │   ├──__init__.py
│   │   │   │   ├──activity.py
│   │   │   │   ├──geo_search.py
│   │   │   │   ├──meeting.py
│   │   │   │   └──ttl.py
│   │   │   ├──__init__.py
│   │   │   ├──config.py
│   │   │   └──main.py
│   │   ├──tests
│   │   │   ├──__init__.py
│   │   │   └──test_simple.py
│   │   ├──alembic.ini
│   │   ├──Dockerfile
│   │   └──requirements.txt
│   ├──api-gateway
│   │   ├──app
│   │   │   ├──middleware
│   │   │   │   ├──__init__.py
│   │   │   │   ├──jwt_validator.py
│   │   │   │   └──rate_limiter.py
│   │   │   ├──routers
│   │   │   │   ├──__init__.py
│   │   │   │   ├──activities.py
│   │   │   │   ├──auth.py
│   │   │   │   ├──chat.py
│   │   │   │   ├──media.py
│   │   │   │   ├──meetings.py
│   │   │   │   └──users.py
│   │   │   ├──__init__.py
│   │   │   ├──config.py
│   │   │   ├──dependencies.py
│   │   │   ├──main.py
│   │   │   └──proxy.py
│   │   ├──tests
│   │   │   └──__init__.py
│   │   ├──Dockerfile
│   │   └──requirements.txt
│   ├──auth-service
│   │   ├──alembic
│   │   │   ├──versions
│   │   │   │   ├──0001_create_user_auth.py
│   │   │   │   └──.gitkeep
│   │   │   ├──env.py
│   │   │   └──script.py.mako
│   │   ├──app
│   │   │   ├──db
│   │   │   │   ├──__init__.py
│   │   │   │   ├──base.py
│   │   │   │   └──session.py
│   │   │   ├──models
│   │   │   │   ├──__init__.py
│   │   │   │   └──user_auth.py
│   │   │   ├──routers
│   │   │   │   ├──__init__.py
│   │   │   │   └──auth.py
│   │   │   ├──schemas
│   │   │   │   ├──__init__.py
│   │   │   │   └──auth.py
│   │   │   ├──services
│   │   │   │   ├──__init__.py
│   │   │   │   ├──jwt.py
│   │   │   │   └──otp.py
│   │   │   ├──__init__.py
│   │   │   ├──config.py
│   │   │   └──main.py
│   │   ├──tests
│   │   │   └──__init__.py
│   │   ├──alembic.ini
│   │   ├──Dockerfile
│   │   └──requirements.txt
│   ├──chat-service
│   │   ├──alembic
│   │   │   ├──versions
│   │   │   │   ├──001_create_comments_table.py
│   │   │   │   ├──002_user_id_varchar.py
│   │   │   │   └──.gitkeep
│   │   │   ├──env.py
│   │   │   └──script.py.mako
│   │   ├──app
│   │   │   ├──db
│   │   │   │   ├──__init__.py
│   │   │   │   ├──base.py
│   │   │   │   └──session.py
│   │   │   ├──kafka
│   │   │   │   ├──__init__.py
│   │   │   │   └──producer.py
│   │   │   ├──models
│   │   │   │   ├──__init__.py
│   │   │   │   └──message.py
│   │   │   ├──routers
│   │   │   │   ├──__init__.py
│   │   │   │   └──chat.py
│   │   │   ├──schemas
│   │   │   │   ├──__init__.py
│   │   │   │   └──chat.py
│   │   │   ├──services
│   │   │   │   ├──__init__.py
│   │   │   │   └──chat.py
│   │   │   ├──websocket
│   │   │   │   ├──__init__.py
│   │   │   │   ├──handlers.py
│   │   │   │   └──manager.py
│   │   │   ├──__init__.py
│   │   │   ├──config.py
│   │   │   └──main.py
│   │   ├──tests
│   │   │   └──__init__.py
│   │   ├──alembic.ini
│   │   ├──Dockerfile
│   │   └──requirements.txt
│   ├──media-service
│   │   ├──app
│   │   │   ├──kafka
│   │   │   │   ├──__init__.py
│   │   │   │   └──producer.py
│   │   │   ├──routers
│   │   │   │   ├──__init__.py
│   │   │   │   └──upload.py
│   │   │   ├──services
│   │   │   │   ├──__init__.py
│   │   │   │   └──minio.py
│   │   │   ├──__init__.py
│   │   │   ├──config.py
│   │   │   └──main.py
│   │   ├──tests
│   │   │   └──__init__.py
│   │   ├──Dockerfile
│   │   └──requirements.txt
│   ├──moderation-service
│   │   ├──app
│   │   │   ├──db
│   │   │   │   ├──__init__.py
│   │   │   │   └──session.py
│   │   │   ├──kafka
│   │   │   │   ├──__init__.py
│   │   │   │   ├──consumer.py
│   │   │   │   └──producer.py
│   │   │   ├──services
│   │   │   │   ├──__init__.py
│   │   │   │   ├──media_checker.py
│   │   │   │   └──text_checker.py
│   │   │   ├──__init__.py
│   │   │   ├──config.py
│   │   │   └──main.py
│   │   ├──tests
│   │   │   └──__init__.py
│   │   ├──Dockerfile
│   │   └──requirements.txt
│   ├──notification-service
│   │   ├──app
│   │   │   ├──kafka
│   │   │   │   ├──__init__.py
│   │   │   │   └──consumer.py
│   │   │   ├──services
│   │   │   │   ├──__init__.py
│   │   │   │   ├──fcm.py
│   │   │   │   └──geo_notify.py
│   │   │   ├──__init__.py
│   │   │   ├──config.py
│   │   │   └──main.py
│   │   ├──tests
│   │   │   └──__init__.py
│   │   ├──Dockerfile
│   │   └──requirements.txt
│   ├──user-service
│   │   ├──alembic
│   │   │   ├──versions
│   │   │   │   ├──create users table.py
│   │   │   │   └──.gitkeep
│   │   │   ├──env.py
│   │   │   └──script.py.mako
│   │   ├──app
│   │   │   ├──db
│   │   │   │   ├──__init__.py
│   │   │   │   ├──base.py
│   │   │   │   └──session.py
│   │   │   ├──models
│   │   │   │   ├──__init__.py
│   │   │   │   └──user.py
│   │   │   ├──routers
│   │   │   │   ├──__init__.py
│   │   │   │   └──users.py
│   │   │   ├──schemas
│   │   │   │   ├──__init__.py
│   │   │   │   └──user.py
│   │   │   ├──services
│   │   │   │   ├──__init__.py
│   │   │   │   └──user.py
│   │   │   ├──__init__.py
│   │   │   ├──config.py
│   │   │   └──main.py
│   │   ├──tests
│   │   │   └──__init__.py
│   │   ├──alembic.ini
│   │   ├──Dockerfile
│   │   └──requirements.txt
│   └──video-worker
│   │   ├──app
│   │   │   ├──kafka
│   │   │   │   ├──__init__.py
│   │   │   │   └──consumer.py
│   │   │   ├──services
│   │   │   │   ├──__init__.py
│   │   │   │   ├──ffmpeg.py
│   │   │   │   └──minio.py
│   │   │   ├──__init__.py
│   │   │   ├──config.py
│   │   │   └──main.py
│   │   ├──tests
│   │   │   └──__init__.py
│   │   ├──Dockerfile
│   │   └──requirements.txt
├──docker-compose.yml
├──README.md
├──.env.example
└──.gitignore
```
```


## Отдельный микросервис (пример структуры)
├──activity-service
│   │   ├──alembic
│   │   │   ├──versions
│   │   │   │   ├──ac7af778082d_create_activities_table.py
│   │   │   │   ├──add_activity_media.py
│   │   │   │   ├──add_status.py
│   │   │   │   └──second_migration.py
│   │   │   ├──env.py
│   │   │   ├──README
│   │   │   └──script.py.mako
│   │   ├──app
│   │   │   ├──db
│   │   │   │   ├──__init__.py
│   │   │   │   ├──base.py
│   │   │   │   └──session.py
│   │   │   ├──kafka
│   │   │   │   ├──__init__.py
│   │   │   │   ├──consumer.py
│   │   │   │   └──producer.py
│   │   │   ├──models
│   │   │   │   ├──__init__.py
│   │   │   │   ├──activity.py
│   │   │   │   └──meeting_request.py
│   │   │   ├──routers
│   │   │   │   ├──__init__.py
│   │   │   │   ├──activities.py
│   │   │   │   └──meetings.py
│   │   │   ├──schemas
│   │   │   │   ├──__init__.py
│   │   │   │   └──activity.py
│   │   │   ├──services
│   │   │   │   ├──__init__.py
│   │   │   │   ├──activity.py
│   │   │   │   ├──geo_search.py
│   │   │   │   ├──meeting.py
│   │   │   │   └──ttl.py
│   │   │   ├──__init__.py
│   │   │   ├──config.py
│   │   │   └──main.py
│   │   ├──tests
│   │   │   └──__init__.py
│   │   ├──alembic.ini
│   │   ├──Dockerfile
│   │   └──requirements.txt