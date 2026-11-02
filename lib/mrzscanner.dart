/// The MRZ scanner for Flutter: reads passports, ID cards and visas with the camera (AR mode) or
/// from photos, offline. The API of every MRZ scanner wrapper (platforms/API.md) in Dart; the
/// native side (MrzscannerPlugin) passes strings to the SDKs' MrzScan / MRZScan and
/// returns their JSON.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

/// The kinds of document.
enum DocumentType { passport, id, visa }

/// How many agreeing frames a read needs: [normal] two (more when a character no check digit covers
/// is uncertain), [fast] the first frame with valid check digits.
enum Confirmation { normal, fast }

/// Why [MRZScanner.scan] ended.
enum ScanStatus { read, stopped, timeout, permissionDenied, licenseInactive, error }

/// A region of the upright camera picture, in fractions (0..1).
class ScanRegion {
  final double x, y, width, height;
  const ScanRegion(this.x, this.y, this.width, this.height);
  Map<String, Object> toJson() => {'x': x, 'y': y, 'width': width, 'height': height};
}

/// How [MRZScanner.scan] scans; null fields keep the defaults.
class ScanSettings {
  /// false: close after the first confirmed read; true: collect each new document until Stop.
  final bool? continuous;
  /// continuous only: the same MRZ is not collected again within this time (default 3 s).
  final Duration? duplicateTimeout;
  final Confirmation? confirmation;
  /// Close when nothing was read for this long (default: never).
  final Duration? timeout;
  /// The torch and the zoom factor when the camera opens.
  final bool? torch;
  final double? zoom;
  /// A haptic tick for each read (default true).
  final bool? vibrateOnRead;
  /// The box that follows the MRZ and the read badge over it (default true).
  final bool? arOverlay;
  /// The kinds of document to read (default all).
  final Set<DocumentType>? documentTypes;
  /// Only an MRZ inside this part of the picture is read (default all of it).
  final ScanRegion? regionOfInterest;
  /// Each read also gets [MrzRead.isolatedMrz]: the MRZ alone, [isolatedHeight] pixels tall.
  final bool? isolateMrz;
  final int? isolatedHeight;
  /// Each read also gets [MrzRead.portrait]: the document's photo, cut out and straightened (only a
  /// photo on the MRZ's side: a passport's data page, not an ID card's back). Default false.
  final bool? capturePortrait;
  /// Each read also gets [MrzRead.signature], the same way, when the MRZ's side has one. Default false.
  final bool? captureSignature;
  /// Each read also gets [MrzRead.document]: the whole page around the MRZ, cut out, straightened, in
  /// colour. Default false.
  final bool? captureDocument;
  /// Anti-blur: a second character model, trained on defocus-blurred MRZs, reads what the first
  /// cannot (a camera out of focus, a document held too close); only when the normal read fails.
  /// Names have no check digit: on a blurred MRZ a letter is occasionally wrong. Default false.
  final bool? blurReading;
  /// true (default): only reads whose check digits all match are returned. false: a read whose check
  /// digits do not match is returned too, with [MrzRead.checkDigitsValid] false - specimens and sample
  /// documents often print digits that do not add up. On the camera such a read needs more agreeing
  /// frames than a valid one; it is the reader's best reading, not verified by the check digits:
  /// decide in the app what to do with it.
  final bool? enforceCheckDigits;
  /// [ScanMode.mrz] (default): read MRZs. [ScanMode.document]: no MRZ reading - the camera finds an
  /// ID-1 card or a passport / visa page (e.g. a card's front), outlines it, and once it is held
  /// still captures it ([ScanResult.documents]); the MRZ settings do not apply.
  final ScanMode? mode;
  /// The camera bar's title (default "Passport & ID").
  final String? title;

  const ScanSettings({
    this.continuous,
    this.duplicateTimeout,
    this.confirmation,
    this.timeout,
    this.torch,
    this.zoom,
    this.vibrateOnRead,
    this.arOverlay,
    this.documentTypes,
    this.regionOfInterest,
    this.isolateMrz,
    this.isolatedHeight,
    this.capturePortrait,
    this.captureSignature,
    this.captureDocument,
    this.blurReading,
    this.enforceCheckDigits,
    this.mode,
    this.title,
  });

