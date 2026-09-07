# Consent Photo Uploader

Cross-platform Flutter + FastAPI starter project.

## Privacy model
The app only uploads images explicitly selected by the user through the system picker.
It does not scan the device gallery automatically, run hidden uploads, or collect photos in the background.

## Structure
- `mobile/` Flutter app
- `server/` FastAPI API and simple web gallery

## Run server
```bash
cd server
python -m venv .venv
# activate the environment
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

Open `http://127.0.0.1:8000/` for the gallery.

## Run mobile
Install Flutter, then:
```bash
cd mobile
flutter pub get
flutter run
```

Set the API base URL in `lib/main.dart` if your phone cannot reach the development computer.

For Android release:
```bash
flutter build apk --release
```

For iOS:
```bash
flutter build ios --release
```
iOS signing requires an Apple developer setup and signing certificate/profile.
