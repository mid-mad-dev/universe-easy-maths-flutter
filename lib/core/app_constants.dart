import 'dart:convert';
import 'package:flutter/services.dart';

class AppConstants {
  static const appName = 'UNIVERSE EASY MATHS';
  static const companyName = 'UNIVERSE EASY MATHS EDTEC PRIVATE LIMITED';
  static const location = 'Piravom, Ernakulam, Kerala';
  static const founder = 'Midhun Suku';
  static const coFounder = 'Sinthilkumar';
  static const tagline = 'Maths, but in 60-second bites.';
  static const supportText =
      'Swipe through short lessons, watch your chapter progress bar fill up, and drop your doubts any time.';

  static const profileBucket = 'profile-photos';
  static const doubtBucket = 'doubt-images';
  static const lessonBucket = 'lesson-videos';

  /// Load configuration from the bundled [assets/env.json] file.
  ///
  /// This is the primary way a sideloaded APK gets its Supabase project values:
  /// a device owner edits [assets/env.json] (or an admin rebuilds the APK with
  /// real values) instead of recompiling Dart source. Return [Config] with
  /// placeholder values when the asset is missing or malformed so the app can
  /// show a first-run config screen instead of crashing or failing at startup.
  static Future<Config> load() async {
    final raw = await rootBundle.loadString('assets/env.json').catchError((_) => '');
    if (raw.isEmpty) {
      return Config.empty();
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final endpoints = decoded['endpoints'] as List<dynamic>? ?? const [];
      for (final endpoint in endpoints) {
        if (endpoint is! Map<String, dynamic>) continue;
        final name = (endpoint['name'] as String?)?.trim();
        if (name != 'main') continue;
        final url =
            (endpoint['url'] as String?)?.trim() ?? '';
        final key =
            (endpoint['publishableKey'] as String?)?.trim() ?? '';
        return Config(url: url, publishableKey: key);
      }
      return Config.empty();
    } catch (_) {
      return Config.empty();
    }
  }

  /// Compile-time fallback values used by previous call sites and by the
  /// first-run config screen as editable defaults. They are intentionally
  /// placeholder-style so a rebuilt APK never silently ships real secrets.
  static const supabaseUrl = 'YOUR_SUPABASE_URL';
  static const supabasePublishableKey = 'YOUR_SUPABASE_PUBLISHABLE_KEY';
  static const razorpayKeyId = 'YOUR_RAZORPAY_KEY_ID';
}

/// Runtime configuration for one Supabase endpoint.
class Config {
  final String url;
  final String publishableKey;

  const Config({required this.url, required this.publishableKey});

  /// A placeholder config that signals "not yet configured".
  const Config.empty()
      : url = AppConstants.supabaseUrl,
        publishableKey = AppConstants.supabasePublishableKey;

  bool get isConfigured =>
      url.isNotEmpty &&
      !url.startsWith('YOUR_') &&
      publishableKey.isNotEmpty &&
      !publishableKey.startsWith('YOUR_');

  bool get supabaseUrlLooksValid =>
      url.isNotEmpty && url.startsWith('https://') && !url.startsWith('YOUR_');

  bool get supabaseKeyLooksValid =>
      publishableKey.isNotEmpty && !publishableKey.startsWith('YOUR_');

  /// Reason shown on the first-run config screen when the app can't start.
  String missingReason() {
    if (!supabaseUrlLooksValid) {
      return 'Supabase URL is missing or looks invalid.';
    }
    if (!supabaseKeyLooksValid) {
      return 'Supabase publishable key is missing.';
    }
    return '';
  }
}
