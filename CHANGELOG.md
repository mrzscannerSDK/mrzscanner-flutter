## 2.7.4

- The native SDKs inside the plugin no longer contain the team's debug frame collector (which could
  upload scanned frames to a development server); the Android SDK no longer asks for the INTERNET
  permission. Files written on the build machine are no longer in the package.

## 2.7.3

- Android: no crash when the scanner screen is closed or recreated (the phone turned) while a frame
  is being scanned - the camera now stops only once that frame is done.

## 2.7.2

- Enforce check digits on MRZ scanner core 2.7.2: `enforceCheckDigits` in the settings (and in
  `scanImage`), on by default. Off, a read whose check digits do not add up is returned too, with
  `checkDigitsValid` false - specimens and some documents print check digits that do not match.
- Bent pages: an MRZ on a page bent so far that its characters are squeezed on one side is read
  (a curled visa filmed on a phone), and with check digits not enforced also when one of them was
  printed wrong.

## 2.7.0

- Anti-blur on MRZ scanner core 2.7.0: `blurReading` in the settings (and in `scanImage`) adds a
  second character model trained on defocus-blurred MRZs, for cameras out of focus. Off by default.
- Blurred ID cards keep their third MRZ line (they were read as a 2-line MRZ, wrongly).
- Licence keys: this release accepts keys issued by mrzscanner.com (production) only.

## 2.6.0

- Portrait and signature capture on MRZ scanner core 2.6.0: `capturePortrait` / `captureSignature`
  in the settings give each read `MrzRead.portrait` / `MrzRead.signature`, cut out of the document
  and straightened. Needs a licence key (without one the read has no portrait or signature).
- The core's models ship protected (stored scrambled; the licensed ones work only after a key is
  accepted).

## 2.5.0

- First release of the Flutter plugin on MRZ scanner core 2.5.0: the full-screen camera with AR
  mode (`MRZScanner.scan`), photos (`MRZScanner.scanImage`), licence registration. Android 7+
  (API 24), iOS 15+ (Swift Package Manager and CocoaPods).
