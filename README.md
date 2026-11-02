# mrzscanner

Reads the machine-readable zone (MRZ) of passports, ID cards and visas, offline: a full-screen
camera with AR mode (a box follows the MRZ and shows the read), or a photo. Android 7+ (API 24) and
iOS 15+ (Swift Package Manager or CocoaPods).

```
flutter pub add mrzscanner
```

Android: `minSdk = 24` in `android/app/build.gradle(.kts)`. iOS: a camera usage text in
`ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Scans the MRZ of passports and ID cards.</string>
```

## Use

```dart
import 'package:mrzscanner/mrzscanner.dart';

await MRZScanner.registerLicense('MRZ2...');      // once; without it some fields are masked

final result = await MRZScanner.scan(const ScanSettings(documentTypes: {DocumentType.passport, DocumentType.id}));
if (result.status == ScanStatus.read) {
  final read = result.reads.first;
  print('${read.text} ${read.field('document_number')} ${read.checkDigitsValid}');
}

final fromPhoto = await MRZScanner.scanImage(path: photoPath);   // or bytes: jpegBytes
```

`scan(settings)` opens the camera (asking for the permission), and closes after the first read, or
with `continuous: true` collects each new document until Stop. It returns a `ScanResult`:
`status` (`read`, `stopped`, `timeout`, `permissionDenied`, `licenseInactive`, `error`), `reads`,
`elapsed`. `ScanSettings`: `continuous`, `duplicateTimeout`, `confirmation`, `timeout`, `torch`,
`zoom`, `vibrateOnRead`, `arOverlay`, `documentTypes`, `regionOfInterest`, `isolateMrz`,
`isolatedHeight`, `title`.

Each `MrzRead`: `text` (the MRZ lines), `checkDigitsValid`, `kind`, `fields` (`document_number`,
`surnames`, `given_names`, `nationality`, `dob_raw`, `expiration_date_raw`, ...; `field(name)`
gives one as text), `corners`, `isolatedMrz` / `isolatedMrzBytes`.

`scanImage(path: ... | bytes: ..., documentTypes:, isolatedHeight:)` returns the read or `null`.

The 1.x plugin is `mrzscanner_flutter` (a different API); this package is its successor from 2.5.0.

Version 2.7.4. Licence: a commercial MRZ scanner licence (https://mrzscanner.com/).
