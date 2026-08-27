# Lab Deploy

Локальный и серверный запуск `lab_front` + `lab_back` + MongoDB.

```bash
make up
```

После запуска приложение доступно на `http://localhost:8081`, API проксируется через тот же origin.

Production использует внешний nginx gateway с HTTPS-сертификатом для IP-адреса,
а systemd timer ежедневно проверяет необходимость продления короткоживущего
сертификата Let's Encrypt. Конфигурация gateway находится в `deploy/nginx.conf`,
а unit-файлы — в `systemd/`.

При первом `make up` скрипт `scripts/init-env.sh` автоматически создаёт `.env`, генерирует криптографически случайные `MONGO_ROOT_PASSWORD` и `JWT_SECRET`, выставляет права `600` и больше не меняет эти секреты при последующих запусках. MongoDB создаёт базу `lab` при первом подключении, а Compose ждёт её успешный health-check перед запуском API.

Секреты не входят в репозиторий. Для теста ИИ-сводки добавьте `DEEPSEEK_API_KEY` в созданный `.env`; без него работает локальный OCR и базовая оценка по референсам.

Для открытого интернета compose следует поставить за TLS reverse proxy и закрыть прямой доступ к MongoDB. Этот MVP не предназначен для хранения реальных медицинских данных до выполнения пунктов из [ARCHITECTURE.md](ARCHITECTURE.md).

## Production VDS

Production-профиль использует готовые публичные образы Docker Hub, не собирает исходники на небольшом сервере и ограничивает память контейнеров:

```bash
cp .env.production.example .env
make prod-up
```

MongoDB получает 640 МБ RAM и WiredTiger cache 256 МБ, backend — 640 МБ, nginx frontend — 128 МБ. Для VDS с 2 ГБ RAM рекомендуется swap не менее 2 ГБ. Перед обработкой реальных данных необходимо подключить домен и HTTPS; доступ по голому HTTP/IP предназначен только для первичной проверки.

Используемые образы:

- `docker.io/idrisovmarat/lab_back:latest`
- `docker.io/idrisovmarat/lab_front:latest`
