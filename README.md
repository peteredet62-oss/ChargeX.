# ChargeMonitor - Flutter mobile project (converted)

This repository is a Flutter conversion of your Buildify/Next.js ChargeMonitor UI with Android native code to fetch battery metrics.
It includes:
- Flutter UI (lib/main.dart)
- Android native MethodChannel (MainActivity.kt) that returns a Map with:
  - level (int, %)
  - voltage (int, mV)
  - current (int, mA, approximate)
  - isCharging (bool)

## Notes on accuracy
- Not all Android devices expose `BATTERY_PROPERTY_CURRENT_NOW`. The value may be missing or 0 on some phones.
- Voltage comes from `Intent.ACTION_BATTERY_CHANGED` (in mV).
- Time-to-full is estimated using an assumed battery capacity (default 4000 mAh). Edit `batteryCapacityMah` in `lib/main.dart` for your device.

## How to build APK (recommended: use a PC with Flutter & Android SDK)
1. Install Flutter SDK: https://flutter.dev/docs/get-started/install
2. From this project root (where `pubspec.yaml` is), run:
   ```
   flutter pub get
   flutter build apk --release
   ```
3. Result APK will be at:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

## How to test on phone without a PC (phone-only)
- Option A: Use **Termux** + **Ubuntu chroot** + Flutter SDK (advanced)
- Option B (easier): Transfer this folder to a PC and follow standard Flutter build steps.

## If you want me to:
- Replace the battery capacity default with a device-specific value
- Try to create a signed APK (I can prepare instructions and signing config)
- Add icons, splash screen, or app settings

Tell me which you'd like and I'll proceed.
