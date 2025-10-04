# flutter_prefi

This repository contains:
- db.json (at repo root) for My JSON Server
- Flutter app in `flutter_application_1/`

My JSON Server base URL:
- https://my-json-server.typicode.com/froakie71/flutter_prefi

Endpoints:
- GET /students -> https://my-json-server.typicode.com/froakie71/flutter_prefi/students
- GET /attendance -> https://my-json-server.typicode.com/froakie71/flutter_prefi/attendance

Note: My JSON Server is read-only. POST/PUT/DELETE are faked and not persisted.

## Flutter Web app
- Path: `flutter_application_1/`
- Pages: Scanner, Students (with QR generation), Dashboard
- Update `lib/config.dart` if you fork/rename.

## Run locally
```bash
cd flutter_application_1
flutter pub get
flutter run -d chrome
```
