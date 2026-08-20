# Lab Deploy

Локальный и серверный запуск `lab_front` + `lab_back` + MongoDB.

```bash
cp .env.example .env
# замените MONGO_ROOT_PASSWORD и JWT_SECRET
make up
```

После запуска приложение доступно на `http://localhost:8081`, API проксируется через тот же origin.

Секреты не входят в репозиторий. Для теста ИИ-сводки добавьте `DEEPSEEK_API_KEY`; без него работает локальный OCR и базовая оценка по референсам.

Для открытого интернета compose следует поставить за TLS reverse proxy и закрыть прямой доступ к MongoDB. Этот MVP не предназначен для хранения реальных медицинских данных до выполнения пунктов из [ARCHITECTURE.md](ARCHITECTURE.md).