  Map<String, Object> toJson() => {
        if (continuous != null) 'continuous': continuous!,
        if (duplicateTimeout != null) 'duplicateTimeoutMs': duplicateTimeout!.inMilliseconds,
        if (confirmation != null) 'confirmation': confirmation!.name,
        if (timeout != null) 'timeoutMs': timeout!.inMilliseconds,
        if (torch != null) 'torch': torch!,
        if (zoom != null) 'zoom': zoom!,
        if (vibrateOnRead != null) 'vibrateOnRead': vibrateOnRead!,
        if (arOverlay != null) 'arOverlay': arOverlay!,
        if (documentTypes != null) 'documentTypes': documentTypes!.map((t) => t.name).toList(),
        if (regionOfInterest != null) 'regionOfInterest': regionOfInterest!.toJson(),
        if (isolateMrz != null) 'isolateMrz': isolateMrz!,
        if (isolatedHeight != null) 'isolatedHeight': isolatedHeight!,
        if (capturePortrait != null) 'capturePortrait': capturePortrait!,
        if (captureSignature != null) 'captureSignature': captureSignature!,
        if (captureDocument != null) 'captureDocument': captureDocument!,
        if (blurReading != null) 'blurReading': blurReading!,
        if (enforceCheckDigits != null) 'enforceCheckDigits': enforceCheckDigits!,
        if (mode != null) 'mode': mode!.name,
        if (title != null) 'title': title!,
      };
}

/// A point in pixels.
class Point {
  final int x, y;
  const Point(this.x, this.y);
}

/// One MRZ read.
class MrzRead {
  /// The MRZ lines joined by "\n".
  final String text;
  final bool checkDigitsValid;
  /// "Passport", "ID card", "Visa" or the document type.
  final String kind;
  /// The parsed fields: document_number, surnames, given_names, nationality, dob_raw, ...
  final Map<String, dynamic> fields;
  /// Where the MRZ is: 4 points (photos: in the image's pixels); null when unknown.
  final List<Point>? corners;
  /// "data:image/jpeg;base64,..." when asked for.
  final String? isolatedMrz;
  /// "data:image/jpeg;base64,..." when asked for ([ScanSettings.capturePortrait]) and found.
  final String? portrait;
  /// "data:image/jpeg;base64,..." when asked for ([ScanSettings.captureSignature]) and found.
  final String? signature;
  /// "data:image/jpeg;base64,..." when asked for ([ScanSettings.captureDocument]) and placed.
  final String? document;

  MrzRead.fromJson(Map<String, dynamic> j)
      : text = j['text'] as String,
        checkDigitsValid = j['checkDigitsValid'] as bool,
        kind = j['kind'] as String? ?? '',
        fields = (j['fields'] as Map?)?.cast<String, dynamic>() ?? const {},
        corners = (j['corners'] as List?)
            ?.map((p) => Point(((p as List)[0] as num).toInt(), (p[1] as num).toInt()))
            .toList(),
        isolatedMrz = j['isolatedMrz'] as String?,
        portrait = j['portrait'] as String?,
        signature = j['signature'] as String?,
        document = j['document'] as String?;

  /// The MRZ lines.
  List<String> get lines => text.split('\n');

  /// [isolatedMrz] as JPEG bytes (for Image.memory); null when not asked for.
  Uint8List? get isolatedMrzBytes => _bytes(isolatedMrz);
  /// [portrait] as JPEG bytes; null when not asked for or not found.
  Uint8List? get portraitBytes => _bytes(portrait);
  /// [signature] as JPEG bytes; null when not asked for or not found.
  Uint8List? get signatureBytes => _bytes(signature);
  /// [document] as JPEG bytes; null when not asked for or not placed.
  Uint8List? get documentBytes => _bytes(document);

  static Uint8List? _bytes(String? s) => s == null ? null : base64Decode(s.substring(s.indexOf(',') + 1));

  /// A field as text (word lists such as surnames joined by spaces); "" when missing.
  String field(String name) {
    final v = fields[name];
    if (v is List) return v.join(' ').trim();
    return v?.toString() ?? '';
  }
}

/// What [MRZScanner.scan] returns.
enum ScanMode { mrz, document }

/// A document captured without an MRZ ([ScanSettings.mode] [ScanMode.document]).
class MrzDocument {
  /// "card" (ID-1) or "page" (passport / visa).
  final String kind;
  final double score;
  /// Where it was in the camera frame, in the order of the image's corners.
  final List<Point> corners;
  /// "data:image/jpeg;base64,...": straightened, landscape (which way is up is not known).
  final String image;

