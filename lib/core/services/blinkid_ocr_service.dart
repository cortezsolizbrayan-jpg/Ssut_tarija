import 'dart:convert';
import 'dart:io';

import 'package:blinkid_flutter/blinkid_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:refactor_template/core/services/servicio_ocr_inteligente_identidad.dart';

class BlinkIdOcrService {
  static final BlinkidFlutter _blinkid = BlinkidFlutter();

  static bool get isEnabled {
    final key = _licenseKey;
    return key != null && key.isNotEmpty;
  }

  static String? get _licenseKey {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return dotenv.env['BLINKID_LICENSE_ANDROID'];
    if (Platform.isIOS) return dotenv.env['BLINKID_LICENSE_IOS'];
    return null;
  }

  static String? get _licensee {
    final licensee = dotenv.env['BLINKID_LICENSEE'];
    return licensee != null && licensee.isNotEmpty ? licensee : null;
  }

  static Future<Map<String, String>?> scanImages({
    required File frontFile,
    File? backFile,
  }) async {
    final licenseKey = _licenseKey;
    if (licenseKey == null || licenseKey.isEmpty) return null;

    try {
      final sdkSettings = BlinkIdSdkSettings(licenseKey);
      sdkSettings.downloadResources = true;
      final licensee = _licensee;
      if (licensee != null) {
        sdkSettings.licensee = licensee;
      }

      final sessionSettings = BlinkIdSessionSettings();
      sessionSettings.scanningMode =
          backFile != null ? ScanningMode.automatic : ScanningMode.single;
      sessionSettings.scanningSettings = _buildScanningSettings();

      final frontBase64 = await _encodeFile(frontFile);
      final backBase64 = backFile != null ? await _encodeFile(backFile) : null;

      final result = await _blinkid.performDirectApiScan(
        sdkSettings,
        sessionSettings,
        frontBase64,
        backBase64,
      );
      if (result == null) return null;

      final mapped = _mapResult(result);
      if (mapped.values.every((value) => value.trim().isEmpty)) return null;
      return mapped;
    } catch (e) {
      debugPrint('BlinkID scan error: $e');
      return null;
    }
  }

  static Future<Map<String, String>?> scanWithUi() async {
    final licenseKey = _licenseKey;
    if (licenseKey == null || licenseKey.isEmpty) return null;

    try {
      final sdkSettings = BlinkIdSdkSettings(licenseKey);
      sdkSettings.downloadResources = true;
      final licensee = _licensee;
      if (licensee != null) {
        sdkSettings.licensee = licensee;
      }

      final sessionSettings = BlinkIdSessionSettings();
      sessionSettings.scanningMode = ScanningMode.automatic;
      sessionSettings.scanningSettings = _buildScanningSettings();

      final uiSettings = BlinkIdScanningUxSettings();
      uiSettings.showHelpButton = true;
      uiSettings.showOnboardingDialog = true;
      uiSettings.allowHapticFeedback = true;
      uiSettings.preferredCamera = PreferredCamera.back;

      final classFilter = ClassFilter.withIncludedDocumentClasses([
        DocumentFilter(Country.bolivia, null, DocumentType.id),
      ]);

      final result = await _blinkid.performScan(
        sdkSettings,
        sessionSettings,
        uiSettings,
        classFilter,
      );
      if (result == null) return null;

      final mapped = _mapResult(result);
      if (mapped.values.every((value) => value.trim().isEmpty)) return null;
      return mapped;
    } catch (e) {
      debugPrint('BlinkID UI scan error: $e');
      return null;
    }
  }

