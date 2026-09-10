import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const _configKey = 'universe_easy_maths_config';

  /// Load the user's saved configuration first, then fall back to the bundled
  /// [assets/env.json] configuration used by release builds and GitHub Pages.
  /// Shared preferences works across Android, iOS, desktop, and web, so the
  /// first-run setup can persist its values on every supported target.
  static Future<Config> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_configKey);
      if (saved != null) {
        final storedConfig = _parse(saved);
        if (storedConfig != null) return storedConfig;
        await preferences.remove(_configKey);
      }
    } catch (_) {
      // Fall back to the bundled asset when local storage is unavailable.
    }

    try {
      final raw = await rootBundle.loadString('assets/env.json');
      return _parse(raw) ?? Config.empty();
    } catch (_) {
      return Config.empty();
    }
  }

  /// Persist the endpoint entered on the first-run setup screen.
  static Future<void> save(Config config) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _configKey,
      jsonEncode({
        'version': 1,
        'endpoints': [
          {
            'name': 'main',
            'url': config.url,
            'publishableKey': config.publishableKey,
          },
        ],
      }),
    );
  }

  static Config? _parse(String raw) {
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final endpoints = decoded['endpoints'] as List<dynamic>? ?? const [];
      for (final endpoint in endpoints) {
        if (endpoint is! Map<String, dynamic>) continue;
        if ((endpoint['name'] as String?)?.trim() != 'main') continue;
        return Config(
          url: (endpoint['url'] as String?)?.trim() ?? '',
          publishableKey: (endpoint['publishableKey'] as String?)?.trim() ?? '',
        );
      }
    } catch (_) {
      // Treat malformed local or bundled configuration as empty.
    }
    return null;
  }

  /// Compile-time fallback values used by the first-run config screen.
  /// They are intentionally placeholder-style so a rebuilt APK never silently
  /// ships real secrets.
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
