@echo off
echo === Building web release ===
call flutter build web --release
if %errorlevel% neq 0 (
    echo Build FAILED. Aborting deploy.
    exit /b %errorlevel%
)

echo.
echo === Deploying to Firebase Hosting ===
call firebase deploy --only hosting
if %errorlevel% neq 0 (
    echo Deploy FAILED.
    exit /b %errorlevel%
)

echo.
echo === Done! ===
