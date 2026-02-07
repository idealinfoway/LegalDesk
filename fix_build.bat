@echo off
echo Fixing Flutter build issues...
echo.

REM Clean build directories
echo Cleaning Gradle...
cd android
call gradlew clean
cd ..

echo.
echo Removing Flutter build artifacts...
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool
if exist .flutter-plugins del /f /q .flutter-plugins
if exist .flutter-plugins-dependencies del /f /q .flutter-plugins-dependencies

echo.
echo Recreating build directory...
mkdir build 2>nul

echo.
echo Running flutter pub get...
flutter pub get

echo.
echo Done! You can now try running your app.
echo If the issue persists, check:
echo 1. Antivirus software (add Flutter/Dart to exclusions)
echo 2. Run as Administrator
echo 3. Check disk health with: chkdsk D: /F (requires restart)
pause
