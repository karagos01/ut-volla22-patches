# Fingerprint Wake+Unlock

Single-touch fingerprint wake and unlock — touch the rear sensor to wake the screen and unlock in one gesture.

## How it works

1. Greeter's biometric identification runs even when display is off (Powerd.On condition removed)
2. On successful identification, `FpWake.wakeScreen()` calls `com.canonical.Unity.Screen.keepDisplayOn` via D-Bus
3. Greeter sets `forcedUnlock = true` to dismiss the lockscreen

## Components

- `FpWake/` — QML plugin (C++ shared library) that exposes `wakeScreen()` D-Bus call
- `Greeter.qml` — patched greeter with FpWake import and always-on biometric identification
- `enroll.qml` — fingerprint enrollment script

## Enrollment

```bash
QT_QPA_PLATFORM=minimal qmlscene /path/to/enroll.qml
```

Touch the sensor ~14 times until "SUCCESS" appears.

## Requirements

- `biometryd` running with `android` device (Focaltech/Goodix FP sensor via Android HAL)
- `EnableFingerprintIdentification` = true in AccountsService (set by apply.sh)