  MrzDocument.fromJson(Map<String, dynamic> j)
      : kind = j['kind'] as String? ?? 'card',
        score = (j['score'] as num?)?.toDouble() ?? 0,
        corners = ((j['corners'] as List?) ?? const [])
            .map((p) => Point(((p as List)[0] as num).toInt(), (p[1] as num).toInt()))
            .toList(),
        image = j['image'] as String? ?? '';

  /// [image] as JPEG bytes.
  Uint8List get imageBytes => base64Decode(image.substring(image.indexOf(',') + 1));
}

class ScanResult {
  final ScanStatus status;
  /// The reads: one, or with continuous settings each new document (possibly none).
  final List<MrzRead> reads;
  /// Document mode: the documents captured (else empty).
  final List<MrzDocument> documents;
  final Duration elapsed;
  /// licenseInactive: why; error: what went wrong.
  final String? reason, message;

  ScanResult.fromJson(Map<String, dynamic> j)
      : status = ScanStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => ScanStatus.error),
        reads = ((j['reads'] as List?) ?? const [])
            .map((r) => MrzRead.fromJson((r as Map).cast<String, dynamic>()))
            .toList(),
        documents = ((j['documents'] as List?) ?? const [])
            .map((d) => MrzDocument.fromJson((d as Map).cast<String, dynamic>()))
            .toList(),
        elapsed = Duration(milliseconds: (j['elapsedMs'] as num?)?.toInt() ?? 0),
        reason = j['reason'] as String?,
        message = j['message'] as String?;
}

/// What [MRZScanner.registerLicense] returns.
class LicenseResult {
  /// 0: accepted; -2 invalid key, -3 other app, -4 other device, -5 expired, -6 other platform.
  final int status;
  /// null, or a reason to show (with the MRZ2 check-in protocol: no_lease, expired,
  /// `denied:<reason>`, clock).
  final String? reason;

  bool get accepted => status == 0;

  LicenseResult.fromJson(Map<String, dynamic> j)
      : status = (j['status'] as num).toInt(),
        reason = j['reason'] as String?;
}

/// The MRZ scanner.
class MRZScanner {
  MRZScanner._();

  static const _channel = MethodChannel('mrzscanner');

  static Future<dynamic> _call(String method, List<String> args) async =>
      jsonDecode(await _channel.invokeMethod<String>(method, args) ?? 'null');

  /// Registers the licence key for this app (call once at start). Without it fields are masked.
  static Future<LicenseResult> registerLicense(String key) async =>
      LicenseResult.fromJson(await _call('registerLicense', [key]) as Map<String, dynamic>);

  /// Opens the full-screen camera, scans, closes. Asks for the camera permission.
  static Future<ScanResult> scan([ScanSettings settings = const ScanSettings()]) async =>
      ScanResult.fromJson(await _call('scan', [jsonEncode(settings.toJson())]) as Map<String, dynamic>);

  /// Reads the MRZ in a photo: a file [path] or the [bytes] of a JPEG / PNG. Null when there is none.
  static Future<MrzRead?> scanImage({String? path, Uint8List? bytes, Set<DocumentType>? documentTypes, int? isolatedHeight,
                                     bool? capturePortrait, bool? captureSignature, bool? captureDocument,
                                     bool? blurReading, bool? enforceCheckDigits}) async {
    assert((path == null) != (bytes == null), 'give either path or bytes');
    final image = path != null ? {'path': path} : {'base64': base64Encode(bytes!)};
    final options = {
      if (documentTypes != null) 'documentTypes': documentTypes.map((t) => t.name).toList(),
      if (isolatedHeight != null) 'isolatedHeight': isolatedHeight,
      if (capturePortrait != null) 'capturePortrait': capturePortrait,
      if (captureSignature != null) 'captureSignature': captureSignature,
      if (captureDocument != null) 'captureDocument': captureDocument,
      if (blurReading != null) 'blurReading': blurReading,
      if (enforceCheckDigits != null) 'enforceCheckDigits': enforceCheckDigits,
    };
    final r = await _call('scanImage', [jsonEncode(image), jsonEncode(options)]);
    return r == null ? null : MrzRead.fromJson(r as Map<String, dynamic>);
  }

  /// The core's version (and this package's, the same), e.g. "2.5.0".
  static Future<String> version() async => ((await _call('version', [])) as Map)['core'] as String;
}
