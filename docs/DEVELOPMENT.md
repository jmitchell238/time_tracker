# Development

## Running locally

Needs the Flutter SDK (stable channel).

```bash
flutter pub get
flutter run -d chrome
```

Add `--web-port 8080` to use a fixed port. It also runs as a Windows desktop app with `flutter run -d windows`.

On WSL, use the Windows Flutter SDK through `cmd.exe /c "flutter ..."`. The WSL Dart SDK doesn't work in this setup.

## Tests

```bash
flutter test
flutter analyze
```

Tests use `fake_cloud_firestore` and `firebase_auth_mocks`, so they don't need a Firebase project. They must all pass before a release.

## Releasing

See [RELEASE.md](RELEASE.md). Bump `kBuildVersion` in `lib/build_info.dart` first; it's shown in Settings so you can tell which build a device is running.
