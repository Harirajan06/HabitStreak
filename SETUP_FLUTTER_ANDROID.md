# Flutter and Android SDK Setup (Codespace)

This devcontainer now has Flutter and the Android SDK installed for building and web UI testing.

## What I installed
- Flutter SDK: located at `$HOME/flutter` and added to PATH
- Android SDK (CLI): located at `$HOME/Android/Sdk`
  - Installed packages: `platform-tools`, `platforms;android-35`, `build-tools;35.0.0` (and 34 for compatibility)
- Web support enabled: `flutter config --enable-web`

## Environment variables
These are persisted in `~/.bashrc` for future shells:
- `export PATH="$HOME/flutter/bin:$PATH"`
- `export ANDROID_SDK_ROOT="$HOME/Android/Sdk"`
- `export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"`

To load them in your current terminal:
```
source ~/.bashrc
```

## Verify installation
```
flutter doctor -v
```
You should see:
- Flutter: OK
- Android toolchain: OK (SDK version 35.0.0)
- Chrome: missing (intentional here to save space)
- Linux desktop: some tools missing (not needed for this project)

## Notes
- We intentionally did not install Android Studio or emulators to keep the container lightweight.
- For UI testing, use Flutter Web (Device Preview package) via your local Chrome, or run a web server device in the codespace. For functionality testing, install the APK on your physical device.