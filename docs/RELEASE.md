# Release Process

Run all commands from `C:\Users\jmitc\workspace\time_tracker` in a **Windows** terminal (not WSL).

## Steps

### 0. Bump the build version
Update `kBuildVersion` in `lib/build_info.dart` (shown in Settings) so deployed
devices can be identified.

### 1. Run tests (must be 100% pass)
```
flutter test
```
Do not proceed if any test fails.

### 2. Build web release
```
flutter build web --release
```

### 3. Deploy to Firebase Hosting
```
firebase deploy --only hosting
```

## Live URL

https://time-tracker-jm.web.app