  static Future<String> _encodeFile(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  static Map<String, String> _mapResult(BlinkIdScanningResult result) {
    final vizResults = _vizResults(result);
    final barcodeResults = _barcodeResults(result);

    final fullName = _pickFirstNonEmpty([
      _stringValue(result.fullName),
      _pickFromViz(vizResults, (viz) => viz.fullName),
      _pickFromBarcode(barcodeResults, (barcode) => barcode.fullName),
      _pickFromViz(vizResults, (viz) => viz.localizedName),
      _stringValue(result.localizedName),
    ]);
    String nombres = _pickFirstNonEmpty([
      _stringValue(result.firstName),
      _pickFromViz(vizResults, (viz) => viz.firstName),
      _pickFromBarcode(barcodeResults, (barcode) => barcode.firstName),
      _pickFromViz(vizResults, (viz) => viz.additionalNameInformation),
      _stringValue(result.additionalNameInformation),
    ]);
    String apellidos = _pickFirstNonEmpty([
      _stringValue(result.lastName),
      _pickFromViz(vizResults, (viz) => viz.lastName),
      _pickFromBarcode(barcodeResults, (barcode) => barcode.lastName),
    ]);
    final fatherName = _pickFirstNonEmpty([
      _stringValue(result.fathersName),
      _pickFromViz(vizResults, (viz) => viz.fathersName),
    ]);
    final motherName = _pickFirstNonEmpty([
      _stringValue(result.mothersName),
      _pickFromViz(vizResults, (viz) => viz.mothersName),
    ]);

    if ((nombres.isEmpty || apellidos.isEmpty) && fullName.isNotEmpty) {
      if (apellidos.isEmpty && (fatherName.isNotEmpty || motherName.isNotEmpty)) {
        apellidos = _pickFirstNonEmpty([
          _joinParts([fatherName, motherName]),
          apellidos,
        ]);
      }
      if (nombres.isEmpty && apellidos.isNotEmpty) {
        final remaining = _removePrefixTokens(fullName, apellidos);
        if (remaining.isNotEmpty) {
          nombres = remaining;
        }
      }
      final split = ServicioOcrInteligenteIdentidad.splitFullName(fullName);
      nombres = _pickFirstNonEmpty([nombres, split['nombres'] ?? '']);
      apellidos = _pickFirstNonEmpty([apellidos, split['apellidos'] ?? '']);
    }

    return {
      'ci': _pickFirstNonEmpty([
        _stringValue(result.documentNumber),
        _stringValue(result.personalIdNumber),
        _stringValue(result.documentAdditionalNumber),
        _stringValue(result.additionalPersonalIdNumber),
        _pickFromViz(vizResults, (viz) => viz.documentNumber),
        _pickFromViz(vizResults, (viz) => viz.personalIdNumber),
        _pickFromViz(vizResults, (viz) => viz.documentAdditionalNumber),
        _pickFromBarcode(barcodeResults, (barcode) => barcode.documentNumber),
        _pickFromBarcode(barcodeResults, (barcode) => barcode.personalIdNumber),
        _pickFromBarcode(
          barcodeResults,
          (barcode) => barcode.documentAdditionalNumber,
        ),
      ]),
      'nombres': nombres,
      'apellidos': apellidos,
      'fechaNacimiento': _pickDate([
        result.dateOfBirth,
        ...vizResults.map((viz) => viz.dateOfBirth),
        ...barcodeResults.map((barcode) => barcode.dateOfBirth),
      ]),
      'fechaEmision': _pickDate([
        result.dateOfIssue,
        ...vizResults.map((viz) => viz.dateOfIssue),
        ...barcodeResults.map((barcode) => barcode.dateOfIssue),
      ]),
      'fechaExpiracion': _pickDate([
        result.dateOfExpiry,
        ...vizResults.map((viz) => viz.dateOfExpiry),
        ...barcodeResults.map((barcode) => barcode.dateOfExpiry),
      ]),
      'lugarNacimiento': _pickFirstNonEmpty([
        _stringValue(result.placeOfBirth),
        _pickFromViz(vizResults, (viz) => viz.placeOfBirth),
        _pickFromBarcode(barcodeResults, (barcode) => barcode.placeOfBirth),
        _pickFromViz(vizResults, (viz) => viz.municipalityOfRegistration),
      ]),
      'profesion': _pickFirstNonEmpty([
        _stringValue(result.profession),
        _pickFromViz(vizResults, (viz) => viz.profession),
        _pickFromBarcode(barcodeResults, (barcode) => barcode.profession),
      ]),
      'estadoCivil': _pickFirstNonEmpty([
        _stringValue(result.maritalStatus),
        _pickFromViz(vizResults, (viz) => viz.maritalStatus),
        _pickFromBarcode(barcodeResults, (barcode) => barcode.maritalStatus),
      ]),
      'domicilio': _pickFirstNonEmpty([
        _stringValue(result.address),
        _pickFromViz(vizResults, (viz) => viz.address),
        _pickFromBarcode(barcodeResults, (barcode) => barcode.address),
      ]),
      'grupoSanguineo': _pickFirstNonEmpty([
        _stringValue(result.bloodType),
        _pickFromViz(vizResults, (viz) => viz.bloodType),
      ]),
    };
  }

  static Iterable<VizResult> _vizResults(BlinkIdScanningResult result) {
    final subResults = result.subResults;
    if (subResults == null || subResults.isEmpty) {
      return Iterable<VizResult>.empty();
    }
    return subResults.map((res) => res.viz).whereType<VizResult>();
  }

  static Iterable<BarcodeResult> _barcodeResults(BlinkIdScanningResult result) {
    final subResults = result.subResults;
    if (subResults == null || subResults.isEmpty) {
      return Iterable<BarcodeResult>.empty();
    }
    return subResults.map((res) => res.barcode).whereType<BarcodeResult>();
  }

  static String _pickFromViz(
    Iterable<VizResult> vizResults,
    StringResult? Function(VizResult) getter,
  ) {
    final values = vizResults.map((viz) => _stringValue(getter(viz))).toList();
    return _pickFirstNonEmpty(values);
  }

  static String _pickFromBarcode(
    Iterable<BarcodeResult> barcodeResults,
    String? Function(BarcodeResult) getter,
  ) {
    final values = barcodeResults
        .map((barcode) => _stringValueFromDynamic(getter(barcode)))
        .toList();
    return _pickFirstNonEmpty(values);
  }

  static String _pickDate(List<dynamic> candidates) {
    for (final candidate in candidates) {
      final formatted = _formatDate(candidate);
      if (formatted.isNotEmpty) return formatted;
    }
    return '';
  }

  static String _formatDate(dynamic dateResult) {
    if (dateResult == null) return '';
    if (dateResult is DateResult) {
      final date = dateResult.date;
      if (date?.day != null && date?.month != null && date?.year != null) {
        final day = date!.day!.toString().padLeft(2, '0');
        final month = date.month!.toString().padLeft(2, '0');
        final year = date.year!.toString();
        return '$day/$month/$year';
      }

      final original = dateResult.originalString;
      if (original is StringResult) {
        final normalized = _normalizeDateString(_stringValue(original));
        return normalized.isNotEmpty ? normalized : _stringValue(original);
      }
      if (original is String) {
        final normalized = _normalizeDateString(original);
        return normalized.isNotEmpty ? normalized : original.trim();
      }
    }
    if (dateResult is String) {
      final normalized = _normalizeDateString(dateResult);
      return normalized.isNotEmpty ? normalized : dateResult.trim();
    }
    return '';
  }

  static String _stringValueFromDynamic(dynamic value) {
    if (value is StringResult) return _stringValue(value);
    if (value is String) return value.trim();
    return '';
  }

  static String _stringValue(StringResult? value) {
    final raw =
        value?.value ??
        value?.latin ??
        value?.cyrillic ??
        value?.greek ??
        value?.arabic ??
        '';
    if (raw.isEmpty) return '';
    return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _pickFirstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static BlinkIdScanningSettings _buildScanningSettings() {
    final settings = BlinkIdScanningSettings();
    settings.skipImagesWithBlur = false;
    settings.skipImagesWithGlare = false;
    settings.skipImagesWithInadequateLightingConditions = false;
    settings.skipImagesOccludedByHand = false;
    settings.allowUncertainFrontSideScan = true;
    settings.scanUnsupportedBack = true;
    settings.enableBarcodeScanOnly = true;
    settings.recognitionModeFilter.enableBarcodeId = true;
    settings.recognitionModeFilter.enableFullDocumentRecognition = true;
    settings.recognitionModeFilter.enablePhotoId = true;
    return settings;
  }

  static String _joinParts(List<String> parts) {
    return parts.where((part) => part.trim().isNotEmpty).join(' ').trim();
  }

  static String _removePrefixTokens(String fullName, String prefix) {
    final fullTokens = _tokenize(fullName);
    final prefixTokens = _tokenize(prefix);
    if (fullTokens.isEmpty || prefixTokens.isEmpty) return '';
    if (fullTokens.length <= prefixTokens.length) return '';

    if (_startsWithTokens(fullTokens, prefixTokens)) {
      return fullTokens.sublist(prefixTokens.length).join(' ').trim();
    }
    if (_endsWithTokens(fullTokens, prefixTokens)) {
      return fullTokens.sublist(0, fullTokens.length - prefixTokens.length).join(' ').trim();
    }
    return '';
  }

  static bool _startsWithTokens(List<String> source, List<String> prefix) {
    if (source.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (source[i].toLowerCase() != prefix[i].toLowerCase()) return false;
    }
    return true;
  }

  static bool _endsWithTokens(List<String> source, List<String> suffix) {
    if (source.length < suffix.length) return false;
    final offset = source.length - suffix.length;
    for (var i = 0; i < suffix.length; i++) {
      if (source[offset + i].toLowerCase() != suffix[i].toLowerCase()) {
        return false;
      }
    }
    return true;
  }

  static List<String> _tokenize(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[^\p{L}\s-]', unicode: true), ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return [];
    return cleaned.split(' ');
  }

  static String _normalizeDateString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    final isoMatch =
        RegExp(r'(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})').firstMatch(trimmed);
    if (isoMatch != null) {
      final year = isoMatch.group(1)!;
      final month = isoMatch.group(2)!.padLeft(2, '0');
      final day = isoMatch.group(3)!.padLeft(2, '0');
      return '$day/$month/$year';
    }

    final dmyMatch =
        RegExp(r'(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})').firstMatch(trimmed);
    if (dmyMatch != null) {
      var year = dmyMatch.group(3)!;
      if (year.length == 2) {
        final y = int.tryParse(year) ?? 0;
        year = y > 30 ? '19$year' : '20$year';
      }
      final day = dmyMatch.group(1)!.padLeft(2, '0');
      final month = dmyMatch.group(2)!.padLeft(2, '0');
      return '$day/$month/$year';
    }

    final digits = RegExp(r'\b(\d{8})\b').firstMatch(trimmed);
    if (digits != null) {
      final value = digits.group(1)!;
      final first = int.tryParse(value.substring(0, 4)) ?? 0;
      if (first > 1900) {
        final year = value.substring(0, 4);
        final month = value.substring(4, 6);
        final day = value.substring(6, 8);
        return '${day.padLeft(2, '0')}/${month.padLeft(2, '0')}/$year';
      }
      final day = value.substring(0, 2);
      final month = value.substring(2, 4);
      final year = value.substring(4, 8);
      return '${day.padLeft(2, '0')}/${month.padLeft(2, '0')}/$year';
    }

    final upper = _replaceAccents(trimmed.toUpperCase());
    final monthPatterns = [
      RegExp(r'(\d{1,2})\s*DE\s*([A-Z]+)\s*DE\s*(\d{2,4})'),
      RegExp(r'(\d{1,2})\s*([A-Z]+)\s*(\d{2,4})'),
    ];
    for (final pattern in monthPatterns) {
      final match = pattern.firstMatch(upper);
      if (match == null) continue;
      final day = match.group(1)!.padLeft(2, '0');
      final monthName = match.group(2) ?? '';
      final monthNum = _spanishMonthToNumber(monthName);
      if (monthNum == null) continue;
      var year = match.group(3) ?? '';
      if (year.length == 2) {
        final y = int.tryParse(year) ?? 0;
        year = y > 30 ? '19$year' : '20$year';
      }
      final month = monthNum.toString().padLeft(2, '0');
      return '$day/$month/$year';
    }

    return '';
  }

  static int? _spanishMonthToNumber(String month) {
    final normalized = _replaceAccents(month.toUpperCase());
    const months = {
      'ENERO': 1,
      'FEBRERO': 2,
      'MARZO': 3,
      'ABRIL': 4,
      'MAYO': 5,
      'JUNIO': 6,
      'JULIO': 7,
      'AGOSTO': 8,
      'SEPTIEMBRE': 9,
      'SETIEMBRE': 9,
      'OCTUBRE': 10,
      'NOVIEMBRE': 11,
      'DICIEMBRE': 12,
    };
    return months[normalized];
  }

  static String _replaceAccents(String input) {
    return input
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ü', 'U')
        .replaceAll('Ñ', 'N');
  }
}
